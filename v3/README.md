# v3 文档包

相对仓库根目录 v2 原稿的修订版 + Linux 版新文档 + 全局指令合并版。

| 文件 | 说明 |
|---|---|
| [`DSH-Setup-Guide.windows.md`](./DSH-Setup-Guide.windows.md) | **v2 的修订版**（Windows）：权限/沙箱核心重写、插件清单纠错、路径参数化、依据分级 |
| [`DSH-Setup-Guide.linux.md`](./DSH-Setup-Guide.linux.md) | **新写**（Fedora/Linux）：源码树安装形态、bwrap+Landlock 围栏验证、Windows→Linux 迁移对照、systemd/防火墙/手机访问、安全基线 |
| [`AGENTS.global.fedora.md`](./AGENTS.global.fedora.md) | **全局指令合并版**，目标位置 `~/.dsh/AGENTS.md`（唯一可靠的全局指令位置） |
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

## ⚠️ 待确认项（文档里已标【未核实】）

1. `dsh web` 的前台/后台行为（影响 systemd unit 的 `Type`）
2. `dsh web --host/--port` 的确切参数名
3. 飞书链路是否暴露 `/permission` 这类斜杠命令
4. Windows 上受限令牌 + ACL 沙箱的实际拦截效果
5. patch 层是否展开 `$env:LOCALAPPDATA` 这类变量
