# install.ps1 — deploy the "paste image & auto-vision" feature into a local
# DeepSeek Harness (dsh) web profile.
#
# What it does:
#   1. Patches @deepseek-ai/dsh-host-apiproxy — removes the
#      MODEL_DOES_NOT_SUPPORT_IMAGES rejection so image parts are admitted
#      regardless of the selected model.
#   2. Patches @deepseek-ai/dsh-llm-pi-ai — text-only models receive image
#      blocks as a text placeholder carrying the attachment's absolute path
#      plus an instruction to call the vision_chat tool.
#   3. Restarts the dsh web harness (unless -NoRestart).
#
# Usage:
#   .\install.ps1            # install (idempotent) and restart the harness
#   .\install.ps1 -NoRestart # install only
#   .\install.ps1 -Uninstall # reverse both patches (git apply -R) and restart
#
# Prerequisite (recognition side): the qwen-mm-plugins-api MCP server with the
# vision_chat tool must be registered in the profile (see README "For AI").

param(
    [switch]$NoRestart,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$profiles = Join-Path $dshHome 'profiles'

$targets = @(
    @{
        Name     = 'dsh-host-apiproxy'
        File     = Join-Path $profiles 'node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js'
        Patch    = Join-Path $repoRoot 'patch\dsh-host-apiproxy.patch'
        Applied  = { param($c) -not $c.Contains('MODEL_DOES_NOT_SUPPORT_IMAGES') }   # patch REMOVES this string
    },
    @{
        Name     = 'dsh-llm-pi-ai'
        File     = Join-Path $profiles 'node_modules\@deepseek-ai\dsh-llm-pi-ai\lib\index.js'
        Patch    = Join-Path $repoRoot 'patch\dsh-llm-pi-ai.patch'
        Applied  = { param($c) $c.Contains('projectImageBlocksToText') }              # patch ADDS this function
    }
)

function Write-Step([string]$msg) { Write-Host "[dsh-vision-bridge] $msg" -ForegroundColor Cyan }

if ($Uninstall) {
    foreach ($t in $targets) {
        if (-not (Test-Path $t.File)) { Write-Step "skip $($t.Name): file missing"; continue }
        $c = [System.IO.File]::ReadAllText($t.File)
        if (& $t.Applied $c) {
            $git = Get-Command git -ErrorAction SilentlyContinue
            if (-not $git) { Write-Error "uninstall needs git (to reverse the patch) or a reinstall of $($t.Name)@0.1.0-rc.6"; exit 1 }
            Push-Location (Split-Path $t.File)
            git -c core.autocrlf=false apply --unsafe-paths --directory=(Split-Path $t.File) -R $t.Patch
            Pop-Location
            Write-Step "reverted $($t.Name)"
        } else {
            Write-Step "$($t.Name) not patched, nothing to undo"
        }
    }
    Write-Step "uninstall done. Restart the harness (start-dsh.bat) to apply."
    exit 0
}

foreach ($t in $targets) {
    if (-not (Test-Path $t.File)) { Write-Error "$($t.Name) target not found: $($t.File)"; exit 1 }
    $c = [System.IO.File]::ReadAllText($t.File)
    if (& $t.Applied $c) {
        Write-Step "$($t.Name) already patched, skipping"
        continue
    }
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { Write-Error "git is required to apply $($t.Name).patch — install git and retry."; exit 1 }
    Push-Location (Split-Path $t.File)
    git -c core.autocrlf=false apply --unsafe-paths --directory=(Split-Path $t.File) $t.Patch
    if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error "git apply failed for $($t.Name) — the installed version may differ from 0.1.0-rc.6. See README (For AI: Debugging)."; exit 1 }
    Pop-Location
    Write-Step "$($t.Name) patched"
}

if ($NoRestart) {
    Write-Step "installed. Restart the harness (close the 'DeepSeek Harness Server' window and run start-dsh.bat), then hard-refresh the browser (Ctrl+F5)."
} else {
    Write-Step "restarting the dsh web harness..."
    $node = Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match 'dsh web' }
    foreach ($p in $node) { taskkill /F /T /PID $p.ProcessId 2>$null | Out-Null }
    Start-Sleep -Seconds 2
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', 'npx -y @deepseek-ai/dsh web --host 127.0.0.1 --port 3080' -WindowStyle Minimized
    Write-Step "harness restarting (http://127.0.0.1:3080). Hard-refresh the browser (Ctrl+F5) once it is back."
}
Write-Step "done."
