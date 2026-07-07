#!/usr/bin/env bash
# 阶段 0:把本机所有「和 Claude 有关」的缓存/指纹/身份数据先备份到桌面,再彻底清理。
#
# 安全设计:
#   - 默认 DRY-RUN(预演),只列出会备份/删除什么,不动任何文件。
#   - 带 --yes 才真正执行:先整体复制到 ~/Desktop/claude-backup-<时间戳>/,再删除原件。
#   - 默认不碰 ~/.claude(Claude Code 自身配置/记忆)。要清用 --include-claude-code 单独开启。
#
# 用法:
#   bash 00_backup_and_clean.sh                       # 预演
#   bash 00_backup_and_clean.sh --yes                 # 真正执行(先备份后删)
#   bash 00_backup_and_clean.sh --yes --include-chrome-claude   # 连隔离 Chrome-Claude 一起清
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
require_macos

APPLY=0; INC_CC=0; INC_CHROME_CLAUDE=0
for a in "$@"; do
  case "$a" in
    --yes) APPLY=1 ;;
    --include-claude-code) INC_CC=1 ;;
    --include-chrome-claude) INC_CHROME_CLAUDE=1 ;;
    *) warn "未知参数: $a" ;;
  esac
done

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/Desktop/claude-backup-$TS"

hdr "阶段 0 · 备份并清理 Claude 相关数据"
if [[ $APPLY -eq 0 ]]; then
  warn "当前是【预演模式】,不会改动任何文件。确认无误后再加 --yes 执行。"
else
  info "备份目录: $BACKUP"
fi

# 检查 Claude 桌面端 / Chrome 是否在运行(占用文件会导致拷贝/删除不干净)
if pgrep -x "Claude" >/dev/null 2>&1; then
  warn "检测到 Claude 桌面端正在运行,请先完全退出(⌘Q)。"
fi
if pgrep -x "Google Chrome" >/dev/null 2>&1; then
  warn "检测到 Google Chrome 正在运行,清理浏览器站点数据前请先完全退出。"
fi

APPSUP="$HOME/Library/Application Support"

# 待处理目标清单。存在才处理。
targets=(
  # ---- Claude 桌面端 ----
  "$APPSUP/Claude"
  "$HOME/Library/Caches/com.anthropic.claude"
  "$HOME/Library/Caches/Claude"
  "$HOME/Library/Preferences/com.anthropic.claude.plist"
  "$HOME/Library/Saved Application State/com.anthropic.claude.savedState"
  "$HOME/Library/HTTPStorages/com.anthropic.claude"
  "$HOME/Library/HTTPStorages/com.anthropic.claude.binarycookies"
  "$HOME/Library/WebKit/com.anthropic.claude"
  "$HOME/Library/Logs/Claude"
)

# ---- 隔离的 Chrome-Claude(专给 Claude 用的独立 user-data-dir,清掉=全新指纹,需重新登录)----
if [[ $INC_CHROME_CLAUDE -eq 1 ]]; then
  targets+=( "$APPSUP/Google/Chrome-Claude" )
fi

# ---- Claude Code(默认跳过,会连记忆/项目一起删)----
if [[ $INC_CC -eq 1 ]]; then
  warn "已开启 --include-claude-code:会删除 ~/.claude(含 Claude Code 记忆/项目配置),请再三确认!"
  targets+=( "$HOME/.claude" )
fi

# 执行:存在的目标先备份后删
found=0
for t in "${targets[@]}"; do
  if [[ -e "$t" ]]; then
    found=1
    sz="$(du -sh "$t" 2>/dev/null | cut -f1)"
    if [[ $APPLY -eq 0 ]]; then
      printf '  会处理: %s  (%s)\n' "$t" "${sz:-?}"
    else
      rel="${t#$HOME/}"
      dest="$BACKUP/$rel"
      mkdir -p "$(dirname "$dest")"
      if cp -a "$t" "$dest" 2>/dev/null; then
        rm -rf "$t" && ok "已备份并清理: $t"
      else
        bad "备份失败,已跳过(未删除): $t"
      fi
    fi
  fi
done
[[ $found -eq 0 ]] && info "未发现上述 Claude 桌面端相关数据(可能未安装或已清理)。"

# ---- 默认 Chrome 里 claude.ai / anthropic 的站点数据(cookie / storage)----
# 这部分按站点精确清理较脆弱,交由参考文档 references/00-cleanup.md 手动处理。
hdr "浏览器站点数据(claude.ai / anthropic.com)"
CHROME_DEFAULT="$APPSUP/Google/Chrome"
if [[ -d "$CHROME_DEFAULT" ]]; then
  warn "默认 Chrome 里 claude.ai/anthropic 的 cookie 与站点存储需按站点清理,较脆弱。"
  info "请参照 references/00-cleanup.md 的「浏览器站点数据」小节手动清理(需先退出 Chrome)。"
else
  info "未发现默认 Chrome 目录。"
fi

echo
if [[ $APPLY -eq 0 ]]; then
  warn "以上为预演。确认后执行:  bash $(basename "$0") --yes"
else
  ok "清理完成。备份保存在: $BACKUP"
  info "确认一切正常、用一阵子后,该备份可自行删除。"
fi
