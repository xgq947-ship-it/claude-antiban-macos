#!/usr/bin/env bash
# 公共函数库,被其它脚本 source。仅 macOS。
set -uo pipefail

# ---- 颜色输出 ----
if [[ -t 1 ]]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'; C_BLU=$'\033[34m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
  C_RED=; C_GRN=; C_YEL=; C_BLU=; C_DIM=; C_RST=
fi

ok()    { printf '%s✅ %s%s\n' "$C_GRN" "$*" "$C_RST"; }
warn()  { printf '%s⚠️  %s%s\n' "$C_YEL" "$*" "$C_RST"; }
bad()   { printf '%s❌ %s%s\n' "$C_RED" "$*" "$C_RST"; }
info()  { printf '%sℹ️  %s%s\n' "$C_BLU" "$*" "$C_RST"; }
dim()   { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RST"; }
hdr()   { printf '\n%s==== %s ====%s\n' "$C_BLU" "$*" "$C_RST"; }

require_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    bad "本 skill 仅支持 macOS,当前系统: $(uname)"; exit 1
  fi
}

# Clash Verge mihomo 本地控制 socket(默认路径)
VERGE_SOCK="${VERGE_SOCK:-/tmp/verge/verge-mihomo.sock}"

# 通过 mihomo unix socket 读运行时配置;失败返回非 0
mihomo_config() {
  [[ -S "$VERGE_SOCK" ]] || return 1
  curl -s --max-time 3 --unix-socket "$VERGE_SOCK" http://localhost/configs 2>/dev/null
}
