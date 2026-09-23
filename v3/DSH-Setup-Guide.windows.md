# DSH 个人配置完整部署手册 · v3（Windows 版）

> **基线**：DSH `0.1.5-rc.1` / Windows 11 · 上一版 `v2` 的修订点见 [`CHANGELOG-v3.md`](./CHANGELOG-v3.md)
> **用途**：新机器复刻、或帮朋友搭建
> **依据分级**：【源码】= 对照过 DSH 源码；【实测】= 命令验证过；【npm】= registry 元数据；【未核实】= 需在目标机确认
>
> ⚠️ **v3 最重要的改动**：v2 把"全局无围栏 + 永不确认"当默认。v3 改为"**围栏对准工作台 + 按会话临时全权**"——手机上少点几十下点击的效果一样，但射程从一个目录缩回而不是整台机器。理由见 §6。

---

## 1. 环境概览

**约定**：`<用户名>` = 你的 Windows 账户名（v2 里写死成了真实用户名，已参数化）。

| 项目 | 值 |
|---|---|
| 操作系统 | Windows 11 |
| Node.js 全局路径 | `D:\CSsoftware\npm-global`（非默认路径，需配 `npm config set prefix`） |
| DSH 安装形态 | `npm install -g @deepseek-ai/dsh` |
| DSH Home | `%USERPROFILE%\.dsh`（=`C:\Users\<用户名>\.dsh`） |
| Web GUI | `http://127.0.0.1:3080` |
| 默认模型 | `qwen-token-plan-cn / qwen3.8-max` |
| 图片生成 | `dashscope / qwen-image-3.0-pro` |
| 搜索 | Exa（自研 `qp-exa-dynamic`，Dynamic Highlights ON） |
| **权限默认（v3 改）** | `workspace-write` + `approval: ask`，围栏=会话工作区（见 §6） |

### Profiles

| Profile | 用途 | v3 权限建议 |
|---|---|---|
| `web` | 主 Web GUI | `workspace-write`（桌面端你在场，够用） |
| `dsh-lark` | 飞书机器人桥接（**手机入口**） | `workspace-write`，围栏=工作台目录；全权按会话临时给 |
| `dsh-lark-sdk` | Lark SDK JSON-RPC 运行时 | 同 `dsh-lark` |
| `open-design` | Open Design 协议接口 | 按需 |

---

## 2. 基础安装

```powershell
node -v                                     # 需 >= 18
npm config set prefix D:\CSsoftware\npm-global
# 把 D:\CSsoftware\npm-global 加进系统 PATH
npm install -g @deepseek-ai/dsh
dsh                                         # 首启创建 ~/.dsh
# 浏览器打开 http://127.0.0.1:3080
```

**启动/停止**（【源码】`apps/cli/src/args.ts` + `bundle/web-app/src/startup.ts`）：

```powershell
dsh web                       # = dsh --profile web，前台常驻，并自动开浏览器
dsh web --no-open             # 不开浏览器
dsh web --port 8080           # 换端口
dsh web --port 0              # OS 分配空闲端口
```

> ⚠️ **没有 `dsh stop` 这个命令**（CLI 只有 `web` 与 `plugin` 两个子命令）。停止 = 前台 Ctrl+C，或结束进程。
> ⚠️ **`--host 0.0.0.0` 会被 CLI 拒绝**，理由见 §10。

---

## 3. 凭证

`%USERPROFILE%\.dsh\.credentials.yaml`：

```yaml
version: 1
refs:
  DEEPSEEK_API_KEY: <YOUR_KEY>
  QWEN_TOKEN_PLAN_CN_API_KEY: <YOUR_KEY>
  MINIMAX_CN_API_KEY: <YOUR_KEY>
  DASHSCOPE_API_KEY: <YOUR_KEY>
```

`DSH_HOME\.env`（**推荐放这里，不要放项目里**）：

```env
EXA_API_KEY=<YOUR_KEY>
```

> **`.env` 的两层**（【源码】`boot/app-boot`）：启动时读 `<cwd>/.env`，另外 `~/.dsh/.env` 作为 home 层且允许设置代理类变量。
> `PATH` / `HOME` / `NODE_OPTIONS` 等**启动期**变量不允许写在 `.env` 里（会直接报错），必须 `export`。
> 同理：`.env` 不随仓库走 —— 所以放 home 层最省事。

**申请入口**：DeepSeek `platform.deepseek.com/api_keys` · 千问 Token Plan `bailian.console.aliyun.com` · MiniMax `platform.minimaxi.com` · DashScope `dashscope.console.aliyun.com` · Exa `dashboard.exa.ai/api-keys`

🔒 `.credentials.yaml` 是**明文**。永远不要提交、不要贴进聊天、不要放进任何同步目录。

---

## 4. 核心设置（`settings.yaml`）

```yaml
# === 默认模型 ===
agent-default-model:
  provider: qwen-token-plan-cn
  model: qwen3.8-max
  reasoningEffort: high

# === Agent 预设 ===
agent-presets:
  default: standard

# === DeepSeek 自定义模型列表 ===
llm-deepseek:
  models:
    - id: deepseek-v4-flash
      name: DeepSeek-V4-Flash
      contextWindow: 1000000
    - id: DeepSeek-V4.1-Flash
      name: DeepSeek-V4.1

# === 视觉路由（图片理解）===
vision-router:
  onboardingSeen: true
  providers:
    - provider: qwen-token-plan-cn
      model: qwen3.8-flash
      fallbacks: []
    - provider: vision-http
      model: ovh/Qwen3.5-397B-A17B
      fallbacks: []

# === 子代理：用小模型省成本 ===
subagent-model-selection:
  enabled: true
  allowedModels:
    - provider: deepseek-official
      model: deepseek-v4-flash

# === Provider ↔ 环境变量映射 ===
llm-pi-ai:
  providers:
    qwen-token-plan-cn:
      apiKeyEnv: QWEN_TOKEN_PLAN_CN_API_KEY
    minimax-cn:
      apiKeyEnv: MINIMAX_CN_API_KEY

# === UI / 桌面 ===
ui-theme: { preference: light }
pet: { visible: false, enabled: false, petId: ouo-neko }
desktop-launcher: { enabled: true, announceToAgent: true }
skin-wallpaper: { enabled: true, wallpaperOpacity: 10, sound: false }
dsh-better-sidebar: { workspaceFence: true, agentOpenTools: true }

# === 远程 / 手机 ===
remote-web-ui:
  autoTunnel: true
  lanBind: true

# === 图片生成 / 搜索 ===
image-generation:
  provider: dashscope
  dashscopeModel: qwen-image-3.0-pro
  dashscopeEndpoint: https://dashscope.aliyuncs.com/api/v1
web-search-deepseek:
  maxUses: 30
  dynamicHighlights: true
qp-exa-dynamic:
  dynamicHighlights: true
  numResults: 10

# === 权限默认（v3 新增）===
permission:
  defaultPreset: workspace-write
```

> **权限默认有两个可写位置**：settings 的 `permission.defaultPreset`（用户设置，影响新会话）与 patch 层的 `permission` 插件 config（部署默认）。二者都行；**别两处写不同值**。
> 【源码】`interaction/permission-presets/src/index.ts`: `PERMISSION_SETTINGS_NAMESPACE = 'permission'`。

---

## 5. Web Profile 插件

### 5.1 两条路线，**不要混装**

| 路线 | 装什么 | 适合 |
|---|---|---|
| **聚合**（v2 走的） | 只装 `@linxin666/dsh-web-all` | 想要 20+ 组件一键到位 |
| **离散** | 逐个装自己要的组件 | 想控制版本/裁掉不要的 |

`@linxin666/dsh-web-all@0.3.24` 的依赖里**已经包含**（【npm】）：

`@linxin666/dsh-client-ui-{community-plugins, git-graph, market, model-capabilities, plugin-manager, preset-center, skill-explorer, skin-center, task-board, web-ui-settings}`、`@linxin666/dsh-{doctor, i18n, liangshen, pet, remote-web-ui, session-archive, ssh, tool-describe-image, usage}`、`dsh-better-sidebar@0.19.1`

⇒ 所以下面这些**都不要**再单独列进 `bundles`（v2 犯了这条）：
`@linxin666/dsh-remote-web-ui`、`@linxin666/dsh-client-ui-skill-explorer`、`dsh-better-sidebar`
混装后果实测：better-sidebar 会同时存在 `0.18.0` 与 `0.19.1`，skill-explorer / remote-web-ui 会同时存在 `0.3.16` 与 `0.3.24`。

> 顺带修正 v2 的 §5 组件表：~~"你手动启用了 SSH / Describe Image / LiangShen / Skill Explorer / Doctor"~~ → 这 5 个是聚合包的**依赖**，随包自动进来；启停写在 patch 层，不是"手动装过"。

### 5.2 依赖清单（聚合路线）

```json
{
  "dependencies": {
    "@dhicoc/dsh-reverse-skill": "^1.0.5",
    "@linxin666/dsh-web-all": "^0.3.24",
    "@xxxyz/dsh-mcp-manager": "^2.2.7",
    "dsh-agent-plugins-market": "^0.7.2",
    "dsh-builtin-browser": "^0.1.22",
    "dsh-chat-import": "^0.19.3",
    "dsh-find-plugin": "^0.3.7",
    "dsh-image-gen": "^0.6.10",
    "dsh-vision-router": "^2.2.1",
    "dshmarket": "^1.45.1",
    "qp-exa-dynamic": "^0.1.0"
  },
  "dsh": { "profile": { "bundles": ["<见下方说明>"], "patchReload": "live" } }
}
```

> ⚠️ **`bundles` 不用手写全**（【源码】`apps/cli/src/plugin.ts`）：`dsh plugin --profile web add <pkg>` 本质是**在该 profile 目录里转发 pnpm**，装完会**按安装态自动 reconcile** `dsh.profile.bundles`——依赖里声明了 `dsh.bundle` 的包会自动进层栈，删掉或没声明 bundle 的会自动出层。
> 所以：**用 `dsh plugin` 装，不要手改 bundles**；手改只在需要固定顺序/打 patch 时才碰。

### 5.3 安装（新设备）

```powershell
# 聚合路线
dsh plugin --profile web add @linxin666/dsh-web-all@latest
# 其余逐个
foreach ($p in @(
  '@xxxyz/dsh-mcp-manager@latest','dsh-builtin-browser@latest','dsh-vision-router@latest',
  'dsh-chat-import@latest','dsh-find-plugin@latest','dsh-image-gen@latest',
  'dsh-agent-plugins-market@latest','dshmarket@latest','@dhicoc/dsh-reverse-skill@latest'
)) { dsh plugin --profile web add $p }
```

**要精确复刻版本**（推荐）：拷 `package.json` + `pnpm-lock.yaml` + `cordis.patch.yml` 到 `$env:USERPROFILE\.dsh\profiles\web\`，然后在那目录里 `pnpm install`。
📌 `pnpm-lock.yaml` 才是版本事实源；v2 正文里那些 `^0.x.y` 是快照，会漂移。

### 5.4 自研插件 `qp-exa-dynamic`（本地 link 是坑）

v2 写的是 `link:C:/Users/Windows11/.dsh/plugins/qp-exa-dynamic` —— **机器相关，换机必坏**。三选一：

```powershell
dsh plugin --profile web add qp-exa-dynamic@latest                        # 推荐
dsh plugin --profile web add github:Geighlord007/qp-exa-dynamic           # 跟 GitHub
dsh plugin --profile web add "link:$env:USERPROFILE\.dsh\plugins\qp-exa-dynamic"  # 本地开发
```

源码：https://github.com/Geighlord007/qp-exa-dynamic ｜ 需要 `EXA_API_KEY`。

---

## 6. 权限与沙箱（v3 核心重写）

### 6.1 先纠正三个概念

**① `approval` 只有两档，且 `never` 是"自动拒绝"**

【源码】`interaction/user-approval/src/index.ts`：

> `'never'` — never prompt anyone: **every ask resolves `rejected` deterministically**. The strict headless stance (CI, unattended runs).

`never` 在服务内部、**在应答者链之前**强制执行——连后注册的应答者都绕不过。所以它**不是"免确认放行"**。

**② 审批只在"越界"后发生，不是每次操作都问**

【源码】`sandbox/sandbox/src/escalation.ts`：唯一的审批通路是沙箱升权。流程是
内核拒绝 → agent 看到 `[sandbox: file access denied under workspace-write mode]` + 升权提示 → 它带 `sandbox_permissions` + `justification` 重试 → **这才弹审批**。
升权是**一次性**的（`allowed-once`，只授权所询问的那一个操作）。
⇒ **在工作区里编辑文件，本来就不需要任何审批。**

**③ 围栏是"会话工作区"，不是 patch 里的 `workspaceRoot`**

【源码】`sandbox/sandbox-policy/src/index.ts`：

```ts
workspaceRoot: resolveWorkspaceRoot(session?.header.cwd ?? this.workspaceRoot)
```

配置项 `workspaceRoot` 只对**无 cwd 的会话/无 agent 调用**生效。真实会话用**自己的 cwd** 当边界。
而 `workspace-write` 允许写的范围（【源码】`sandbox/sandbox/src/roots.ts`）= **会话工作区 + `/tmp` + `os.tmpdir()`**。

⇒ **真正决定射程的是"会话工作区指向哪"，不是 patch 里那个 `workspaceRoot`。** v2 里 `workspaceRoot: !!js process.cwd()` 基本是个空操作，还容易让人误以为围栏已设。

### 6.2 出厂 preset 表（别和它打架）

| preset | sandbox | approval |
|---|---|---|
| `workspace-write` | workspace-write | **ask** |
| `danger-full-access` | danger-full-access | **never** |

【源码】`interaction/permission-presets/src/index.ts` 的 `Config.presets` 默认表。这两个是**成对绑定**的：全权时没有可问的事，所以配 `never`。

> ⚠️ **危险组合**：`workspace-write` + `never`。越界操作会走"拒绝 → 尝试升权 → `never` 直接判 rejected"。结果：**你手机上收不到任何提示，但 agent 会告诉你"用户拒绝了这个操作"**。你会去查一个你从没做过的拒绝。

### 6.3 v3 推荐的策略（手机优先，且几乎不弹审批）

**① web（桌面）**：`workspace-write` + `ask`（出厂默认，什么都不用改）。

**② dsh-lark（手机）**：仍然是 `workspace-write` + `ask`，但**把会话工作区指到一个"工作台"根目录**，把手机上要碰的东西都收进去。→ 常规编辑/传输 **0 次审批**，射程缩在一个目录内。

**③ 越界需求：用一条命令，而不是 N 次点击。** `permission-presets` 自带 `/permission` 命令（【源码】同包），切的是**当前会话**的 preset，落成 `permission/preset` + `sandbox/mode` + `approval/policy` 事件——durable、可 replay、**不影响其它会话**。

**④ 想保留"临时全权"就加一档自定义 preset**（比全局 `never` 好）：

```yaml
# cordis.patch.yml
- id: permission
  config:
    presets:
      read-only:            { sandbox: read-only,            approval: ask }
      workspace-write:      { sandbox: workspace-write,      approval: ask }
      full-access-ask:      { sandbox: danger-full-access,   approval: ask }   # ← 全权但不吞掉别的插件的审批
      danger-full-access:   { sandbox: danger-full-access,   approval: never }
    defaultPreset: workspace-write
```

**⑤ 为什么值得这么绕**：KimiCU 那条 MCP、Lark 桥接、以及别的插件自己的危险操作询问都走 `ctx.approval`。全局 `never` 会**把它们一起静默拒掉**——你会看到一堆"莫名其妙失败"。

### 6.4 平台差异（**别互相推断**）

| 平台 | 写限制后端 | 强度 |
|---|---|---|
| Linux | **bwrap + Landlock** | 内核级 |
| macOS | Seatbelt | 内核级 |
| **Windows** | **受限令牌 + ACL**（`packages/sandbox/sandbox-windows-acl`） | ACL 级，**不等价** |

【源码】`sandbox/README.zh.md`。文档说沙箱"仅限同世界"——它与宿主共享内核与文件系统，**不是容器/微VM**。
⇒ Windows 上**不要**把 `workspace-write` 当成 Linux 那样的硬隔离来依赖；它的边界是 ACL 授予。【未核实】具体到你的 Windows 构建，建议实测一次"故意越界写"看是否被拦。

### 6.5 与 v2 的差异（要说服自己就对照这张表）

| | v2 | v3 |
|---|---|---|
| 默认 preset | `danger-full-access` | `workspace-write` |
| 围栏 | 无 | 会话工作区（手机 profile 对准工作台） |
| 全权怎么给 | 一直是 | 按会话 `/permission` 临时切 |
| 审批默认 | 全局 `never` | `ask`（保住别的插件的询问） |
| 手机体验 | 无提示 | 常规 0 次提示；越界 1 条命令 |

---

## 7. Skills / Presets / Skins（路径修正）

### 7.1 技能有 4 个发现根（v2 只写了 1 个）

【源码】`skill/skill-filesystem/src/index.ts` L246–254：

| 根 | 路径 | 来源标记 |
|---|---|---|
| 项目 | `<项目根>/.dsh/skills` | `project-dsh` |
| 项目 | `<项目根>/.agents/skills` | `project-agents` |
| 用户 | `~/.dsh/skills` | `user-dsh` |
| 用户 | **`$DSH_AGENTS_HOME` 或 `~/.agents`** 下的 `skills/` | `user-agents` |

> `~/.agents` 是**与其它 agent 工具共享**的数据根（可由 `DSH_AGENTS_HOME` 覆盖）。
> 💡 **你这套技能的实际位置是 `~/.agents/skills`，而且它是一个 git 仓库**（`Geighlord007/Agent-skills_QP`）。
> ⇒ 迁移**不要**"拷贝 skills 目录"，直接 `git clone` 到新机器的 `~/.agents/skills` 即可，还能继续同步。

### 7.2 Agent Presets

`~/.dsh/.agent-presets/`（【源码】`USER_PRESET_DIR = '.agent-presets'` 挂在 DSH home 下）。

### 7.3 全局工作指令 `AGENTS.md`

| 位置 | 作用 |
|---|---|
| `~/.dsh/AGENTS.md` | **固定的用户全局指令**（推荐把全局规则放这里） |
| `<项目根>/**/AGENTS.md`、`CLAUDE.md` | 项目级，从项目根到 cwd 逐层发现 |

⚠️ v2 的 `AGENTS.md` 草稿开头写了"尚未放入 `~/.dsh/AGENTS.md`"——**确实没放**。另外注意：写在 `C:\Users\<用户名>\AGENTS.md`（home 根）**不一定被读到**，取决于 cwd 解析出的项目根；要可靠就放 `~/.dsh/AGENTS.md`。

---

## 8. MCP

```yaml
- insert:
    - id: mcp-kimi-cu
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: kimi-cu
        transport: stdio
        command: '$env:LOCALAPPDATA\KimiCU\kimi-cu.exe'   # ← 别硬编码用户名
        args: ['mcp']
```

【未核实】`$env:LOCALAPPDATA` 是否被 patch 层当变量展开——若不支持，安装脚本里用正则替换（见 §12 脚本第 7 步）。

---

## 9. Lark / 飞书 profile

需要的环境变量：

```env
DSH_LARK_APP_ID=cli_<YOUR_ID>
DSH_LARK_APP_SECRET=<YOUR_SECRET>
DSH_LARK_WORKSPACE=<工作台目录>        # ← v3 重点：这就是围栏边界
DSH_LARK_NOTIFY_URL=...
DSH_LARK_NOTIFY_TOKEN=...
```

### 手机场景的真实瓶颈（v3 新增）

审批粒度是**单次操作**（`allowed-once`），没有"本会话都允许"、没有白名单规则、`ApprovalPolicy` 只有 `ask`/`never`（【源码】）。所以在飞书里逐条确认确实是设计缺口。
**正确的解法不是拆围栏，是三件事**：把 `DSH_LARK_WORKSPACE` 对准工作台 → 常规操作 0 审批；越界用 `/permission` 一条命令切会话；`never` 别当默认。

> ❓ **待你在目标机验证**：飞书这条链路是否把 `/permission` 这类斜杠命令暴露出来（`ctx.commands` 的桥接取决于 `dsh-lark-bot` 实现，本机没有该 profile，我无法核实）。**如果不能**，那才需要修——修"手机端缺一个会话级权限开关"，而不是拆围栏。

---

## 10. SSH 远程主机 / Remote Web UI

```json
// ~/.dsh/dsh-ssh.json
{ "alias": "<YOUR_SERVER_IP>", "host": "<YOUR_SERVER_IP>", "port": 22, "user": "root",
  "auth": { "kind": "password" } }
```

密码在 DSH 内部存储，迁移需重输。Remote Web UI 设备配对需重新扫码。

🚨 **暴露面提醒**：`host: '0.0.0.0'` + `remote-web-ui.autoTunnel: true` + `lanBind: true` = **局域网 + 隧道都能进**。

【源码】`bundle/web-app/src/startup.ts` 里，上游**明文拒绝** `--host 0.0.0.0`：

> `error: --host 0.0.0.0 is intentionally not supported yet for safety: it would expose remote code execution to the network; use 127.0.0.1 instead`

也就是说 v2 §5 里那条 `host: '0.0.0.0'` 是**绕过上游刻意设的闸门**（配置层仍接受该值）。要走隧道/自定义域名，正确做法是绑 loopback + `--trusted-host <该authority>`（`/api` 的 browser-trust 围栏只认 loopback、LAN IP 字面量和显式声明的 authority）。
⚠️ 且该围栏**不是鉴权层**（上游注释原话："this fence is not an auth layer"）——它防 DNS rebinding 与跨站，不防陌生人。

---

## 11. 迁移清单（修正版）

| 优先级 | 文件 | 说明 | 可直接拷? |
|---|---|---|---|
| 🔴 P0 | `profiles/web/package.json` | 依赖清单 | ✅ 改用户名路径 |
| 🔴 P0 | `profiles/web/pnpm-lock.yaml` | **版本事实源** | ✅ |
| 🔴 P0 | `profiles/web/cordis.patch.yml` | 所有自定义覆盖 | ⚠️ 改 KimiCU 路径 |
| 🔴 P0 | `.credentials.yaml` | API 密钥 | ⚠️ 换成自己的 |
| 🟡 P1 | `.env`（home 层） | `EXA_API_KEY` 等 | ⚠️ 换成自己的 |
| 🟡 P1 | `settings.yaml` | 模型/UI/搜索/`permission.defaultPreset` | ✅ |
| 🟡 P1 | `profiles/dsh-lark{,-sdk}/cordis.patch.yml` | 飞书覆盖 | ⚠️ 按 §6 重设权限 |
| 🟢 P2 | `~/.agents/skills/` | 技能 | ✅ **用 git clone**，别拷目录 |
| 🟢 P2 | `.agent-presets/` | 自定义预设（liangshen 由插件同步） | ✅ |
| 🟢 P2 | `AGENTS.md` → `~/.dsh/AGENTS.md` | 全局指令 | ✅ 注意路径（§7.3） |
| 🟢 P2 | `skins/` + `skin-center-active.json` + `dream-skin.json` | 皮肤 | ✅ 或 Skin Center 重装 |
| 🟢 P2 | `dsh-ssh.json` | 主机列表 | ✅ 密码重输 |
| ⚪ P3 | `plugins/qp-exa-dynamic/` | 自研插件 | ✅ 优先用 npm 版 |

**不需要迁移**：`sessions/`、`cache/`、`profiles/*/node_modules/`、`logs/`、`storages/`、`task-board/`、`.anonymous-user-id`、`remote-web-ui-devices.json`、`profiles/web/.dsh-market/`

**必须重新做**：SSH 密码 · Remote Web UI 配对 · KimiCU 路径 · Lark App 凭证 · `pnpm install`

---

## 12. 部署脚本（含路径参数化）

```powershell
# === 精确复刻 ===
$dshHome = "$env:USERPROFILE\.dsh"
$backup  = "<U盘或云盘路径>\.dsh-backup"

npm install -g @deepseek-ai/dsh
dsh --version
# 若在运行：先停掉（没有 dsh stop 命令，直接结束进程）
#   Get-Process | Where-Object { $_.Path -like '*dsh*' } | Stop-Process

foreach ($f in @('.credentials.yaml','.env','settings.yaml','skin-center-active.json',
                 'dream-skin.json','dsh-ssh.json','pet.json')) {
  if (Test-Path "$backup\$f") { Copy-Item "$backup\$f" "$dshHome\$f" -Force; "  ✅ $f" }
}
foreach ($p in @('web','dsh-lark','dsh-lark-sdk')) {
  $src="$backup\profiles\$p"; $dst="$dshHome\profiles\$p"
  if (Test-Path $src) { foreach ($f in @('package.json','cordis.patch.yml','pnpm-lock.yaml','cordis.yml')) {
    if (Test-Path "$src\$f") { Copy-Item "$src\$f" "$dst\$f" -Force } }; "  ✅ profiles/$p" }
}
foreach ($d in @('skills','skins','.agent-presets','plugins')) {
  if (Test-Path "$backup\$d") { Copy-Item "$backup\$d" "$dshHome\$d" -Recurse -Force; "  ✅ $d/" }
}

# 路径参数化：把所有写死的用户名换成当前用户
$patch = "$dshHome\profiles\web\cordis.patch.yml"
if (Test-Path $patch) {
  (Get-Content $patch -Raw) -replace 'C:\\Users\\[^\\]+\\', "$env:USERPROFILE\" |
    Set-Content $patch -NoNewline
  "  ✅ 路径已参数化"
}

Push-Location "$dshHome\profiles\web"; pnpm install; Pop-Location
dsh
# 验证 http://127.0.0.1:3080
```

**首启自检**（【源码】语义）：`/permission` 看当前 preset 是否为 `workspace-write`；故意在会话工作区写一个文件（应成功、无提示）；故意在围栏外写（应看到 `[sandbox: file access denied ...]` 并触发一次升权提示）。**这一对测试就是"围栏是否真的生效"的判据。**

---

## 13. 配置文件速查（修正版）

| 文件/目录 | 路径 | 依据 |
|---|---|---|
| DSH Home | `~/.dsh/`（可被 `DSH_HOME` 覆盖） | 【源码】`util/home-paths` |
| 凭证 | `~/.dsh/.credentials.yaml` | 【源码】`credentials/credentials-local` |
| 环境变量 | `~/.dsh/.env` 或 `<cwd>/.env` | 【源码】`boot/app-boot` |
| 核心设置 | `~/.dsh/settings.yaml` | 【源码】`settings/settings-file` |
| Web Profile patch | `~/.dsh/profiles/web/cordis.patch.yml` | 【实测】 |
| 全局指令 | **`~/.dsh/AGENTS.md`** | 【源码】`context/agent-instructions` |
| 技能 | `~/.dsh/skills/` **和** `~/.agents/skills/`（+项目级两个） | 【源码】`skill/skill-filesystem` |
| Agent Presets | `~/.dsh/.agent-presets/` | 【源码】`preset/agent-presets` |
| 插件源码 | `~/.dsh/plugins/` | 【实测】 |
| Skins / 皮肤激活 | `~/.dsh/skins/`、`~/.dsh/skin-center-active.json` | 【未核实】插件所有 |
| 会话 / 日志 | `~/.dsh/sessions/`、`~/.dsh/logs/` | 【实测】 |

---

## 14. 故障排查（v3 新增）

启动即失败时按这个顺序：

1. **`dsh --version` 报错** → 先看它有没有"临时目录不可写"这类系统错误。DSH 启动要建临时包管理器目录，只读的 home（或只读挂载）会直接失败。
2. **模型报错** → 查 `settings.yaml` 的 `agent-default-model` 对应 provider 的 key 是否在 `.credentials.yaml` 里存在（provider 名与 env 名靠 `llm-pi-ai.providers.*.apiKeyEnv` 绑定）。
3. **插件加载失败 / 界面缺组件** → 多半是**版本代差**（插件按新 DSH 写、你的 DSH 是旧版）。处置：`cordis.patch.yml` 里先 `disabled: true` 隔离，再决定升级谁。
4. **越界操作莫名其妙失败** → 查是不是 `workspace-write` + `never`（§6.2 的危险组合）；看会话日志里有没有 `approval/asked` 配对。
5. **两个同名组件都出现** → 聚合包 + 离散包混装（§5.1）。
6. **`~/.dsh/.env` 不生效** → 检查是否写了 `PATH`/`NODE_OPTIONS` 之类启动期变量（会被拒）；改用 `export`。

---

*基于 v2 修订 · 核查基线 DSH `0.1.3-alpha.1` / 源码 `d347e70390` · 未核实项已逐条标注*
