# dsh-vision-bridge

在 DeepSeek Harness 聊天框里直接**粘贴图片，让 AI 自动识别并回答**——不再报"当前模型不支持图片"，也不用手动传文件路径。

| | |
|---|---|
| **平台** | Windows / macOS / Linux（dsh web） |
| **依赖** | DeepSeek Harness `dsh web` 0.1.0-rc.6 + **qwen-mm-plugins-api** MCP 服务（`vision_chat` 工具） |
| **许可** | MIT（发布前请自行添加 `LICENSE` 文件） |

> English version: [README.md](README.md)。

---

# 第一部分 — 如果你是人类请看

*这一部分写给只想把功能装好就用的你。*

## 这个插件是干什么的

在此之前，用不支持图片的模型（比如 `deepseek-v4-flash`）在聊天框粘贴图片，发送时会报：

> 当前模型不支持图片，请切换支持图片的模型

装上这个项目之后：

1. **把图片粘贴进输入框**（正常显示缩略图）；
2. **发送**——即使聊天模型不支持图片，消息也能正常发出；
3. Harness 自动把图片以**本地路径**的形式交给 AI，AI **自动调用你可用的视觉识图工具**识别图片——描述、OCR、问答，你问什么它答什么。

全程不需要你手动填路径，识别全自动。

> **请务必理解这一点**：这个项目**只是一座桥**——它负责"图片能发出去、并且以路径形式交给 AI"。它**不包含、也不替你安装任何视觉模型**：
> - 视觉模型插件需要**你自己另外配置**（例如把 qwen-mm-plugins-api 注册进 `profiles\web\cordis.patch.yml`，并配好 API key）；
> - 视觉模型**可以自由选择**——只要是一个"能接收图片并返回文字描述"的工具即可，不限于某一个；
> - 如果你没说用哪个视觉模型，让 AI **自己推荐一个能适配的**（比如 `mcp-qwen-mm-plugins-api` 的 `vision_chat`）；AI 会按占位符里的提示，调用它当前可用的识图工具。

## 展示图位置

_把你的截图放进 [`screenshots/`](screenshots) 文件夹，然后在下面引用。_

![输入框里粘贴的图片](screenshots/paste.png)

![AI 自动描述粘贴的图片](screenshots/result.png)

## 环境要求

- DeepSeek Harness Web 界面（`dsh web --host 127.0.0.1 --port 3080`）
- **qwen-mm-plugins-api** MCP 服务已注册到 web profile（提供 `vision_chat` 工具；需要可用的 DashScope 兼容 API key）
- `git`（安装脚本用它打补丁）

## 手动部署（Windows）

1. **打 host 补丁**（移除"模型不支持图片"的拒绝）：

   ```powershell
   cd "$env:USERPROFILE\.dsh\profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib"
   git -c core.autocrlf=false apply --unsafe-paths --directory="$PWD" "..\..\..\..\..\..\dsh-vision-bridge\patch\dsh-host-apiproxy.patch"
   ```

2. **打 LLM 补丁**（纯文本模型收到图片时，把图片转成"路径 + 识图指令"）：

   ```powershell
   cd "$env:USERPROFILE\.dsh\profiles\node_modules\@deepseek-ai\dsh-llm-pi-ai\lib"
   git -c core.autocrlf=false apply --unsafe-paths --directory="$PWD" "..\..\..\..\..\..\dsh-vision-bridge\patch\dsh-llm-pi-ai.patch"
   ```

3. **重启 harness** — 关闭 *DeepSeek Harness Server* 窗口，重新运行 `start-dsh.bat`（或重启 `dsh web`），然后**强制刷新浏览器（Ctrl+F5）**。

### 一条命令搞定

```powershell
.\install.ps1          # 自动打两个补丁并重启 harness
```

## 让 AI 帮你部署

把下面这段话原样发给你的 AI 助手：

> 请把 `https://github.com/chou109/dsh-vision-bridge` 里的 dsh-vision-bridge 功能部署到我的本地 DeepSeek Harness web profile。
> 1) Windows 下在仓库根目录运行 `.\install.ps1`——它用 `git -c core.autocrlf=false apply` 把 `patch\dsh-host-apiproxy.patch` 和 `patch\dsh-llm-pi-ai.patch` 打进 `%USERPROFILE%\.dsh\profiles\node_modules\@deepseek-ai\...` 对应文件，然后重启 harness。macOS/Linux 用 `./install.sh`（重启 `dsh web` 由我自己来）。
> 2) 脚本不可用时，按 README「如果你是 AI 请看」的精确步骤手动打两个补丁。
> 3) 注意：这个项目**只是"图片发送 + 视觉模型插件"之间的桥**，它本身不包含视觉模型——视觉模型插件需要我另外配置，而且视觉模型可以自由选择。如果我没有指定用哪个视觉模型，请帮我**推荐一个能适配的**（例如 `mcp-qwen-mm-plugins-api` / `vision_chat`），并确认它在 `profiles\web\cordis.patch.yml` 里注册好、API key 可用。
> 4) harness 起来后验证：我在聊天框粘贴一张图片发送，AI 必须自动识别图片内容（它会收到 `[图片附件：<路径>（如需了解内容，请调用你可用的视觉识图工具…）]` 并自动调用识图工具）。

## 使用方法

1. 在聊天框**粘贴（Ctrl+V）或拖入**一张图片。
2. （可选）输入问题，比如"这是什么"。
3. 发送。AI 会自动用 `vision_chat` 识别图片并回答。
4. 只贴图**不打字**也可以——消息会自动发送。

## 卸载

```powershell
.\install.ps1 -Uninstall
```

或者手动：`git apply -R` 两个补丁（或重装 `@deepseek-ai/dsh-host-apiproxy@0.1.0-rc.6` 和 `@deepseek-ai/dsh-llm-pi-ai@0.1.0-rc.6`），然后重启 harness。

---

# 第二部分 — 如果你是 AI 请看

*这一部分写给负责安装、调试、扩展这个功能的 AI 代理。假设你能执行命令、能读 `node_modules` 里的 dsh 包。*

## 这是什么（客观事实）

粘贴识图 = **对两个随包 dsh 文件打补丁**（客户端完全不用改——输入框本来就允许粘贴，拦截点在发送时的服务端拒绝）：

1. **`patch/dsh-host-apiproxy.patch`** — 在 `@deepseek-ai/dsh-host-apiproxy/lib/index.js` 的 `prompt` RPC 里，原来当所选模型的 `inputModalities` 不含 `image` 时，会拒绝任何带图片部分的消息（返回 `attachment-error` / `MODEL_DOES_NOT_SUPPORT_IMAGES`，前端渲染成"当前模型不支持图片…"）。补丁删掉这段拒绝：**任何模型都放行图片**。（1 个 hunk，文件变小。）

2. **`patch/dsh-llm-pi-ai.patch`** — 在 `@deepseek-ai/dsh-llm-pi-ai/lib/index.js` 的 `stream()` 里，原来纯文本模型收到图片块会抛 `UNSUPPORTED_CONTENT`。补丁改为把每个图片块**投影成文本占位符**：

   ```
   [图片附件：<绝对路径>（如需了解内容，请调用你可用的视觉识图工具识别此图片；例如 vision_chat，images 参数传此路径）]
   ```

   路径由 `imageAttachmentPath()` 从内容寻址引用解析：`<DSH_HOME>/attachments/v1/objects/<aa>/<sha256>.<ext>`（尽力硬链补上扩展名，方便工具识别类型）。投影会递归进入 `tool-result` 内容，所以工具返回的图片（如 `read_image`）同样处理。（3 个 hunk。）

3. **识别侧不在本仓库** — 占位符是**通用指令**（"调用你可用的视觉识图工具"），AI 会自动选择它当前可用的识图工具。典型搭配是 **qwen-mm-plugins-api** MCP 服务的 `vision_chat`（需已注册在 profile `profiles/web/cordis.patch.yml` → `mcp-qwen-mm-plugins-api` 且 API key 可用），但**不限于此**——任何"输入图片路径、输出文字描述"的工具都能适配。

**数据流：** 粘贴 → 草稿缩略图 → 发送 → `prompt` RPC 放行（补丁 1）→ 消息持久化保留图片块（聊天历史仍显示图片）→ LLM 请求序列化遇到纯文本模型 → 投影（补丁 2）→ AI 上下文收到路径占位符 → AI 调用可用的识图工具（如 `vision_chat(path)`）→ 回答。

## 部署（精确步骤）

```powershell
$profiles = "$env:USERPROFILE\.dsh\profiles"          # 或 $env:DSH_HOME\profiles

# 1. host-apiproxy（移除拒绝）
$d = "$profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib"
git -c core.autocrlf=false apply --unsafe-paths --directory="$d" patch\dsh-host-apiproxy.patch

# 2. llm-pi-ai（图片 -> 路径文本投影）
$d = "$profiles\node_modules\@deepseek-ai\dsh-llm-pi-ai\lib"
git -c core.autocrlf=false apply --unsafe-paths --directory="$d" patch\dsh-llm-pi-ai.patch
```

- 补丁目标是 `index.js`，头为 `a/index.js`/`b/index.js`；在仓库根目录执行。
- **换行符**：bundle 是纯 LF；Windows 上必须 `-c core.autocrlf=false`。
- **版本锁定**：上下文针对 `0.1.0-rc.6`。`git apply` 失败说明版本不一致——用 `npm pack @deepseek-ai/dsh-host-apiproxy@0.1.0-rc.6`（`dsh-llm-pi-ai` 同理）重新 diff。
- **幂等**：`install.ps1`/`install.sh` 用标记判断是否已打（host：`MODEL_DOES_NOT_SUPPORT_IMAGES` 字符串**不存在**=已打；llm：`projectImageBlocksToText` 函数**存在**=已打）。

## 部署后验证

1. 在聊天框粘贴一张图片并发送（不打字会自动发送）。
2. 预期：AI 的回答显示它分析了图片（描述/OCR/回答）。
3. 链路上：到达 LLM 的用户消息里含 `[图片附件：<路径>（如需了解内容，请调用你可用的视觉识图工具识别此图片；例如 vision_chat，images 参数传此路径）]`——占位符是通用指令（不写死某个工具），AI 会调用它当前可用的识图工具；这是设计，不是报错。
4. 直接检查：

   ```powershell
   # host 补丁生效：错误码字符串已从运行代码中消失
   Select-String "$profiles\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" -Pattern 'MODEL_DOES_NOT_SUPPORT_IMAGES'   # -> 无匹配
   # llm 补丁生效
   Select-String "$profiles\node_modules\@deepseek-ai\dsh-llm-pi-ai\lib\index.js" -Pattern 'projectImageBlocksToText'            # -> 有匹配
   ```

### 常见故障

| 现象 | 原因 | 处理 |
|---|---|---|
| 发送时仍提示"当前模型不支持图片…" | host 补丁没加载（没重启，或 profile 的 `node_modules` junction 被重装刷新） | 重启 harness；重新打补丁；用上面的检查确认 |
| AI 回复"看不到图片" | 识图工具没注册或 key 缺失 | 检查 `profiles\web\cordis.patch.yml` 有对应的识图 MCP（如 `mcp-qwen-mm-plugins-api`）；配置 key；重启 |
| 安装脚本显示成功但功能没生效 | git 在含非 ASCII 字符的路径（如中文用户名）下可能**静默跳过**补丁（exit 0 但文件没变） | 安装脚本现在会做"按内容复查"并大声报错；手动时用 `Select-String` 验证（见上），或把 dsh 移到纯 ASCII 路径，或手动 `git apply -p1` |
| 占位符路径指向不存在的文件 | 附件存储根不同（`DSH_HOME` 覆盖）或对象被清理 | 检查 `<DSH_HOME>\attachments\v1\objects\<aa>\<sha256>`；重新粘贴图片 |
| `git apply` 失败 | 安装的包版本 ≠ 0.1.0-rc.6 | 用 `npm pack` 精确版本重新 diff |
| 图片发给支持图片的模型 | 不投影（设计如此）——原始图片直接给模型 | 不是 bug；本功能面向纯文本模型 |

## 运维

- **重启 harness**：`taskkill /F /T /PID <node dsh web pid>` 后 `npx -y @deepseek-ai/dsh web --host 127.0.0.1 --port 3080`。`install.ps1` 自动完成。
- **回滚**：`install.ps1 -Uninstall`（或 `git apply -R` 两个补丁），重启。
- **junction 陷阱**：`profiles\node_modules\@deepseek-ai\*` 是指向 npx 缓存的 junction。用新版本重跑 `npx -y @deepseek-ai/dsh` 可能覆盖补丁文件——升级后重新打补丁。
- **不要改客户端**：本功能不需要动 `dsh-client-ui-conversation`；输入框本来就允许粘贴。

---

# 补充 — 原理与设计取舍

- **拦截点在服务端而非客户端。** 输入框对任何模型都接受粘贴；报错来自 host 的 `prompt` RPC 检查 `modelInfo.inputModalities` 后拒绝。删掉这一处检查就是整个用户可见的修复。
- **为什么用路径文本而不是像素？** 纯文本 LLM 无法消费图片字节。harness 本来就把图片内容寻址存储（`attachments/v1/objects/…`），所以最省事可靠的桥接就是路径。占位符文本顺带就是指令——任何带 `vision_chat` 工具的 AI 无需额外配置就会识别图片。
- **工具返回的图片同样处理。** 投影递归进入 `tool-result`，`read_image`/`save_view` 的结果对纯文本模型也走同一桥接。
- **聊天记录里的图片不丢。** 只改写 LLM *序列化*；持久化消息和聊天 UI 保留真实图片块。

## FAQ

- **Q: 图片会被额外发送到别处吗？** 粘贴的图片由 dsh 本地存储，识图工具通过本地路径读取；视觉模型（如 mimo-v2.5，走你的 DashScope 兼容端点）收到的内容与之前完全一致——本功能只是改变了*谁*来读图（视觉模型代替聊天模型）。
- **Q: 支持图片的模型也能用吗？** 能，行为不变：`model.input` 含 `image` 时不投影，模型直接看像素。
- **Q: 为什么占位符是中文？** 该 profile 的代理提示约定是中文；对模型来说文本本身无所谓——它只需要识别出路径和工具名。
- **Q: 仓库为什么没有 LICENSE？** 发布前请添加（建议 MIT）。

---

*献给想把图一贴就能得到回答的 DeepSeek Harness 用户。*
