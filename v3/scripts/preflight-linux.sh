#!/usr/bin/env bash
# DSH Linux 自检 —— 只读，不修改任何文件；不打印任何密钥值（只打印 key 名）
# 用法: bash preflight-linux.sh        # PREFLIGHT_STRICT=1 时把"已接受风险"也计为失败
set -uo pipefail

ok(){ printf '  \033[32m✅\033[0m %s\n' "$1"; }
bad(){ printf '  \033[31m✗\033[0m %s\n' "$1"; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$1"; }
hdr(){ printf '\n\033[1m%s\033[0m\n' "$1"; }

DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
AGENTS_HOME="${DSH_AGENTS_HOME:-$HOME/.agents}"
SRC="${DSH_SRC:-$HOME/deepseek-harness}"
FAIL=0

hdr "1. 运行时"
node -v >/dev/null 2>&1 && ok "node $(node -v)" || { bad "node 不可用"; FAIL=1; }
NV=$(node -v 2>/dev/null | sed 's/^v//' | cut -d. -f1)
[ "${NV:-0}" -ge 18 ] && ok "node 主版本 >= 18" || warn "node 主版本 ${NV:-?} < 18"

hdr "2. DSH 安装形态"
SHIM="$HOME/.local/bin/dsh"
if [ -f "$SHIM" ]; then
  ok "shim: $SHIM"
  sed -n '2p' "$SHIM" | sed 's/^/    → /'
  grep -q "pnpm" "$SHIM" && warn "源码树形态：加插件前确认 profile 依赖锚点" || true
else
  command -v dsh >/dev/null 2>&1 && ok "dsh 在 PATH: $(command -v dsh)" || { bad "找不到 dsh"; FAIL=1; }
fi
if [ -f "$SRC/package.json" ]; then
  V=$(node -e "try{console.log(require('$SRC/package.json').version)}catch(e){console.log('?')}" 2>/dev/null)
  ok "源码树 $SRC @ $V"
  git -C "$SRC" log -1 --format='    → %h %ad %s' --date=short 2>/dev/null || true
else
  warn "未发现源码树 $SRC"
fi

hdr "3. Profiles 与 patch"
if [ -d "$DSH_HOME/profiles" ]; then
  for p in "$DSH_HOME"/profiles/*/; do
    name=$(basename "$p")
    [ "$name" = node_modules ] && continue
    cnt=$(node -e "try{const d=require('$p/package.json');console.log((d.dsh&&d.dsh.profile&&d.dsh.profile.bundles||[]).length)}catch(e){console.log('?')}" 2>/dev/null)
    ok "profile '$name'（bundles: $cnt）"
  done
else
  bad "无 $DSH_HOME/profiles"; FAIL=1
fi
PATCH="$DSH_HOME/profiles/web/cordis.patch.yml"
if [ -f "$PATCH" ]; then
  n=$(grep -cE '^\s*-\s*id:' "$PATCH" 2>/dev/null || echo 0)
  ok "web patch 有 $n 条覆盖"
  if grep -qE 'danger-full-access' "$PATCH"; then warn "patch 里出现 danger-full-access（先确认是否必要）"; fi
  if grep -qE '^\s*approval:\s*never' "$PATCH"; then warn "patch 里出现 approval: never（=自动拒绝，非放行）"; fi
  if grep -qE 'C:\\\\Users|/home/[a-z]+/' "$PATCH"; then warn "patch 里可能有硬编码绝对路径/用户名"; fi
else
  warn "无 $PATCH"
fi

hdr "4. 凭证（只列 key 名，不打印值）"
CRED="$DSH_HOME/.credentials.yaml"
if [ -f "$CRED" ]; then
  keys=$(grep -oE '^\s+[A-Z0-9_]+:' "$CRED" | tr -d ' :' | paste -sd, -)
  [ -n "$keys" ] && ok "credentials 含: $keys" || bad "credentials 里没解析到 key"
  for need in DEEPSEEK_API_KEY QWEN_TOKEN_PLAN_CN_API_KEY DASHSCOPE_API_KEY; do
    grep -q "^\s*$need:" "$CRED" 2>/dev/null || warn "缺少 $need（用到对应 provider 时会失败）"
  done
else
  bad "无 $CRED"; FAIL=1
fi
for e in "$DSH_HOME/.env" "./.env"; do
  [ -f "$e" ] && ok "存在环境文件 $e（含: $(grep -oE '^[A-Z0-9_]+=' "$e" | tr -d '=' | paste -sd, -)）"
done
[ -f "$DSH_HOME/.env" ] || warn "无 $DSH_HOME/.env（EXA_API_KEY 等需要它）"

hdr "5. 权限默认"
grep -qE '^permission:' "$DSH_HOME/settings.yaml" 2>/dev/null \
  && ok "settings.yaml 设置了 permission 段" \
  || warn "未设置 → 走出厂默认 workspace-write + ask（一般即可）"

hdr "6. Linux 沙箱后端"
command -v bwrap >/dev/null 2>&1 && ok "bwrap: $(command -v bwrap)" || { bad "缺 bwrap → workspace-write 无法内核级强制"; FAIL=1; }
if [ -r /sys/kernel/security/lsm ]; then
  grep -q landlock /sys/kernel/security/lsm && ok "landlock 在 LSM 列表" || warn "LSM 里没有 landlock"
else
  warn "读不到 /sys/kernel/security/lsm（无权限或非 Linux）"
fi
ok "kernel $(uname -r)"

hdr "7. 指令 / 技能 / 预设"
[ -f "$DSH_HOME/AGENTS.md" ] && ok "全局指令 $DSH_HOME/AGENTS.md" \
  || warn "无 $DSH_HOME/AGENTS.md（注意：~/AGENTS.md 不保证被读到）"
for root in "$DSH_HOME/skills" "$AGENTS_HOME/skills"; do
  if [ -d "$root" ]; then
    n=$(find "$root" -maxdepth 1 -mindepth 1 -not -name '.*' | wc -l)
    ok "技能根 $root（$n 项）"
  else
    warn "无技能根 $root"
  fi
done
[ -d "$AGENTS_HOME/skills/.git" ] && ok "$AGENTS_HOME/skills 是 git 仓库（可用 clone 迁移）"
[ -d "$DSH_HOME/.agent-presets" ] && ok "自定义预设 $DSH_HOME/.agent-presets" || warn "无自定义预设（非必需）"

hdr "8. 凭据泄漏扫描（URL 内嵌 token / 仓库内落凭据）"
# 已知接受风险：~/.agents/skills 的 remote URL 内嵌 PAT（用户 2026-09-23 决定暂不吊销）。
# 默认降级为提示，避免每次自检都红；PREFLIGHT_STRICT=1 可恢复为失败。
ACCEPTED=".agents/skills"
STRICT="${PREFLIGHT_STRICT:-0}"
hits=0
while IFS= read -r cfg; do
  repo="${cfg%/config}"
  if grep -qE 'https://[^/@]*:[^/@]*@|https://(ghp_|github_pat_|gho_|glpat_)[A-Za-z0-9_-]+@' "$cfg" 2>/dev/null; then
    if [[ "$repo" == *"$ACCEPTED"* ]]; then
      warn "git remote URL 内嵌凭据: $repo  【已知接受风险，暂不吊销】"
      warn "  不吊销的话，建议至少做一次: git -C ~/.agents/skills remote set-url origin git@github.com:<owner>/<repo>.git"
      warn "  （这样 token 就不再随目录拷贝/克隆一起外流）"
      [ "$STRICT" = "1" ] && hits=$((hits+1))
    else
      bad "git remote URL 内嵌凭据: $repo  （新发现，建议吊销 token 并改用 SSH）"
      hits=$((hits+1))
    fi
  fi
done < <(find "$HOME" -maxdepth 6 -name config -path '*/.git/*' 2>/dev/null)
if [ "$hits" -eq 0 ]; then
  ok "无新增内嵌凭据问题（已接受项见上）"
else
  FAIL=1
fi
for f in "$DSH_HOME/.credentials.yaml" "$DSH_HOME/.env"; do
  [ -f "$f" ] && { d=$(dirname "$f"); [ -d "$d/.git" ] && bad "$f 位于 git 仓库内"; }
done
if command -v git >/dev/null && git -C "$HOME" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  warn "home 目录本身是 git 仓库：确认 .credentials.yaml / .env 已被忽略"
fi

hdr "结果"
if [ "$FAIL" -eq 0 ]; then printf '  \033[32m全部关键项通过\033[0m\n'; else printf '  \033[31m有 %d 项关键检查失败（见上）\033[0m\n' "$FAIL"; fi
exit "$FAIL"
