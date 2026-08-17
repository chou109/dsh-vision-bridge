# dsh-vision-bridge

Paste an image into the DeepSeek Harness chat box and let the agent **see and describe it automatically** — no more "current model does not support images" errors, no manually handing over file paths.

> **国内镜像 / Mirror**: also hosted on [gitee.com/chill109/dsh-vision-bridge](https://gitee.com/chill109/dsh-vision-bridge) — Gitee is a mainland-China Git host (faster access from mainland China; use it if GitHub is slow).

| | |
|---|---|
| **Platform** | Windows / macOS / Linux (dsh web) |
| **Requires** | DeepSeek Harness `dsh web` 0.1.0-rc.6 + the **qwen-mm-plugins-api** MCP server (`vision_chat` tool) |
| **License** | MIT (add a `LICENSE` file before publishing) |

> 中文版见 [README.zh.md](README.zh.md)。

---

# Part 1 — If you are a human

*This part is written for people who just want the feature installed.*

## What it does

Before this project, pasting an image into the chat box with a text-only model (e.g. `deepseek-v4-flash`) showed:

> 当前模型不支持图片，请切换支持图片的模型 / The current model does not support images; switch to a model that does

After installing this project:

1. **Paste any image** into the send box (it shows as a thumbnail, as usual).
2. **Send it** — the message goes through even though the chat model cannot take images.
3. The harness automatically hands the agent the image as a **local file path**, and the agent **automatically calls whatever vision tool it has available** (e.g. `vision_chat` from qwen-mm-plugins-api) to recognize it — it answers with a description, OCR, VQA… whatever you asked.

You never type a path; the recognition happens on its own.

> **Please understand this clearly**: this project is **only a bridge** — it makes the image *sendable* and hands it to the agent as a path. It does **not** include or install any vision model:
> - The vision plugin must be **configured by you** (e.g. register qwen-mm-plugins-api in `profiles\web\cordis.patch.yml` with a working API key);
> - The vision model is **freely selectable** — any tool that takes an image and returns text works;
> - If you did not specify which vision model to use, let the AI **recommend a compatible one** (e.g. `mcp-qwen-mm-plugins-api` / `vision_chat`); the placeholder tells the agent to use whichever vision tool it currently has.

## What this project is NOT: it has no vision capability of its own

**dsh-vision-bridge ships no vision model, no vision tool, and no image-understanding code.** It only does two things:

1. Allows text-only main models (e.g. `deepseek-v4-flash`) to **send images** in a session (removes the harness rejection checks);
2. At request time, **projects image blocks into "attachment path + vision instruction" text** so the main model **calls whatever vision tool you have registered** to read the image.

The division of labor: the main model (DeepSeek, etc.) *thinks*, the vision tool *sees* — and **the "seeing" side is not in this repository**. Without a vision tool, this bridge itself cannot see anything.

## Recommended pairings (the vision side is yours to set up)

**Vision tools (MCP plugins)** — [qwen-mm-plugins](https://github.com/QwenLM/qwen-mm-plugins) is the recommended pairing:

- `api` capability: cloud vision tools `vision_chat` (describe/VQA), `ocr` (text extraction), `grounding` (bounding boxes), and more; register `mcp-qwen-mm-plugins-api` in `profiles\web\cordis.patch.yml` and the bridge's placeholder instruction will call it automatically;
- `core` capability: local reading/visualization (images, video, documents, code, etc.) — no network needed.

**Free vision APIs (pick any; any OpenAI-compatible endpoint works)**:

| API | Model | Cost | Endpoint |
|---|---|---|---|
| Zhipu GLM-4V-Flash (recommended) | `glm-4v-flash` | **Completely free**, register and use | `https://open.bigmodel.cn/api/paas/v4` |
| SiliconFlow | `Qwen/Qwen2.5-VL-7B-Instruct` | Free models (~2 RPM limit) | `https://api.siliconflow.cn/v1` |
| Alibaba Cloud Bailian DashScope | `qwen-vl-plus` etc. | Free quota for new users | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| OpenRouter / GitHub Models | `qwen-2.5-vl-72b:free` etc. | Free tier | Requires a proxy/VPN |

Example with Zhipu — in the qwen-mm-plugins config file `~/.qwen-mm-plugins/config`:

```
DASHSCOPE_API_KEY = <Zhipu API key (get it for free at open.bigmodel.cn)>
DASHSCOPE_BASE_URL = https://open.bigmodel.cn/api/paas/v4
QWEN_MM_VISION_MODEL = glm-4v-flash
```

> Tip: `glm-4v-flash` caps output at 1024 tokens (qwen-mm-plugins adapts automatically); the free tier is rate-limited to roughly 3-10 RPM — plenty for chat use.

## Requirements

- DeepSeek Harness web UI (`dsh web --host 127.0.0.1 --port 3080`)
- The **qwen-mm-plugins-api** MCP server registered in your web profile (provides the `vision_chat` tool; needs a working OpenAI-compatible API key — Zhipu / SiliconFlow / DashScope all work)
- `git` (used by the installer to apply the patches)

## Manual deployment (Windows)

1. **Apply the host patch** — removes the "model does not support images" rejection:

   ```powershell
   cd "$env:USERPROFILE\.dsh\profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib"
   git -c core.autocrlf=false apply --unsafe-paths --directory="$PWD" "..\..\..\..\..\..\dsh-vision-bridge\patch\dsh-host-apiproxy.patch"
   ```

2. **Apply the LLM patch** — text-only models receive images as a path + a vision instruction:

   ```powershell
   cd "$env:USERPROFILE\.dsh\profiles\node_modules\@deepseek-ai\dsh-llm-pi-ai\lib"
   git -c core.autocrlf=false apply --unsafe-paths --directory="$PWD" "..\..\..\..\..\..\dsh-vision-bridge\patch\dsh-llm-pi-ai.patch"
   ```

3. **Restart the harness** — close the *DeepSeek Harness Server* window, run `start-dsh.bat` (or restart `dsh web`), then **hard-refresh the browser (Ctrl+F5)**.

### One-command alternative

```powershell
.\install.ps1          # applies all four patches and restarts the harness
```

## Let an AI deploy it

Copy/paste this whole paragraph into your AI assistant:

> Deploy the dsh-vision-bridge feature from `https://github.com/chou109/dsh-vision-bridge` (mainland-China mirror: `https://gitee.com/chill109/dsh-vision-bridge`) to my local DeepSeek Harness web profile.
> 1) Windows: run `.\install.ps1` from the repo root — it applies `patch\dsh-host-apiproxy.patch`, `patch\dsh-host-apiproxy-selectmodel.patch`, `patch\dsh-llm-pi-ai.patch` and `patch\dsh-llm-deepseek.patch` into `%USERPROFILE%\.dsh\profiles\node_modules\@deepseek-ai\...` with `git -c core.autocrlf=false apply`, then restarts the harness. macOS/Linux: `./install.sh` (restart `dsh web` yourself).
> 2) If the scripts are unavailable, apply the four patches manually exactly as the README "For AI" section describes.
> 3) Note: this project is **only a bridge between "image sending" and a vision-model plugin** — it does not include a vision model. The vision plugin must be configured separately and the vision model can be freely chosen. If I did not specify which vision model to use, please **recommend a compatible one** (e.g. `mcp-qwen-mm-plugins-api` / `vision_chat`), and confirm it is registered in `profiles\web\cordis.patch.yml` with a working API key.
> 4) After the harness is back, verify: I paste an image into the chat box and send it — the agent must automatically describe the image (it receives `[图片附件：<path>（如需了解内容，请调用你可用的视觉识图工具…）]` and automatically calls its available vision tool).

## Usage

1. Paste (Ctrl+V) or drag an image into the chat box.
2. (Optional) type a question, e.g. "这是什么".
3. Send. The agent automatically recognizes the image with `vision_chat` and answers.
4. Pasted images also work with **no text at all** — the message auto-sends.

## Uninstall

```powershell
.\install.ps1 -Uninstall
```

or manually: `git apply -R` all four patches (or reinstall `@deepseek-ai/dsh-host-apiproxy@0.1.0-rc.6`, `@deepseek-ai/dsh-llm-pi-ai@0.1.0-rc.6` and `@deepseek-ai/dsh-llm-deepseek`), then restart the harness.

---

# Part 2 — If you are an AI

*This part is written for AI agents that install, debug, or extend this feature. It assumes you can run shell commands and read the dsh packages in `node_modules`.*

## What this is (facts)

Paste-to-vision is **four patches across three shipped dsh packages** (no client-side change needed — the chat composer already allows pasting; the block was a server-side rejection at send time):

1. **`patch/dsh-host-apiproxy.patch`** — in `@deepseek-ai/dsh-host-apiproxy/lib/index.js`, the `prompt` RPC handler previously rejected any message containing image parts when the selected model's `inputModalities` lacked `image` (returning `attachment-error` / `MODEL_DOES_NOT_SUPPORT_IMAGES`, which the UI renders as "当前模型不支持图片…"). The patch deletes that rejection: image parts are admitted for **any** model. (1 hunk; the file gets smaller.)

2. **`patch/dsh-llm-pi-ai.patch`** — in `@deepseek-ai/dsh-llm-pi-ai/lib/index.js`, the `stream()` entry previously threw `UNSUPPORTED_CONTENT` when a text-only model received image blocks. The patch instead **projects each image block to a text placeholder**:

   ```
   [图片附件：<abs path>（如需了解内容，请调用你可用的视觉识图工具识别此图片；例如 vision_chat，images 参数传此路径）]
   ```

   The path is resolved by `imageAttachmentPath()` from the content-addressed ref: `<DSH_HOME>/attachments/v1/objects/<aa>/<sha256>.<ext>` (a best-effort hardlink adds the extension so tools can sniff it). The projection recurses into `tool-result` content too, so images returned by tools (e.g. `read_image`) are handled the same way. (3 hunks.)

3. **`patch/dsh-host-apiproxy-selectmodel.patch`** — the same package's `selectModel` RPC previously rejected switching to a text-only model when the session already contained images (`model-unavailable`: "does not accept image input, but this session already contains images"). The patch removes that rejection: image sessions may switch to any model — the images are bridged at request time by the projection patches below. (1 hunk.)

4. **`patch/dsh-llm-deepseek.patch`** — newer harness versions route the DeepSeek official provider (`deepseek-official`, e.g. `deepseek-v4-flash`) through the **dedicated adapter** `@deepseek-ai/dsh-llm-deepseek`, which unconditionally threw `UNSUPPORTED_CONTENT` ("The DeepSeek chat-completions adapter does not support image content.") for image blocks. The patch applies the same projection as pi-ai at the `request()` entry, recursing into `tool-result` content. (3 hunks.)

5. **The recognition side is NOT part of this repo** — the placeholder is a **generic instruction** ("use whatever vision tool you have available"), so the agent automatically picks the vision tool currently registered in the profile. A typical pairing is the `vision_chat` tool of the **qwen-mm-plugins-api** MCP server (registered in `profiles/web/cordis.patch.yml` → `mcp-qwen-mm-plugins-api` with a working API key), but **any tool that accepts an image path and returns text works**.

**Data flow:** paste → draft thumbnail → send → `prompt` RPC admitted (patch 1) → message persisted with image parts (UI history still shows the image) → LLM request serialization hits a text-only model → projection (patch 2 / patch 4, whichever adapter the route uses) → agent context receives the path placeholder → agent calls `vision_chat(path)` → answer. Switching models is allowed on image sessions too — `selectModel` no longer rejects them (patch 3).

## Deployment (exact steps)

```powershell
$profiles = "$env:USERPROFILE\.dsh\profiles"          # or $env:DSH_HOME\profiles

# 1. host-apiproxy (removes the rejection)
$d = "$profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib"
git -c core.autocrlf=false apply --unsafe-paths --directory="$d" patch\dsh-host-apiproxy.patch

# 2. llm-pi-ai (image -> path text projection)
$d = "$profiles\node_modules\@deepseek-ai\dsh-llm-pi-ai\lib"
git -c core.autocrlf=false apply --unsafe-paths --directory="$d" patch\dsh-llm-pi-ai.patch

# 3. host-apiproxy (model-switch rejection removal)
$d = "$profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib"
git -c core.autocrlf=false apply --unsafe-paths --directory="$d" patch\dsh-host-apiproxy-selectmodel.patch

# 4. llm-deepseek (DeepSeek adapter: image -> path text projection)
$d = "$profiles\node_modules\@deepseek-ai\dsh-llm-deepseek\lib"
git -c core.autocrlf=false apply --unsafe-paths --directory="$d" patch\dsh-llm-deepseek.patch
```

- Patches target `index.js` with `a/index.js`/`b/index.js` headers; run from the repo root.
- **Line endings**: bundles are LF-only; `-c core.autocrlf=false` is mandatory on Windows.
- **Version pin**: context is exact for `0.1.0-rc.6`. If `git apply` fails, the installed version differs — re-diff against `npm pack @deepseek-ai/dsh-host-apiproxy@0.1.0-rc.6` (and the same for `dsh-llm-pi-ai` and `dsh-llm-deepseek`).
- **Idempotency**: `install.ps1`/`install.sh` detect the patch state via markers (host: string `MODEL_DOES_NOT_SUPPORT_IMAGES` absent ⇒ patched; selectmodel: `does not accept image input` absent ⇒ patched; llm (pi-ai / deepseek): function `projectImageBlocksToText` present ⇒ patched).

## Verification (after deploy + restart + hard refresh)

1. Paste an image into the chat box and send it (empty text auto-sends).
2. Expected: the agent's turn shows it analyzed the image (description/OCR/answers).
3. On the wire: the user message that reached the LLM contains `[图片附件：<path>（如需了解内容，请调用你可用的视觉识图工具识别此图片；例如 vision_chat，images 参数传此路径）]` — the placeholder is a generic instruction (it does not hardcode one tool); the agent calls whichever vision tool it has. This is by design, not an error.
4. Direct checks:

   ```powershell
   # host patch live: the reason string is gone from the running code
   Select-String "$profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" -Pattern 'MODEL_DOES_NOT_SUPPORT_IMAGES'   # -> no match
   # llm patch live (pi-ai adapter)
   Select-String "$profiles\node_modules\@deepseek-ai\dsh-llm-pi-ai\lib\index.js" -Pattern 'projectImageBlocksToText'            # -> match
   # llm patch live (deepseek adapter)
   Select-String "$profiles\node_modules\@deepseek-ai\dsh-llm-deepseek\lib\index.js" -Pattern 'projectImageBlocksToText'         # -> match
   # selectmodel patch live: the reason string is gone from the running code
   Select-String "$profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" -Pattern 'does not accept image input'   # -> no match
   ```

### Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| "当前模型不支持图片…" still shows on send | Host patch not loaded (harness not restarted, or the profile `node_modules` junction was refreshed by a reinstall) | Restart harness; re-apply the patch; verify with the checks above |
| Agent replies "I can't see the image" | No vision tool registered or the API key is missing | Register a vision MCP (e.g. `mcp-qwen-mm-plugins-api`) in `profiles\web\cordis.patch.yml`; set the key; restart |
| Installer reports success but the feature is dead | git silently skips the patch when the path contains non-ASCII characters (e.g. a Chinese user name) — exit 0 but no change | The installer now re-checks file content and fails loudly; manually verify with `Select-String` (above), or move dsh to an ASCII-only path, or apply with `git apply -p1` by hand |
| Placeholder path points to a missing file | Attachment store root differs (`DSH_HOME` override) or the object was cleaned | Check `<DSH_HOME>\attachments\v1\objects\<aa>\<sha256>`; re-paste the image |
| `git apply` fails | Installed package version ≠ 0.1.0-rc.6 | Re-diff against `npm pack` of the exact version |
| `The DeepSeek chat-completions adapter does not support image content.` | `dsh-llm-deepseek` patch missing (after a harness upgrade the DeepSeek official route uses the dedicated adapter, so the pi-ai projection never runs) | Apply `patch\dsh-llm-deepseek.patch` (install.ps1 does this automatically); restart |
| Switching models: `Model "..." does not accept image input, but this session already contains images` | `selectModel` rejection, patch 3 not applied | Apply `patch\dsh-host-apiproxy-selectmodel.patch`; restart |
| Built-in `read_image` tool: "does not declare image input" | Tool-level guard (by design): a text-only model must not consume image blocks | Let the agent use its vision tools (`vision_chat`/`ocr` with the local path) instead; not a bug in this project |
| Images sent to a model that DOES support images | No projection runs (by design) — raw image parts go to the model | Not a bug; the feature targets text-only models |

## Operations

- **Restart harness**: `taskkill /F /T /PID <node dsh web pid>` then `npx -y @deepseek-ai/dsh web --host 127.0.0.1 --port 3080`. `install.ps1` does this automatically.
- **Rollback**: `install.ps1 -Uninstall` (or `git apply -R` both patches), restart.
- **Junction caveat**: `profiles\node_modules\@deepseek-ai\*` are junctions to the npx cache. Re-running `npx -y @deepseek-ai/dsh` with a newer package version can overwrite patched files — re-apply after upgrades.
- **No client changes**: do not patch `dsh-client-ui-conversation` for this feature; the composer already allows pasting.

---

# Extra — how it works (and why it's shaped this way)

- **The rejection lived server-side, not client-side.** The composer accepts pasted images for any model; the error appeared because the host's `prompt` RPC checked `modelInfo.inputModalities` and refused. Removing that one check is the entire client-visible fix.
- **Why path text and not pixels?** A text-only LLM cannot consume image bytes. The image is stored content-addressed by the harness anyway (`attachments/v1/objects/…`), so the cheapest reliable bridge is a path. The placeholder text doubles as an instruction, so any agent with the `vision_chat` tool recognizes the image without extra configuration.
- **Images from tools work too.** The projection recurses into `tool-result` content, so `read_image` / `save_view` results are bridged the same way for text-only models.
- **Attachment display is preserved.** Only the LLM *serialization* is rewritten; the persisted message and the chat UI keep the real image block.

## FAQ

- **Q: Is my image sent anywhere extra?** The pasted image is stored locally by dsh and read by the vision tool via its local path; the vision model (e.g. mimo-v2.5 via your DashScope-compatible endpoint) receives it exactly as before — the feature only changes *which* component reads the image (the vision model instead of the chat model).
- **Q: Does it work with image-capable models?** Yes, unchanged: when `model.input` includes `image`, no projection runs and the model sees the pixels directly.
- **Q: Why is the placeholder in Chinese?** The agent prompt convention in this profile is Chinese; the text is opaque to the model anyway — it only needs to identify the path and the tool name.
- **Q: The repo has no LICENSE.** Add one before publishing (MIT suggested).

---

*Made for DeepSeek Harness users who want to paste a picture and get an answer.*
