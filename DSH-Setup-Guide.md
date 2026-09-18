# 🛠️ DSH (DeepSeek Harness) 个人配置完整部署手册

> **用途**: 在新电脑/新设备上快速复刻当前 DSH 环境，或帮助朋友搭建相同配置。
> **最后更新**: 2026-09-18 (v2 - 修正版)
> **当前版本**: DSH 0.1.5-rc.1 + Web GUI (port 3080)
> 
> ⚠️ **重要声明**: 本文档记录了所有可迁移的配置，但以下内容**无法通过文档自动迁移**，需要手动操作：
> - API 密钥（必须自己申请）
> - SSH 密码（DSH 内部存储，不导出）
> - Remote Web UI 设备配对（需重新扫码）
> - KimiCU 路径（因用户名而异）
> - Lark 飞书 App ID/Secret（需自己的飞书应用）
> - 对话历史（sessions 目录，可选迁移）

---

## 📋 目录

1. [环境概览](#1-环境概览)
2. [基础安装](#2-基础安装)
3. [API 密钥配置](#3-api-密钥配置)
4. [核心设置 (settings.yaml)](#4-核心设置-settingsyaml)
5. [Web Profile 完整插件清单与安装](#5-web-profile-完整插件清单与安装)
6. [自研插件: qp-exa-dynamic](#6-自研插件-qp-exa-dynamic)
7. [Agent Presets (自定义预设)](#7-agent-presets-自定义预设)
8. [Skills (自定义技能)](#8-skills-自定义技能)
9. [Skins (主题皮肤)](#9-skins-主题皮肤)
10. [MCP 服务器配置](#10-mcp-服务器配置)
11. [Lark/飞书集成 (dsh-lark profile)](#11-lark飞书集成-dsh-lark-profile)
12. [SSH 远程主机](#12-ssh-远程主机)
13. [Remote Web UI (手机远程控制)](#13-remote-web-ui-手机远程控制)
14. [安全策略配置](#14-安全策略配置)
15. [快速部署脚本参考](#15-快速部署脚本参考)
16. [配置文件位置速查表](#16-配置文件位置速查表)

---

## 1. 环境概览

| 项目 | 值 |
|------|-----|
| 操作系统 | Windows 11 |
| Node.js 全局路径 | `D:\CSsoftware\npm-global` |
| DSH 安装路径 | `D:\CSsoftware\npm-global\node_modules\@deepseek-ai\dsh` |
| DSH Home | `C:\Users\<用户名>\.dsh` |
| Web GUI 地址 | `http://127.0.0.1:3080` (LAN: `0.0.0.0:3080`) |
| 默认模型 | `qwen-token-plan-cn / qwen3.8-max` |
| 图片生成 | `dashscope / qwen-image-3.0-pro` |
| 搜索引擎 | Exa (自研插件 qp-exa-dynamic, Dynamic Highlights ON) |
| 安全模式 | `danger-full-access` + approval `never` |
| 已配对手机 | 2台 Android 设备 (via Remote Web UI) |

### 已安装的 Profiles

| Profile | 用途 |
|---------|------|
| `web` | 主 Web GUI，包含所有 UI 插件 |
| `dsh-lark` | 飞书/Lark 机器人桥接 |
| `dsh-lark-sdk` | Lark SDK JSON-RPC 运行时 |
| `open-design` | Open Design 协议接口 |

---

## 2. 基础安装

```bash
# 1. 确保 Node.js >= 18 已安装
node -v

# 2. 全局安装 DSH
npm install -g @deepseek-ai/dsh

# 3. 首次启动 (会自动创建 ~/.dsh 目录)
dsh

# 4. 验证 Web GUI
# 浏览器打开 http://127.0.0.1:3080
```

> ⚠️ **Windows 注意**: 如果 npm 全局路径不在默认位置，需要先配置：
> ```bash
> npm config set prefix D:\CSsoftware\npm-global
> # 并将 D:\CSsoftware\npm-global 加入系统 PATH
> ```

---

## 3. API 密钥配置

编辑 `~/.dsh/.credentials.yaml`:

```yaml
version: 1
refs:
  DEEPSEEK_API_KEY: sk-xxxxx           # DeepSeek 官方 API
  QWEN_TOKEN_PLAN_CN_API_KEY: sk-sp-xxxxx  # 通义千问 Token Plan
  MINIMAX_CN_API_KEY: sk-cp-xxxxx      # MiniMax 中文 API
  DASHSCOPE_API_KEY: sk-ws-xxxxx       # 阿里云 DashScope (图片生成)
```

编辑 `~/.dsh/.env`:

```env
EXA_API_KEY=xxxxx-xxxxx-xxxxx          # Exa 搜索 API
```

> 🔒 **安全提示**: `.credentials.yaml` 中的密钥是明文存储的。不要将此文件提交到 Git 或分享给他人。

### 获取密钥的链接

| 服务 | 获取地址 |
|------|----------|
| DeepSeek | https://platform.deepseek.com/api_keys |
| 通义千问 Token Plan | https://bailian.console.aliyun.com/ |
| MiniMax | https://platform.minimaxi.com/ |
| DashScope | https://dashscope.console.aliyun.com/ |
| Exa | https://dashboard.exa.ai/api-keys |

---

## 4. 核心设置 (settings.yaml)

完整文件位于 `~/.dsh/settings.yaml`，以下是关键配置项及说明：

```yaml
# === 默认模型 ===
agent-default-model:
  provider: qwen-token-plan-cn     # 使用通义千问作为主力
  model: qwen3.8-max               # 最强推理模型

# === Agent 预设 ===
agent-presets:
  default: standard                # 默认使用标准模式

# === DeepSeek 自定义模型列表 ===
llm-deepseek:
  models:
    - id: deepseek-v4-flash
      name: DeepSeek-V4-Flash
      contextWindow: 1000000
    - id: DeepSeek-V4.1-Flash
      name: DeepSeek-V4.1

# === 视觉路由 (图片理解) ===
vision-router:
  onboardingSeen: true
  providers:
    - provider: qwen-token-plan-cn
      model: qwen3.8-flash         # 首选: 千问闪电图文
      fallbacks: []
    - provider: vision-http
      model: ovh/Qwen3.5-397B-A17B # 备选: OVH 托管的千问
      fallbacks: []

# === 子代理模型选择 ===
subagent-model-selection:
  enabled: true
  allowedModels:
    - provider: deepseek-official
      model: deepseek-v4-flash     # 子代理用 DeepSeek 节省成本

# === LLM Provider 环境变量映射 ===
llm-pi-ai:
  providers:
    qwen-token-plan-cn:
      apiKeyEnv: QWEN_TOKEN_PLAN_CN_API_KEY
    minimax-cn:
      apiKeyEnv: MINIMAX_CN_API_KEY

# === UI 主题 ===
ui-theme:
  preference: light                # 浅色主题

# === 桌面宠物 (已关闭) ===
pet:
  visible: false
  enabled: false
  petId: ouo-neko

# === 桌面启动器 ===
desktop-launcher:
  enabled: true
  announceToAgent: true

# === 壁纸 ===
skin-wallpaper:
  enabled: true
  wallpaperOpacity: 10
  sound: false

# === Better Sidebar ===
dsh-better-sidebar:
  workspaceFence: true             # 工作区隔离
  agentOpenTools: true             # Agent 可打开工具面板

# === Remote Web UI ===
remote-web-ui:
  autoTunnel: true                 # 自动建立隧道
  lanBind: true                    # 绑定 LAN 地址

# === 图片生成 ===
image-generation:
  provider: dashscope
  dashscopeModel: qwen-image-3.0-pro
  dashscopeEndpoint: https://dashscope.aliyuncs.com/api/v1

# === 搜索设置 ===
web-search-deepseek:
  maxUses: 30                      # 每轮最多搜索30次
  dynamicHighlights: true

qp-exa-dynamic:
  dynamicHighlights: true
  numResults: 10                   # Exa 默认返回10条
```

---

## 5. Web Profile 完整插件清单与安装

### ⚡ 核心发现: package.json 是真正的安装记录

你的 Web Profile 的实际依赖记录在 `~/.dsh/profiles/web/package.json` 中，**不是**通过单独的 `dsh plugin add` 命令逐个安装的。以下是精确的依赖列表：

```json
{
  "dependencies": {
    "@dhicoc/dsh-reverse-skill": "^1.0.5",
    "@linxin666/dsh-remote-web-ui": "^0.3.21",
    "@linxin666/dsh-web-all": "^0.3.21",
    "@xxxyz/dsh-mcp-manager": "^2.2.7",
    "dsh-agent-plugins-market": "^0.6.2",
    "dsh-builtin-browser": "^0.1.21",
    "dsh-chat-import": "^0.11.2",
    "dsh-find-plugin": "^0.3.7",
    "dsh-image-gen": "^0.6.1",
    "dsh-vision-router": "^2.1.6",
    "dshmarket": "^1.45.1",
    "qp-exa-dynamic": "link:C:/Users/<用户名>/.dsh/plugins/qp-exa-dynamic"
  },
  "dsh": {
    "profile": {
      "bundles": [
        "@deepseek-ai/dsh-base",
        "@deepseek-ai/dsh-web-app",
        "dshmarket",
        "dsh-find-plugin",
        "@linxin666/dsh-web-all",
        "dsh-chat-import",
        "@dhicoc/dsh-reverse-skill",
        "@linxin666/dsh-remote-web-ui",
        "dsh-vision-router",
        "@xxxyz/dsh-mcp-manager",
        "dsh-image-gen",
        "dsh-builtin-browser",
        "qp-exa-dynamic",
        "dsh-agent-plugins-market"
      ]
    }
  }
}
```

### 新设备上的安装步骤

```bash
# 方法 A: 使用 dsh plugin add 逐个安装（推荐，会自动更新 package.json）
dsh plugin --profile web add @linxin666/dsh-web-all@latest
dsh plugin --profile web add @linxin666/dsh-remote-web-ui@latest
dsh plugin --profile web add @xxxyz/dsh-mcp-manager@latest
dsh plugin --profile web add dsh-builtin-browser@latest
dsh plugin --profile web add dsh-vision-router@latest
dsh plugin --profile web add dsh-chat-import@latest
dsh plugin --profile web add dsh-find-plugin@latest
dsh plugin --profile web add dsh-image-gen@latest
dsh plugin --profile web add dsh-agent-plugins-market@latest
dsh plugin --profile web add dshmarket@latest
dsh plugin --profile web add @dhicoc/dsh-reverse-skill@latest
dsh plugin --profile web add qp-exa-dynamic@latest

# 方法 B: 直接复制 package.json + pnpm-lock.yaml + cordis.patch.yml
# 然后运行 pnpm install（适合完全复刻版本号）
cd ~/.dsh/profiles/web
# 复制这三个文件后:
pnpm install
```

> ⚠️ **注意**: `dsh-better-sidebar` 不在 package.json 的直接依赖中，它是 `@linxin666/dsh-web-all` 的子依赖（v0.19.0），会随聚合包自动安装。**不需要单独安装**。

### dsh-web-all 聚合包包含的组件

| 组件 | 默认状态 | 你的配置 |
|------|---------|---------|
| Web UI Settings | ✅ 启用 | ✅ 启用 |
| Plugin Manager | ✅ 启用 | ✅ 启用 |
| Community Plugins | ✅ 启用 | ✅ 启用 |
| Market | ✅ 启用 | ✅ 启用 |
| Task Board | ✅ 启用 | ✅ 启用 |
| Git Graph | ✅ 启用 | ✅ 启用 |
| Remote Web UI | ✅ 启用 | ✅ 启用 |
| Pet | ✅ 启用 | ✅ 启用 |
| SSH | ❌ 默认禁用 | ✅ **你手动启用了** |
| Describe Image | ❌ 默认禁用 | ✅ **你手动启用了** |
| LiangShen | ❌ 默认禁用 | ✅ **你手动启用了** |
| Skill Explorer | ❌ 默认禁用 | ✅ **你手动启用了** |
| Doctor | ❌ 默认禁用 | ✅ **你手动启用了** |
| Usage | ✅ 启用 | ✅ 启用 |
| Session Archive | ✅ 启用 | ✅ 启用 |
| Skin Center | ✅ 启用 | ✅ 启用 |
| i18n | ✅ 启用 | ✅ 启用 |
| Better Sidebar | ✅ 启用 | ✅ 启用 |
| Preset Center | ✅ 启用 | ✅ 启用 |
| Model Capabilities | ✅ 启用 | ✅ 启用 |

> 🔑 **关键点**: 你在 `cordis.patch.yml` 中把 5 个默认禁用的组件改为了 `disabled: false`。这些覆盖必须写在 patch 文件中才能生效。

### Web Profile cordis.patch.yml 手动配置

在 `~/.dsh/profiles/web/cordis.patch.yml` 中需要添加以下关键配置：

```yaml
# === LAN 绑定 (允许局域网访问) ===
- id: webserver
  name: '@deepseek-ai/dsh-host-webserver'
  config:
    host: '0.0.0.0'
    port: 3080
    compression: gzip
    compressionLevel: 1
    compressionThresholdBytes: 1024

# === KimiCU Computer Use MCP ===
- insert:
    - id: mcp-kimi-cu
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: kimi-cu
        transport: stdio
        command: 'C:\Users\<用户名>\AppData\Local\KimiCU\kimi-cu.exe'
        args: ['mcp']

# === 启用所有 Web UI 组件 ===
- id: web-ui-compat
  disabled: false
- id: web-ui-settings
  disabled: false
- id: web-ui-plugin-manager
  disabled: false
# ... (其余 web-ui-* 均设为 disabled: false)

# === 禁用 TUI 组件 (Web 不需要) ===
- id: reverse-skill
  disabled: true
- id: dsh-tui-storage
  disabled: true
# ... (其余 dsh-tui-* 均设为 disabled: true)
- id: working-activity
  disabled: true

# === Exa 搜索提供方切换 ===
- id: web
  name: '@deepseek-ai/dsh-web'
  config:
    searchProvider: exa
    fetchProvider: http

# === Exa API Key (如 .env 不生效则写在这里) ===
- id: qp-exa-dynamic
  name: qp-exa-dynamic
  config:
    apiKey: '<你的 EXA_API_KEY>'
```

---

## 6. 自研插件: qp-exa-dynamic

这是你自己开发的 Exa 搜索插件，解决了官方 `dsh-web-search-exa` 不支持 Dynamic Highlights 的问题。

### 特点
- ✅ 默认开启 Exa Dynamic Highlights
- ✅ 自动发送 `Exa-Beta: dynamic-highlights-2026-08-28` 请求头
- ✅ 提供 `/exa` 命令运行时调整参数
- ✅ 独立的 `exa_search` 工具，支持自定义结果数量
- ✅ 实测 Dynamic Highlights 比传统截断节省 ~75% token

### 安装方式（你当前使用的是本地 link）

你的 `package.json` 中记录的是 **本地 Junction 链接**，不是 npm 包：
```json
"qp-exa-dynamic": "link:C:/Users/Windows11/.dsh/plugins/qp-exa-dynamic"
```

这意味着插件源码在 `~/.dsh/plugins/qp-exa-dynamic/`，Web Profile 通过符号链接引用它。

**在新设备上复刻的方式（三选一）：**

```bash
# 方式 1: 从 npm 安装（最简单，推荐给朋友用）
dsh plugin --profile web add qp-exa-dynamic@latest

# 方式 2: 从 GitHub 安装
dsh plugin --profile web add github:Geighlord007/qp-exa-dynamic

# 方式 3: 保持本地开发模式（适合你自己继续迭代）
# 先把源码克隆/复制到 ~/.dsh/plugins/qp-exa-dynamic/
# 然后:
dsh plugin --profile web add link:~/.dsh/plugins/qp-exa-dynamic
```

### 源码仓库
https://github.com/Geighlord007/qp-exa-dynamic

---

## 7. Agent Presets (自定义预设)

你安装了两个自定义 Agent 预设：

### 梁神模式 (liangshen)
- **来源**: `@linxin666/dsh-liangshen` 插件自动同步
- **描述**: "三秒三辈子的代码，文言文+二进制+摩斯电码三语解说"
- **文件**: `~/.dsh/.agent-presets/liangshen/`
- 包含自定义 system prompt、tool catalog、custom bash

### 锚定标准模式 (anchored-standard)
- **描述**: 任务感知首轮锚定，修复类用极简开局，构建类用实干开局
- **文件**: `~/.dsh/.agent-presets/anchored-standard/`
- 包含自定义 agent.cordis.yml、tool-bootstrap.mjs

---

## 8. Skills (自定义技能)

### eli5 (Explain Like I'm 5)
- **位置**: `~/.dsh/skills/eli5/SKILL.md`
- **触发**: `/eli5 <主题>` 或 "大白话讲讲"
- **输出**: 自包含单文件 HTML，大图少字，适合截图分享

如需在新设备上复用，将 `~/.dsh/skills/` 目录整体拷贝即可。

---

## 9. Skins (主题皮肤)

已安装两套皮肤（来自 Skin Center / dsh-market）：

| 皮肤 | 风格 | 当前状态 |
|------|------|----------|
| **starry-nocturne** | 星空夜景 | ✅ 当前激活 |
| **matrix** | 黑客帝国 | 已安装未激活 |

当前激活配置 (`~/.dsh/skin-center-active.json`):
```json
{
  "active": "starry-nocturne",
  "background": {
    "enabled": true,
    "backgroundOpacity": 15,
    "backgroundBlurContent": 17,
    "inputCardBlur": 10,
    "bubbleOpacity": 50
  }
}
```

Dream Skin: `mist` (薄雾)

### 皮肤安装方式

两套皮肤都来自 **dsh-market.com**（通过 Skin Center UI 安装），不是手动拷贝的。在新设备上：

1. 确保安装了 `@linxin666/dsh-web-all`（包含 Skin Center）
2. 打开 Web GUI → Skin Center
3. 搜索并安装 `starry-nocturne` 和 `matrix`
4. 激活 `starry-nocturne`，配置背景参数

或者手动复制 `~/.dsh/skins/` 目录 + `~/.dsh/skin-center-active.json` + `~/.dsh/dream-skin.json`。

---

## 10. MCP 服务器配置

### KimiCU Computer Use
- **类型**: stdio
- **命令**: `C:\Users\<用户名>\AppData\Local\KimiCU\kimi-cu.exe mcp`
- **工具数**: 13 个 (窗口操作、点击、输入、截图等)
- **用途**: Windows 桌面自动化，操控本地应用

安装 KimiCU: https://github.com/MoonshotAI/KimiCU (或从 Kimi 官网下载)

---

## 11. Lark/飞书集成 (dsh-lark profile)

你配置了完整的飞书机器人桥接：

### Profile: dsh-lark
- 安装了 `dsh-lark-bot` 插件
- 禁用了 plan gate (直接执行，不需审批)
- 默认 `danger-full-access` + approval `never`
- 支持: lark_notify, lark_send_file, lark_ask_user, lark_request_plan_approval

### Profile: dsh-lark-sdk
- SDK JSON-RPC 运行时覆盖层
- 同样禁用了 plan gate
- 自定义了 system prompt (全权限直连模式)

### 需要的环境变量
```env
DSH_LARK_APP_ID=cli_xxxxx
DSH_LARK_APP_SECRET=xxxxx
DSH_LARK_WORKSPACE=/path/to/workspace
DSH_LARK_NOTIFY_URL=http://...
DSH_LARK_NOTIFY_TOKEN=xxxxx
DSH_LARK_FILE_URL=http://...
DSH_LARK_ASK_URL=http://...
DSH_LARK_PLAN_URL=http://...
DSH_LARK_APPROVAL_URL=http://...
```

---

## 12. SSH 远程主机

配置了一台远程服务器 (`~/.dsh/dsh-ssh.json`):

```json
{
  "alias": "<YOUR_SERVER_IP>",
  "host": "<YOUR_SERVER_IP>",
  "port": 22,
  "user": "root",
  "auth": { "kind": "password" }
}
```

> ⚠️ 密码存储在 DSH 内部，迁移时需要重新输入。

---

## 13. Remote Web UI (手机远程控制)

已配对 2 台 Android 设备，可通过手机浏览器访问 DSH Web GUI。

配置要点：
- `remote-web-ui.autoTunnel: true` — 自动建隧
- `remote-web-ui.lanBind: true` — 绑定 LAN
- Web Server 监听 `0.0.0.0:3080`

新设备配对流程：
1. 确保手机和电脑在同一网络
2. 手机浏览器打开 `http://<电脑IP>:3080`
3. 输入配对码完成绑定

---

## 14. 安全策略配置

你的 DSH 采用了**全权限直连模式**：

### dsh-lark / dsh-lark-sdk Profile Patch
```yaml
# 禁用 plan gate
- id: lark-plan-approval
  disabled: true

# 文件沙箱: 完全开放
- id: sandbox-policy
  config:
    mode: danger-full-access
    workspaceRoot: !!js process.cwd()

# 审批: 永不询问
- id: approval
  config:
    policy: never

# 权限预设
- id: permission
  config:
    presets:
      read-only:
        sandbox: read-only
        approval: ask
      workspace-write:
        sandbox: workspace-write
        approval: ask
      danger-full-access:
        sandbox: danger-full-access
        approval: never
    defaultPreset: danger-full-access
```

> ⚠️ **风险提示**: 此配置意味着 AI 可以不经确认执行任何文件操作和命令。仅在你信任 AI 且了解风险时使用。帮朋友安装时建议先用默认的 `ask` 模式。

---

## 15. 快速部署脚本参考

### 方式 A: 文件拷贝法（最精确复刻）

```powershell
# === DSH 精确复刻脚本 ===
# 前提: 已从旧电脑拷贝了整个 ~/.dsh 目录到 U盘/云盘

$dshHome = "$env:USERPROFILE\.dsh"
$backupPath = "<U盘或云盘路径>\.dsh-backup"  # ← 改这里

# 1. 安装 DSH (如果还没装)
npm install -g @deepseek-ai/dsh

# 2. 首次启动创建目录结构
dsh --version  # 不真正启动，只确保目录存在

# 3. 停止 DSH (如果在运行)
dsh stop

# 4. 拷贝配置文件 (⚠️ 不要覆盖 sessions/ 和 node_modules/)
$configFiles = @(
    ".credentials.yaml",      # ← 记得替换密钥!
    ".env",                   # ← 记得替换密钥!
    "settings.yaml",
    "skin-center-active.json",
    "dream-skin.json",
    "dsh-ssh.json",
    "pet.json"
)
foreach ($f in $configFiles) {
    if (Test-Path "$backupPath\$f") {
        Copy-Item "$backupPath\$f" "$dshHome\$f" -Force
        Write-Host "  ✅ $f" -ForegroundColor Green
    }
}

# 5. 拷贝 profiles 配置 (不含 node_modules)
$profiles = @("web", "dsh-lark", "dsh-lark-sdk")
foreach ($p in $profiles) {
    $src = "$backupPath\profiles\$p"
    $dst = "$dshHome\profiles\$p"
    if (Test-Path $src) {
        # 拷贝 package.json, cordis.patch.yml, pnpm-lock.yaml
        foreach ($f in @("package.json", "cordis.patch.yml", "pnpm-lock.yaml", "cordis.yml")) {
            if (Test-Path "$src\$f") {
                Copy-Item "$src\$f" "$dst\$f" -Force
            }
        }
        Write-Host "  ✅ profiles/$p config" -ForegroundColor Green
    }
}

# 6. 拷贝 skills, skins, agent-presets, plugins
foreach ($dir in @("skills", "skins", ".agent-presets", "plugins")) {
    if (Test-Path "$backupPath\$dir") {
        Copy-Item "$backupPath\$dir" "$dshHome\$dir" -Recurse -Force
        Write-Host "  ✅ $dir/" -ForegroundColor Green
    }
}

# 7. ⚠️ 修改 cordis.patch.yml 中的硬编码路径
$kimiCuPath = "$env:LOCALAPPDATA\KimiCU\kimi-cu.exe"
$patchFile = "$dshHome\profiles\web\cordis.patch.yml"
if (Test-Path $patchFile) {
    (Get-Content $patchFile -Raw) -replace 
        'C:\\Users\\[^\\]+\\AppData\\Local\\KimiCU\\kimi-cu\.exe', 
        $kimiCuPath | Set-Content $patchFile
    Write-Host "  ✅ KimiCU path updated" -ForegroundColor Green
}

# 8. 安装依赖
Write-Host "`n📦 Installing web profile dependencies..." -ForegroundColor Cyan
Push-Location "$dshHome\profiles\web"
pnpm install
Pop-Location

# 9. 启动
Write-Host "`n🚀 Starting DSH..." -ForegroundColor Cyan
dsh
Write-Host "✅ 打开 http://127.0.0.1:3080 验证" -ForegroundColor Green
```

### 方式 B: 从零安装法（适合帮朋友装）

```powershell
# === DSH 全新安装脚本 ===

# 1. 安装 DSH
npm install -g @deepseek-ai/dsh

# 2. 首次启动
dsh  # Ctrl+C 停掉，创建 ~/.dsh 目录

# 3. 写入 credentials (⚠️ 替换密钥)
@"
version: 1
refs:
  DEEPSEEK_API_KEY: <YOUR_KEY>
  QWEN_TOKEN_PLAN_CN_API_KEY: <YOUR_KEY>
  DASHSCOPE_API_KEY: <YOUR_KEY>
"@ | Set-Content "$env:USERPROFILE\.dsh\.credentials.yaml"

@"
EXA_API_KEY=<YOUR_KEY>
"@ | Set-Content "$env:USERPROFILE\.dsh\.env"

# 4. 安装核心插件
dsh plugin --profile web add @linxin666/dsh-web-all@latest
dsh plugin --profile web add @linxin666/dsh-remote-web-ui@latest
dsh plugin --profile web add @xxxyz/dsh-mcp-manager@latest
dsh plugin --profile web add dsh-builtin-browser@latest
dsh plugin --profile web add dsh-vision-router@latest
dsh plugin --profile web add dsh-chat-import@latest
dsh plugin --profile web add dsh-image-gen@latest
dsh plugin --profile web add dshmarket@latest
dsh plugin --profile web add qp-exa-dynamic@latest

# 5. 复制 settings.yaml (从本文档第4节重建或从备份拷贝)

# 6. 启动
dsh
Write-Host "✅ 打开 http://127.0.0.1:3080" -ForegroundColor Green
```

---

## 16. 配置文件位置速查表

| 文件/目录 | 路径 | 说明 |
|-----------|------|------|
| DSH Home | `~/.dsh/` | 所有用户数据根目录 |
| 凭证 | `~/.dsh/.credentials.yaml` | API 密钥 (⚠️ 敏感) |
| 环境变量 | `~/.dsh/.env` | EXA_API_KEY 等 |
| 核心设置 | `~/.dsh/settings.yaml` | 模型/UI/插件设置 |
| Web Profile Patch | `~/.dsh/profiles/web/cordis.patch.yml` | Web 插件挂载和配置 |
| Lark Profile Patch | `~/.dsh/profiles/dsh-lark/cordis.patch.yml` | 飞书集成配置 |
| SSH 主机 | `~/.dsh/dsh-ssh.json` | 远程服务器列表 |
| 插件目录 | `~/.dsh/plugins/` | 自研/独立插件 |
| Skills 目录 | `~/.dsh/skills/` | 自定义技能 |
| Skins 目录 | `~/.dsh/skins/` | 主题皮肤 |
| Agent Presets | `~/.dsh/.agent-presets/` | 自定义 Agent 预设 |
| 宠物状态 | `~/.dsh/pet.json` | 桌面宠物数据 |
| 皮肤激活 | `~/.dsh/skin-center-active.json` | 当前皮肤配置 |
| 远控设备 | `~/.dsh/remote-web-ui-devices.json` | 已配对手机 |
| 会话数据 | `~/.dsh/sessions/` | 对话历史 |
| 日志 | `~/.dsh/logs/` | 运行日志 |

---

## 💡 迁移注意事项

### ✅ 必须迁移的文件 (按优先级)

| 优先级 | 文件 | 说明 | 可直接拷贝? |
|--------|------|------|------------|
| 🔴 P0 | `profiles/web/package.json` | **插件依赖清单 + bundles 列表** | ✅ 改用户名路径 |
| 🔴 P0 | `profiles/web/pnpm-lock.yaml` | **锁定精确版本号** | ✅ |
| 🔴 P0 | `profiles/web/cordis.patch.yml` | **Web 所有自定义覆盖** | ⚠️ 改 KimiCU 路径 |
| 🔴 P0 | `.credentials.yaml` | API 密钥 | ⚠️ 替换为自己的密钥 |
| 🟡 P1 | `.env` | EXA_API_KEY | ⚠️ 替换为自己的密钥 |
| 🟡 P1 | `settings.yaml` | 模型/UI/搜索设置 | ✅ |
| 🟡 P1 | `profiles/dsh-lark/cordis.patch.yml` | Lark 安全策略覆盖 | ✅ |
| 🟡 P1 | `profiles/dsh-lark-sdk/cordis.patch.yml` | Lark SDK 覆盖 | ✅ |
| 🟢 P2 | `skills/eli5/SKILL.md` | 自定义技能 | ✅ |
| 🟢 P2 | `.agent-presets/` | 梁神+锚定预设 | ✅ (liangshen 会由插件自动同步) |
| 🟢 P2 | `skins/` | 两套皮肤 | ✅ 或通过 Skin Center 重装 |
| 🟢 P2 | `skin-center-active.json` | 皮肤激活状态 | ✅ |
| 🟢 P2 | `dream-skin.json` | Dream Skin 选择 | ✅ |
| 🟢 P2 | `dsh-ssh.json` | SSH 主机列表 | ✅ (密码需重输) |
| ⚪ P3 | `plugins/qp-exa-dynamic/` | 自研插件源码 | ✅ 或用 npm 版 |
| ⚪ P3 | `pet.json` | 宠物状态 | ✅ (非必需) |

### ❌ 不需要迁移的 (会自动重建)

- `sessions/` — 对话历史 (除非你想保留)
- `cache/` — 缓存
- `profiles/*/node_modules/` — 依赖包 (pnpm install 重建)
- `logs/` — 日志
- `storages/` — 运行时存储
- `task-board/` — 任务看板数据
- `.anonymous-user-id` — 匿名 ID
- `remote-web-ui-devices.json` — 设备配对 (需重新扫码)
- `profiles/web/.dsh-market/` — 市场缓存

### ⚠️ 需要在新设备上重新操作的

1. **SSH 密码** — DSH 内部加密存储，不导出到配置文件
2. **Remote Web UI 设备配对** — 需要手机重新扫码绑定
3. **KimiCU 路径** — `cordis.patch.yml` 中硬编码了 `C:\Users\Windows11\...`，新电脑用户名不同时需修改
4. **Lark App ID/Secret** — 如果用同一个飞书应用可以复用，否则需新建
5. **首次启动后运行 `pnpm install`** — 在 `~/.dsh/profiles/web/` 目录下执行，安装所有插件依赖

### 🔑 最简迁移流程 (5步)

```
步骤1: 新电脑安装 DSH → dsh (首次启动创建 ~/.dsh)
步骤2: 拷贝上面 P0+P1 的文件到新电脑的 ~/.dsh/ (注意改路径和密钥)
步骤3: cd ~/.dsh/profiles/web && pnpm install
步骤4: 拷贝 P2 文件 (skills, skins, presets)
步骤5: dsh → 打开 http://127.0.0.1:3080 验证
```

### 👫 帮朋友安装时的建议

- 先使用默认的 approval `ask` 模式，熟悉后再切换到 `never`
- 根据朋友的实际需求裁剪插件（不必全装）
- API 密钥让朋友自己申请，不要共享你的
- 如果朋友不用飞书，跳过 Lark 相关 profile
- `qp-exa-dynamic` 建议用 npm 版而非本地 link
- 皮肤可以让朋友自己在 Skin Center 里挑选
- 安全策略的 `danger-full-access` 要解释清楚风险

---

*本文档由 DSH Agent 自动生成于 2026-09-18，基于对 `~/.dsh/` 目录的完整扫描。*

