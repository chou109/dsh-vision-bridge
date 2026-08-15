#!/usr/bin/env bash
# install.sh — deploy the "paste image & auto-vision" feature into a local
# DeepSeek Harness (dsh) web profile (macOS / Linux).
#
# Usage:
#   ./install.sh            # install (idempotent)
#   ./install.sh --uninstall
#
# Applies patch/dsh-host-apiproxy.patch and patch/dsh-llm-pi-ai.patch with
# `git apply` (LF-safe), then you restart the harness yourself.

set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
PROFILE="$DSH_HOME/profiles"

log() { printf '[dsh-vision-bridge] %s\n' "$*"; }

declare -A PATCHES=(
  [dsh-host-apiproxy]="$PROFILE/node_modules/@deepseek-ai/dsh-host-apiproxy/lib/index.js"
  [dsh-llm-pi-ai]="$PROFILE/node_modules/@deepseek-ai/dsh-llm-pi-ai/lib/index.js"
)

applied() { # applied <name>
  local f="${PATCHES[$1]}"
  case "$1" in
    dsh-host-apiproxy) grep -q 'MODEL_DOES_NOT_SUPPORT_IMAGES' "$f";; # patched => string ABSENT
    dsh-llm-pi-ai) grep -q 'projectImageBlocksToText' "$f";;          # patched => string PRESENT
  esac
}

apply_one() { # apply_one <name> <reverse?>
  local name="$1" rev="${2:-}"
  local f="${PATCHES[$name]}"
  if [[ -n "$rev" ]]; then
    ( cd "$(dirname "$f")" && git -c core.autocrlf=false apply --unsafe-paths --directory="$(dirname "$f")" -R "$REPO/patch/$name.patch" )
    log "reverted $name"
  else
    ( cd "$(dirname "$f")" && git -c core.autocrlf=false apply --unsafe-paths --directory="$(dirname "$f")" "$REPO/patch/$name.patch" )
    log "patched $name"
  fi
}

if [[ "${1:-}" == "--uninstall" ]]; then
  for name in "${!PATCHES[@]}"; do
    [[ -f "${PATCHES[$name]}" ]] || { log "skip $name: file missing"; continue; }
    if applied "$name"; then apply_one "$name" -R; else log "$name not patched, nothing to undo"; fi
  done
  log "uninstall done; restart the harness to apply"
  exit 0
fi

for name in "${!PATCHES[@]}"; do
  [[ -f "${PATCHES[$name]}" ]] || { log "ERROR: $name target not found: ${PATCHES[$name]}"; exit 1; }
  if applied "$name"; then
    log "$name already patched, skipping"
  else
    command -v git >/dev/null || { log "ERROR: git is required to apply $name.patch"; exit 1; }
    apply_one "$name"
    # Re-verify by content: some git versions silently skip patches when the
    # working path contains non-ASCII characters (exit 0 but no change).
    if ! applied "$name"; then
      log "ERROR: $name: git apply exited 0 but the file did not change (non-ASCII path quirk). Apply patch/$name.patch manually (git apply -p1) or move dsh to an ASCII path."
      exit 1
    fi
  fi
done

log "installed. Restart the harness (run 'dsh web --host 127.0.0.1 --port 3080' again) and hard-refresh the browser."
