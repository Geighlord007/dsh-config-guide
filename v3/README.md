# v3 文档包

相对仓库根目录 v2 原稿的修订版 + Linux 版新文档 + 全局指令合并版。

| 文件 | 说明 |
|---|---|
| [`DSH-Setup-Guide.windows.md`](./DSH-Setup-Guide.windows.md) | **v2 的修订版**（Windows）：权限/沙箱核心重写、插件清单纠错、路径参数化、依据分级 |
| [`DSH-Setup-Guide.linux.md`](./DSH-Setup-Guide.linux.md) | **新写**（Fedora/Linux）：源码树安装形态、bwrap+Landlock 围栏验证、Windows→Linux 迁移对照、systemd/防火墙/手机访问、安全基线 |
| [`AGENTS.global.fedora.md`](./AGENTS.global.fedora.md) | **全局指令（Fedora 版）**，目标位置 `~/.dsh/AGENTS.md` |
| — | Windows 版全局指令已提升到仓库根 [`AGENTS.md`](../AGENTS.md)（原草稿的修订版），避免同内容两处漂移 |
| [`CHANGELOG-v3.md`](./CHANGELOG-v3.md) | 改了哪 8 条、为什么、依据是什么 |
| [`scripts/preflight-linux.sh`](./scripts/preflight-linux.sh) | Linux 自检脚本（只读，不打印密钥值） |

## 快速开始

```bash
# 自检（PREFLIGHT_STRICT=1 时把"已接受风险"也计为失败）
bash ~/Deepseek/dsh-config-guide/v3/scripts/preflight-linux.sh

# 启用全局指令（唯一可靠位置）
cp ~/Deepseek/dsh-config-guide/v3/AGENTS.global.fedora.md ~/.dsh/AGENTS.md
```

## 核查基线

- DSH `0.1.3-alpha.1`，源码 `d347e70390`（本机 `~/deepseek-harness`）
- 依据分级：【源码】/【实测】/【npm】/【未核实】，逐条标注

## 已知接受风险

- `~/.agents/skills/.git/config` 的 remote URL 内嵌 PAT —— 用户 2026-09-23 决定**暂不吊销**。
  见 [Linux 手册 §7.1](./DSH-Setup-Guide.linux.md)。自检脚本该项为提示，不阻塞。
  已记录以免后来者误判为疏漏。

## ✅ v3.1 已用源码核实（从"待确认"转正）

| 项 | 结论 | 依据 |
|---|---|---|
| `dsh web` 前台还是 daemon | **前台常驻**（`runProfile` 被 `await`）→ systemd 用 `Type=simple` | 【源码】`apps/cli/src/bin.ts` |
| `dsh web` 的参数名 | `--host` / `--port` / `--no-open` / `--trusted-host`（由 **web app** 解析，非 launcher） | 【源码】`bundle/web-app/src/startup.ts` |
| 能否 `--host 0.0.0.0` | **CLI 明文拒绝**，理由：会向网络暴露远程代码执行 | 【源码】同上 |
| 有没有 `dsh stop` | **没有**（CLI 只有 `web` / `plugin`） | 【源码】`apps/cli/src/args.ts` |
| `/api` 围栏是什么 | browser-trust 围栏，防 DNS rebinding / 跨站，**不是鉴权层** | 【源码】`client/connection/src/api-request-trust.ts` |

## ⚠️ 仍需在对应机器确认（Linux 本机无法验证）

1. 飞书链路是否暴露 `/permission` 这类斜杠命令（需 Windows 那台的 `dsh-lark` profile）
2. Windows 上「受限令牌 + ACL」沙箱的实际拦截效果
3. patch 层是否展开 `$env:LOCALAPPDATA` 这类变量
