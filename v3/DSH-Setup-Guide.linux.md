# DSH 部署与日常使用手册 · Fedora / Linux 版

> **基线**：本机实测 —— Fedora 44 (KDE Plasma / Wayland) · 内核 `7.1.3-201.fc44` · Node `v22.23.1`
> **DSH 形态**：**源码树 + pnpm**（不是 `npm -g`），源码在 `~/deepseek-harness`，版本 `@deepseek-ai/dsh-root 0.1.3-alpha.1`（git `d347e70390`，2026-09-04）
> **依据分级**：【实测】= 本机命令验证；【源码】= 对照 `~/deepseek-harness` 源码；【未核实】= 需你自己确认
> **姊妹文档**：[Windows 版](./DSH-Setup-Guide.windows.md) · 修订说明 [CHANGELOG-v3](./CHANGELOG-v3.md)

---

## 1. 环境基线（先跑一遍，10 秒）

```bash
node -v                                  # v22.23.1
cat ~/.local/bin/dsh                     # 确认安装形态
python3 -c "import json;print(json.load(open('$HOME/deepseek-harness/package.json'))['version'])"
bwrap --version                          # Linux 沙箱后端
cat /sys/kernel/security/lsm             # 应含 landlock
```

**本机实测结论**：

| 项 | 值 | 意义 |
|---|---|---|
| DSH 启动方式 | `~/.local/bin/dsh` → `pnpm --prefix ~/deepseek-harness dsh "$@"` | **源码树形态**，不是全局 npm 包 |
| 源码版本 | `0.1.3-alpha.1` | 比 Windows 那台（`0.1.5-rc.1`）旧 2 版 |
| 沙箱后端 | `/usr/bin/bwrap` 已装 + `landlock` 在 LSM 列表 | **内核级围栏可用** |
| profiles | 只有 `web` | 没有 `dsh-lark`，手机/飞书那套在这台机器上还没搭 |
| 凭证 | `~/.dsh/.credentials.yaml` 只有 `DEEPSEEK_API_KEY` | 只够跑 DeepSeek |
| `.env` | **不存在** | 没有 `EXA_API_KEY` 等 |

---

## 2. 安装形态：源码树怎么用

### 2.1 为什么是源码树

```bash
$ cat ~/.local/bin/dsh
#!/bin/bash
exec pnpm --prefix ~/deepseek-harness dsh "$@"
```

`~/deepseek-harness` 是 `deepseek-ai/deepseek-harness` 的 clone（release 分支 `dsh-0.1.3-alpha.1`）。
**好处**：能读源码（本文档所有【源码】结论都来自这里）、能改、能跟着上游分支走。
**代价**：`dsh plugin` 的依赖解析锚点和全局装不同；升级要自己 `git pull` + `pnpm install`。

### 2.2 加插件 / 改插件

【源码】`apps/cli/src/plugin.ts`：`dsh plugin --profile <name> <pnpm 参数...>` 就是**在 profile 目录里转发 pnpm**，装完按安装态**自动重建** `dsh.profile.bundles`。

```bash
# 加插件（会自动进 bundles，不用手改）
dsh plugin --profile web add <package>@<version>
dsh plugin --profile web remove <package>
dsh plugin --profile web why <package>
dsh plugin --profile web update

# 等价于
cd ~/.dsh/profiles/web && pnpm add <package> && pnpm install
```

> ⚠️ **别手改 `bundles`**：它由安装态 reconcile。手改只在固定顺序或打 patch 时才碰。

### 2.3 升级源码树

```bash
cd ~/deepseek-harness
git fetch --tags && git status          # 先看当前在哪个分支
# ⚠️ 你现在在 release/dsh-0.1.3-alpha.1 上；换版本是"换分支"，不是 pull
git checkout <目标 release 分支>
pnpm install
```

> 🔴 **升级前先读 `~/.dsh/profiles/web/cordis.patch.yml`**：里面已经有一条"因版本不兼容先禁用 `agent-teams`"。**升级要连带处理这批被隔离的插件**——升完把 `disabled` 逐条撤掉试，别一起放开。

### 2.4 只启动 Web GUI

```bash
dsh web            # 【未核实】前台启动，Ctrl+C 退出
# 浏览器 http://127.0.0.1:3080
```

---

## 3. 目录速查（这台机器的真实情况）

| 用途 | 路径 | 本机状态 |
|---|---|---|
| DSH Home | `~/.dsh`（可由 `DSH_HOME` 覆盖）【源码】 | 存在 |
| 核心设置 | `~/.dsh/settings.yaml`【源码】 | 存在 |
| 凭证 | `~/.dsh/.credentials.yaml`（**明文**）【源码】 | 仅 `DEEPSEEK_API_KEY` |
| 环境变量 | `~/.dsh/.env` 或 `<cwd>/.env`【源码】 | **都没有** |
| Web profile | `~/.dsh/profiles/web/{package.json,pnpm-lock.yaml,cordis.patch.yml}` | 存在 |
| 全局指令 | `~/.dsh/AGENTS.md`【源码】 | **不存在**（你的是 `~/AGENTS.md`，不保证被读到，见 §3.1） |
| **技能** | `~/.agents/skills/`（+`~/.dsh/skills/`+2 个项目级）【源码】 | `~/.agents/skills` 有 21 项，**是个 git 仓库** |
| Agent Presets | `~/.dsh/.agent-presets/`【源码】 | 不存在 |
| 插件源码 | `~/.dsh/plugins/` | 不存在 |
| 会话 / 日志 | `~/.dsh/sessions/`、`~/.dsh/logs/` | 存在 |
| 源码树 | `~/deepseek-harness/` | 存在 |

### 3.1 全局指令放哪最可靠

【源码】`context/agent-instructions`：用户全局指令是**固定的 `~/.dsh/AGENTS.md`**；项目级是 `AGENTS.md` / `CLAUDE.md`，**从项目根往下到 cwd** 逐层发现。

⇒ 你现在写在 `~/AGENTS.md`（home 根）。它**只有在 `~` 被解析成项目根（或其祖先）时才被读到**，取决于 cwd。**要稳定生效，请把全局规则放 `~/.dsh/AGENTS.md`。**
👉 建议：`~/AGENTS.md` 里的通用部分（用户背景、语言偏好、铁律）搬一份到 `~/.dsh/AGENTS.md`，`~/AGENTS.md` 留作"在 home 下干活时"的补充。

### 3.2 技能有 4 个发现根

【源码】`skill/skill-filesystem/src/index.ts`：

`<项目根>/.dsh/skills` · `<项目根>/.agents/skills` · `~/.dsh/skills` · **`$DSH_AGENTS_HOME` 或 `~/.agents/skills`**

`~/.agents` 是**跨工具共享**的技能根。你的技能（`eli5`、`deep-research`、`literature-search`、`pubmed-database`、`baoyu-*`、`docx`、`exhibition-notes` …）都在那儿，且由 `Geighlord007/Agent-skills_QP` 管版本。

💡 **换机器/重装只要**：

```bash
git clone <你的 skills 仓库> ~/.agents/skills     # 别拷目录，用 git
```

---

## 4. 权限与沙箱（Linux 版）

### 4.1 三个必须先搞清的概念

1. **`approval` 只有 `ask` / `never`，而 `never` = 自动拒绝**（不是免确认放行）。
   【源码】`interaction/user-approval/src/index.ts`："every ask resolves `rejected` deterministically"（CI/无人值守档），且在应答者链**之前**生效。
2. **审批只在"越界"后触发**：内核拒绝 → agent 看到 `[sandbox: file access denied under workspace-write mode]` → 带 `justification` 重试 → **这才弹审批**，且**一次性**（`allowed-once`）。
   ⇒ **在工作区里编辑文件本来就不需要审批。**
3. **围栏 = 会话工作区（会话 cwd）**，不是 patch 里的 `workspaceRoot`。
   【源码】`sandbox/sandbox-policy/src/index.ts`：`session?.header.cwd ?? this.workspaceRoot`。
   【源码】`sandbox/sandbox/src/roots.ts`：`workspace-write` 可写 = **会话工作区 + `/tmp` + `os.tmpdir()`**。

**出厂 preset 表**（【源码】`interaction/permission-presets`）：

| preset | sandbox | approval |
|---|---|---|
| `workspace-write` | workspace-write | **ask** |
| `danger-full-access` | danger-full-access | **never** |

> 🚨 **危险组合**：`workspace-write` + `never` → 越界操作会"拒绝→尝试升权→直接判 rejected"。**你收不到提示，但 agent 会告诉你"用户拒绝了这个操作"**。

### 4.2 在 Linux 上验证围栏真的生效

```bash
# 后端可用性
bwrap --version && cat /sys/kernel/security/lsm | tr ',' '\n' | grep landlock
```

一次会话里做两个测试（【源码】语义）：

- 在工作区写一个文件 → **应成功、无任何提示**
- 在工作区外（例：`~/.bashrc` 或 `/etc/hosts`）写 → **应看到** `[sandbox: file access denied under workspace-write mode]` **并触发一次升权询问**

**这两个测试就是判据**——过了说明围栏是活的；第二个测试"什么都没发生就成功了"说明围栏没生效，要马上排查。

### 4.3 本机当前策略

`~/.dsh/profiles/web/cordis.patch.yml` **只做了 `agent-teams` 隔离**，没有 permission/sandbox 覆盖；`settings.yaml` 也没有 `permission` 段。
⇒ **你现在走的就是出厂默认 `workspace-write + ask`**，配置是干净的。**别急着改它。**

### 4.4 手机/远程场景建议（等你要搭的时候）

- 手机那套（`dsh-lark`）在这台机器上**还没装**；真要搭，**从第一天就用围栏**：把 `DSH_LARK_WORKSPACE` 指向一个专门的"工作台"目录（例：`~/工作台/`），把手机要碰的东西都收进去 → 常规编辑/传输 **0 次审批**，射程锁在一个目录里。
- 越界需求用**一条命令**：`/permission`（`permission-presets` 自带）切**当前会话**的 preset，落成 `permission/preset` + `sandbox/mode` + `approval/policy` 事件，durable、可 replay、不影响其它会话。
- **不要**把 `never` 设成默认：它会把**其它插件**的审批请求一起静默吞掉。
- 想要"临时全权"就加一档 `full-access-ask`（`danger-full-access` + `ask`），而不是全局 `never`。

### 4.5 Linux 是内核级围栏

`sandbox-local` 在 Linux 上走 **bwrap + Landlock**（【源码】`sandbox/sandbox-local/src/profiles.ts`）。本机 `bwrap` 已装、`landlock` 在 LSM 里。
⇒ 即使 agent 被注入并跑了任意 bash，**物理上也写不出围栏**。这是"保留围栏"最有力的理由：**你损失的性能和便利几乎为零，换来的是内核级兜底**。（Windows 那边是受限令牌 + ACL，**不等价**，别互相推断。）

---

## 5. Windows → Linux 迁移对照

| Windows | Linux（本机） |
|---|---|
| `npm install -g @deepseek-ai/dsh` | `git clone` + `pnpm install`（源码树） |
| `D:\CSsoftware\npm-global` | `~/.local/bin`、`~/.local/share/pnpm` |
| `C:\Users\<用户名>\.dsh` | `~/.dsh` |
| `%USERPROFILE%\AppData\Local\...` | `~/.local/share/...` |
| `$env:USERPROFILE\.dsh\plugins\` | `~/.dsh/plugins/` |
| PowerShell `$env:X` | `export X=` / `~/.bashrc` |
| `Copy-Item -Recurse` | `cp -r` |
| systemd 服务 → **用 systemd user unit**（见 §6.2） |
| KimiCU（`kimi-cu.exe`） | ❌ **不可迁移**（Windows 专用可执行） |
| 受限令牌 + ACL 沙箱 | ✅ **升级为** bwrap + Landlock |
| `dsh-ssh.json` 密码 | 需重输 |
| Remote Web UI 配对 | 需重新扫码 |

**可迁移**：`settings.yaml`、`profiles/*/{package.json,pnpm-lock.yaml,cordis.patch.yml}`、`.credentials.yaml`（换成自己的 key）、`.env`、`~/.agents/skills`（用 git clone）、`.agent-presets/`、`AGENTS.md`（放 `~/.dsh/AGENTS.md`）

**要重做**：`pnpm install`、脚本里的路径、KimiCU、Lark 凭证

> ⚠️ **版本代差**：Windows 那套是给 `0.1.5-rc.1` 的，这台是 `0.1.3-alpha.1`。插件按新版写、DSH 是旧版 → 会重演 `agent-teams` 那种加载失败。
> 所以**要么**先把源码树升到 `0.1.5-rc.1`（连带处理被隔离的插件），**要么**只挑不依赖新版的插件装。

---

## 6. 让 DSH 更顺手（Linux 专项）

### 6.1 别让 `~/.dsh` 进 git

```bash
cat >> ~/.dsh/.gitignore <<'TXT'
.credentials.yaml
.env
sessions/
logs/
cache/
storages/
*devices*.json
TXT
```

### 6.2 用 systemd user unit 常驻（比 autostart 桌面项干净）

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/dsh.service <<'UNIT'
[Unit]
Description=DeepSeek Harness (web)
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/Deepseek
ExecStart=%h/.local/bin/dsh web
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
UNIT
systemctl --user daemon-reload
systemctl --user enable --now dsh.service
journalctl --user -u dsh -f          # 看日志
```

> 【未核实】`dsh web` 是否前台常驻；若它自己 daemon 化，把 `Type=simple` 改 `Type=forking` 或去掉 `Restart`。
> `WorkingDirectory` 很重要：它会成为**无 cwd 会话的兜底工作区**（【源码】`sandbox-policy`），直接影响围栏边界。
> 你想开机就跑（未登录也跑）：`sudo loginctl enable-linger $USER`

### 6.3 手机访问（本机没有 lark profile，走 Web GUI）

```bash
# 1) 只绑本机（默认，最安全）
dsh web --host 127.0.0.1 --port 3080        # 【未核实】参数名

# 2) 要局域网访问 → 绑 0.0.0.0 并放行 firewalld
sudo firewall-cmd --add-port=3080/tcp --permanent && sudo firewall-cmd --reload
ip -4 addr show scope global | grep inet     # 查本机 LAN IP
```

- 🔴 绑 `0.0.0.0` = **同网段任何人都能连**。DSH 的权限默认是 `workspace-write`，但**会话工作区里的内容仍可被读写**。只在可信网络下这么做，用完 `firewall-cmd --remove-port=3080/tcp --permanent`。
- 更稳的路线：只绑 `127.0.0.1`，用 SSH 隧道从手机/别的机器进：
  ```bash
  ssh -L 3080:127.0.0.1:3080 adam@<本机IP>   # 在手机端支持的客户端里做
  ```

### 6.4 会话工作区约定（决定围栏边界）

给不同用途固定几个工作根，**每次开会话选对目录**：

| 用途 | 建议工作根 |
|---|---|
| 文档 / 表格 / 翻译 | `~/文档` 或 `~/Deepseek` |
| 代码 | 各项目仓库目录 |
| 手机远程要碰的东西 | 统一收进一个"工作台"目录 |

**把要碰的东西收进同一个根**，就是"少弹审批"的正解——比拆围栏有效得多。

### 6.5 中文输入 / 桌面集成（本机已有）

你已装 Fcitx5 + vinput（`~/Deepseek/vinput-setup`）。DSH 是 Web GUI，输入法走浏览器/WebKit 那条路，无需额外配置。
Wayland 下如果要截图/剪贴板联动，用 KDE 自带的 Spectacle / Klipper 即可；agent 侧不要依赖 X11 专用的截图工具。

---

## 7. 安全基线（请逐条过）

### 7.1 已知接受风险：技能仓库 remote URL 内嵌 GitHub PAT

**状态**：⚠️ **已知并接受的风险**（用户 2026-09-23 决定暂不吊销）。记录在此以免后来者以为是疏漏。

**事实**：`~/.agents/skills/.git/config` 的 `remote.origin.url` 把 Personal Access Token 明文写在 URL 里（形如 `https://<TOKEN>@github.com/<owner>/<repo>.git`）。全盘扫描（`~` 下所有 `.git/config`）**仅此一处**。

**为什么值得记一笔**：

- 任何能读你 home 的进程都能直接拿到它 —— **包括一个 `danger-full-access` 的 agent**（这正是 §4 里"围栏在不在"的现实意义）
- 该文件不受 `.gitignore` 保护，且会随"拷 home / 拷 `.agents`"一路搬走
- `.git/config` 里的 URL 形式是**最差的存法**：它嵌在仓库目录内部，clone 不走它、但拷贝目录会带走它

**如果决定继续保留这个 token**，建议至少做下面任一项（**不需要吊销 token**）：

```bash
# 方案 A（推荐）：URL 改干净 + 凭据交给 credential helper 保管
cd ~/.agents/skills
git remote set-url origin https://github.com/<owner>/<repo>.git
# 凭据存到 ~/.git-credentials（chmod 600）或系统 keyring
git config --global credential.helper libsecret     # KDE/GNOME 有 keyring 时
git config --global credential.helper store         # 退路：明文但不在仓库目录内
git remote -v   # 确认 URL 里已无 token

# 方案 B：改走 SSH（本地不落任何 token）
git remote set-url origin git@github.com:<owner>/<repo>.git
```

核心收益：token 不再位于**会被整体拷贝的仓库目录**里，外流面小一圈。
自检脚本里该项已降级为提示（`PREFLIGHT_STRICT=1` 可恢复为失败）。

### 7.2 通用清单

- [ ] 凭证类文件一律不进任何 git 仓库：`~/.dsh/.credentials.yaml`、`~/.dsh/.env`
- [x] git remote 里不出现 `<token>@` —— **当前未达标**（§7.1 已接受风险，至少做掉 URL 清理）
- [ ] 顺手查一遍 URL 改写规则：`git config --global --get-regexp 'url\..*\.insteadof'`
- [ ] `~/.dsh/profiles/*/cordis.patch.yml` 里不硬编码用户名/绝对路径
- [ ] 不把 `danger-full-access` 当默认；临时提权用完就切回（`/permission`）
- [ ] 绑 `0.0.0.0` 前先想清楚同网段有谁；用完关端口

---

## 8. 自检脚本

见 [`scripts/preflight-linux.sh`](./scripts/preflight-linux.sh)：

```bash
bash ~/Deepseek/dsh-config-guide/v3/scripts/preflight-linux.sh
```

检查：Node 版本 · dsh 安装形态与版本 · profile/patch · 凭证里有哪些 key（**只打印名字**）· 沙箱后端 · 技能根 · git remote 是否内嵌 token · 权限默认。

---

## 9. 故障排查

| 症状 | 先查 | 处置 |
|---|---|---|
| `dsh --version` 报 `Read-only file system (os error 30)` | home 或临时目录是否可写 | DSH 启动要建临时包管理器目录；`touch ~/.dsh/x` 测可写性 |
| 启动即失败、缺组件 | 插件 vs DSH 版本代差 | patch 里先 `disabled: true` 隔离，再决定升谁 |
| 模型报错 | `agent-default-model` 的 provider 对应 key 是否存在 | 看 `llm-*-ai.providers.*.apiKeyEnv` 映射 |
| 越界操作"莫名失败" | 是否 `workspace-write` + `never` | 见 §4.1 危险组合 |
| 同功能出现两个组件 | 聚合包 + 离散包混装 | 二选一 |
| `~/.dsh/.env` 不生效 | 是否写了 `PATH`/`NODE_OPTIONS` 等启动期变量 | 会被拒；改用 `export` |
| 技能不出现 | 放错根 | 放 `~/.agents/skills/`（§3.2） |
| 全局规则不生效 | 放成了 `~/AGENTS.md` | 移到 `~/.dsh/AGENTS.md`（§3.1） |

---

## 10. 附：本机现状快照（便于日后 diff）

```
DSH 形态    源码树 ~/deepseek-harness @ 0.1.3-alpha.1
启动         ~/.local/bin/dsh → pnpm --prefix ~/deepseek-harness dsh
profiles     web（14 bundles）
默认模型     deepseek-official/deepseek-v4-flash（reasoningEffort: high）
预设         agent-presets.default = minimal
子代理       subagent-model-selection.allowedModels = deepseek-v4-flash
凭证         仅 DEEPSEEK_API_KEY
patch        仅禁用 agent-teams（版本不兼容）
权限         出厂默认 workspace-write + ask（无覆盖）
沙箱         bwrap + landlock（均可用）
技能         ~/.agents/skills（git 仓库，21 项）
缺失         ~/.dsh/AGENTS.md · ~/.dsh/.env · ~/.dsh/skills · .agent-presets · plugins · skins
```

---

*本手册基于本机实测 + 源码核查（DSH `0.1.3-alpha.1`）编写；未核实项已逐条标注。*
