# CHANGELOG v3 — 相对 v2 的修订说明

> 依据规则：【源码】= 对照过 DSH 源码（本机 `~/deepseek-harness` @ `0.1.3-alpha.1`, git `d347e70390`）；
> 【实测】= 本机命令验证；【npm】= registry 元数据核实；【未核实】= 无法在本机验证，需目标机确认。
> v2 原文保留在仓库根目录（`../DSH-Setup-Guide.md`），本目录是修订版。

## 一、必须改的（会误导 / 有安全影响）

| # | v2 写法 | 问题 | v3 写法 | 依据 |
|---|---|---|---|---|
| 1 | `sandbox-policy: mode: danger-full-access` + `approval: never` 作全局默认 | `never` 不是"免确认放行"，而是**自动拒绝**（CI/无人值守档）；两者叠加 = 无围栏 + 无闸门，且其他插件的审批请求也被静默吞掉 | 默认 `workspace-write`；围栏对准"工作台"目录；全权改为**按会话**临时切换 | 【源码】`interaction/user-approval/src/index.ts`（"every ask resolves `rejected`"）、`interaction/permission-presets/src/index.ts`（出厂 preset 表） |
| 2 | `sandbox-policy.workspaceRoot: !!js process.cwd()` | 真实会话的围栏是**会话自己的 cwd**；此配置只对"无 cwd 会话 / 无 agent 调用"生效，等于没设，还容易误以为已设围栏 | 删掉该项；改为**控制会话工作区**（这才是真正的射程开关） | 【源码】`sandbox/sandbox-policy/src/index.ts` → `resolve()`: `session?.header.cwd ?? this.workspaceRoot` |
| 3 | 插件清单同时列 `@linxin666/dsh-web-all` 和它自带的子包（`@linxin666/dsh-remote-web-ui`） | 聚合包与离散包**同装会版本打架**（实测：better-sidebar 0.18.0 vs web-all 带的 0.19.1；skill-explorer / remote-web-ui 0.3.16 vs 0.3.24） | 二选一：聚合路线只留 `dsh-web-all`；离散路线不装聚合包 | 【npm】`@linxin666/dsh-web-all@0.3.24` 依赖 20 个包，含 remote-web-ui / dsh-pet / skill-explorer / liangshen / dsh-ssh / describe-image / doctor |
| 4 | "你手动启用了 SSH / Describe Image / LiangShen / Skill Explorer / Doctor" | 这 5 个是 `dsh-web-all` 的**依赖项**，随聚合包自动进来，不是"手动启用" | 改为"随聚合包带入，启停写在 patch 层" | 【npm】同上 |
| 5 | 技能目录写作 `~/.dsh/skills/`（并说"整体拷贝即可"） | 技能实际有 **4 个发现根**；本机用户真正的技能在 `~/.agents/skills`，而它是一个 **git 仓库** → 迁移应该 `git clone` 而不是拷目录 | 给出 4 个根 + 优先级表；迁移改用 git | 【源码】`skill/skill-filesystem/src/index.ts` L246–254 |
| 6 | `link:C:/Users/Windows11/.dsh/plugins/qp-exa-dynamic`、`C:\Users\<用户名>\...` 混写 | 把真实 Windows 用户名写进了公开仓库；路径不参数化 | 全文统一 `<用户名>`，并附替换脚本 | 【实测】仓库公开可下载 |
| 7 | "§5 精确依赖列表"当作安装依据 | 那份快照已过期（如 chat-import v2 写 `^0.11.2`，npm 现为 `0.19.3`） | 版本以 `pnpm-lock.yaml` 为唯一事实源；文档只讲"怎么复现锁定态" | 【npm】 |
| 8 | 未提 `dsh plugin` 的真实行为 | 它是 **pnpm 转发器**，且会按安装态**自动重建 `dsh.profile.bundles`** → 手改 bundles 常是多余的 | 明确它转发 pnpm + 自动 reconcile | 【源码】`apps/cli/src/plugin.ts` 头注释 |

## 二、建议补的（v2 缺，v3 新增）

- **§手机/飞书场景**：审批为何在异步通道上体验差、`/permission` 会话级开关、为什么"围栏对准工作台"能同时拿到 0 次审批和内核围栏。
- **§平台差异**：Windows 的写限制后端是**受限令牌 + ACL**，Linux 是 **bwrap + Landlock**，两者不等价，别互相推断。
- **§故障排查**：`dsh --version` 之类启动即失败的定位顺序。
- **依据分级**：v2 通篇是断言但没有依据标注（与用户自己的 AGENTS.md 铁律 4 不一致）。

## 三、复核过、确认 v2 是对的（未改）

- `.credentials.yaml` 为明文、不要提交 Git —— 正确。
- `DSH_HOME/.env` 与 `<cwd>/.env` 两层，且 `.env` 不随仓库走 —— 正确（【源码】`boot/app-boot`）。
- `USER_PRESET_DIR = .agent-presets` 挂在 DSH home 下 → `~/.dsh/.agent-presets/` —— 正确（【源码】`preset/agent-presets/src/discovery.ts` L51 + `index.ts` L181）。
- P0/P1/P2/P3 迁移优先级表、"不需要迁移"清单 —— 思路正确，v3 只做小幅勘误。
- 建议帮朋友安装时先用 `ask` —— 正确，v3 进一步说明 `ask`/`never` 的真实语义。

---

## 四、v3.1 补充核实（全部来自源码，非推测）

写 v3 时有 5 条标了【未核实】。其中 5 条里有 3 条可以靠读源码定论，已回填并顺带发现两处 v2 的错误：

| 项 | 结论 | 依据 |
|---|---|---|
| `dsh web` 前台/daemon | **前台常驻**（`runProfile` 被 `await`）→ systemd `Type=simple` 正确 | 【源码】`apps/cli/src/bin.ts` |
| `dsh web` 参数名 | `--host <host>` / `--port <port>` / `--no-open` / `--trusted-host <authority...>`；由 **web app** 解析（launcher 只做透传） | 【源码】`bundle/web-app/src/startup.ts` |
| **v2 错**：`host: '0.0.0.0'` | CLI **明文拒绝**该值，理由原文是"would expose remote code execution to the network"。绑 LAN 必须改配置层，等于绕过上游刻意设的闸门 | 【源码】同上 |
| **v2 错**：`dsh stop` | **不存在该命令**。停止 = Ctrl+C / `systemctl --user stop` / 结束进程 | 【源码】`apps/cli/src/args.ts` |
| `/api` 的信任模型 | browser-trust 围栏只认 loopback、绑 LAN 时自动推导的 LAN IP 字面量、`--trusted-host` 声明项；上游注释明确 **"this fence is not an auth layer"**。走隧道/域名访问需要 `--trusted-host` | 【源码】`client/connection/src/api-request-trust.ts`、`bundle/web-app/src/index.ts` |

**顺带补进文档的实务要点**

- systemd unit 必须加 `--no-open`（无浏览器可开）
- `--port 0` 可让 OS 分配空闲端口
- `webserver.host` 的类型是闭合联合 `'127.0.0.1' | '0.0.0.0'`，不存在"绑某个网卡"的写法

**仍未核实（保留）**：飞书是否暴露 `/permission` · Windows ACL 沙箱实际效果 · patch 是否展开 `$env:` 变量。

---

## 五、v3.2 按用户修订意见改 AGENTS.md（两份同步）

用户提出的两条意见，两份全局指令同步执行：

| 改动 | 为什么 |
|---|---|
| **删除「工作范围」与「工具与工作流偏好」两节** | 这两节写的是 agent 自己能读到的东西（工作区范围、可用工具/技能清单）。写进指令文件只会**重复**、并随着工具增减**变旧** |
| **新增铁律 2「角色=分析、编排、验证」** | 明确分工：自己只做**需求澄清 → 方案拆解 → 任务分发 → 结果验收**；**实现类工作（读大量代码、写代码、跑测试、批量修改、大范围检索）一律派给 subagent**。给了"必须派"的清单和"要不要派"的判据，并强调当前会话没有 subagent 工具时要**如实说明**，不要假装派过 |
| **强化铁律 4「未明确要求前禁止全库递归读取」** | 用户点的重点。从原来的一句话扩成硬要求：禁止 `find ~ -type f` / `grep -r /` / `Get-ChildItem -Recurse C:\`；改用 `ls`/`du -sh *`/`git ls-files` 先摸边界；并写明理由（慢 + 把无关内容灌进上下文、挤掉有效信息） |
| **语言规则统一** | 由草稿的"默认中文回复"改为"对话中文 + 交付物英文"（Windows 版同步） |
| **交付前自检新增两项** | ①实现类工作是否已派给 subagent ②是否在全库递归读取上偷懒 |

产物：`AGENTS.global.fedora.md`（110 行）、`AGENTS.global.windows.md`（120 行，基于仓库根草稿改）。
仓库根 `AGENTS.md` 仍保留为旧草稿，未改动。

---

## 六、v3.3 根 `AGENTS.md` 替换为修订版

原根 `AGENTS.md` 是自述"尚未启用"的旧草稿（Windows/合成生物学那版，含 KimiCU、PowerShell 工具表）。

处置：

- **根 `AGENTS.md` ← v3.2 的 Windows 修订版**（同步了删工具表、加派活铁律、强化禁止全库递归读取、语言规则）
- **删除 `v3/AGENTS.global.windows.md`** —— 内容已提升到根目录，同内容保留两处必然漂移；根目录成为 Windows 版的**唯一落点**
- Fedora 版仍留在 `v3/AGENTS.global.fedora.md`
- 根 `README.md` 已更新：`AGENTS.md` 标注为"Windows 工作机版"并指向 Fedora 版；补了 `v3/` 一行与 v2 手册的修订提示

旧草稿仍可从 git 历史取回：

```bash
git show 012c03f:AGENTS.md
```
