#!/usr/bin/env bash
# 阶段 0:把本机所有「和 Claude 有关」的缓存/指纹/身份数据先备份到桌面,再彻底清理。
#
# 安全设计:
#   - 默认 DRY-RUN(预演),只列出会备份/删除什么,不动任何文件。
#   - 带 --yes 才真正执行:先整体复制到 ~/Desktop/claude-backup-<时间戳>/,再删除原件。
#   - 默认不碰 ~/.claude(Claude Code 自身配置/记忆)。要清用 --include-claude-code 单独开启。
#   - 浏览器站点数据与 Claude Code CLI 默认不动,分别用 --include-browser-sites / --include-cli 开启
#     (完整说明见 references/browser-residue.md)。
#
# 用法:
#   bash 00_backup_and_clean.sh                       # 预演
#   bash 00_backup_and_clean.sh --yes                 # 真正执行(先备份后删)
#   bash 00_backup_and_clean.sh --yes --include-chrome-claude   # 连隔离 Chrome-Claude 一起清
#   bash 00_backup_and_clean.sh --yes --include-browser-sites   # 清各浏览器 claude/anthropic cookie
#   bash 00_backup_and_clean.sh --yes --include-cli             # 卸载 Claude Code CLI 残留
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
require_macos

APPLY=0; INC_CC=0; INC_CHROME_CLAUDE=0; INC_BROWSER=0; INC_CLI=0
for a in "$@"; do
  case "$a" in
    --yes) APPLY=1 ;;
    --include-claude-code) INC_CC=1 ;;
    --include-chrome-claude) INC_CHROME_CLAUDE=1 ;;
    --include-browser-sites) INC_BROWSER=1 ;;
    --include-cli) INC_CLI=1 ;;
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

# 检查 Claude 桌面端 / Chrome / Safari 是否在运行(占用文件会导致拷贝/删除不干净)
if pgrep -x "Claude" >/dev/null 2>&1; then
  warn "检测到 Claude 桌面端正在运行,请先完全退出(⌘Q)。"
fi
if pgrep -x "Google Chrome" >/dev/null 2>&1; then
  warn "检测到 Google Chrome 正在运行,清理浏览器站点数据前请先完全退出。"
fi
if pgrep -x "Safari" >/dev/null 2>&1; then
  warn "检测到 Safari 正在运行,清理 Safari 站点数据前请先退出。"
fi

APPSUP="$HOME/Library/Application Support"
DARWIN_CACHE="$(getconf DARWIN_USER_CACHE_DIR 2>/dev/null || true)"

# ---- 目标清单(存在才处理)----
targets=(
  # Claude 桌面端
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

# 隔离的 Chrome-Claude(专给 Claude 用的独立 user-data-dir,清掉=全新指纹,需重新登录)
if [[ $INC_CHROME_CLAUDE -eq 1 ]]; then
  targets+=( "$APPSUP/Google/Chrome-Claude" )
fi

# Claude Code(默认跳过,会连记忆/项目一起删)
if [[ $INC_CC -eq 1 ]]; then
  warn "已开启 --include-claude-code:会删除 ~/.claude(含 Claude Code 记忆/项目配置),请再三确认!"
  targets+=( "$HOME/.claude" )
fi

# 系统小残留(默认一并处理)
sys_targets=()
while IFS= read -r -d '' f; do sys_targets+=( "$f" ); done < <(find "$APPSUP/CrashReporter" -maxdepth 1 -iname 'Claude_*.plist' -print0 2>/dev/null)
if [[ -n "$DARWIN_CACHE" ]]; then
  while IFS= read -r -d '' f; do sys_targets+=( "$f" ); done < <(find "$DARWIN_CACHE" -maxdepth 1 -iname 'com.anthropic.claudefordesktop*' -print0 2>/dev/null)
fi

FOUND_ANY=0
process_targets() {
  local t sz rel dest
  for t in "$@"; do
    if [[ -e "$t" ]]; then
      FOUND_ANY=1
      sz="$(du -sh "$t" 2>/dev/null | cut -f1)"
      if [[ $APPLY -eq 0 ]]; then
        printf '  会处理: %s  (%s)\n' "$t" "${sz:-?}"
      else
        rel="${t#$HOME/}"; rel="${rel#/}"
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
  return 0
}

process_targets ${targets[@]+"${targets[@]}"}
process_targets ${sys_targets[@]+"${sys_targets[@]}"}
[[ $FOUND_ANY -eq 0 ]] && info "未发现桌面端相关数据(可能未安装或已清理)。"

# ---- 浏览器站点数据(claude.ai / anthropic.com 的 cookie)----
hdr "浏览器站点数据(claude.ai / anthropic.com)"
if [[ $INC_BROWSER -eq 1 ]]; then
  COOKIE_DBS=()
  while IFS= read -r -d '' f; do COOKIE_DBS+=( "$f" ); done < <(find "$APPSUP" -maxdepth 6 -type f -name 'Cookies' -print0 2>/dev/null)
  info "发现 cookie 数据库 ${#COOKIE_DBS[@]} 个,逐一检查:"
  hits=0
  for db in ${COOKIE_DBS[@]+"${COOKIE_DBS[@]}"}; do
    n="$(sqlite3 "file:$db?mode=ro" "SELECT COUNT(*) FROM cookies WHERE host_key LIKE '%claude%' OR host_key LIKE '%anthropic%';" 2>/dev/null || echo 0)"
    if [[ "${n:-0}" != "0" ]]; then
      hits=$((hits+1))
      if [[ $APPLY -eq 0 ]]; then
        printf '  会清理 %s 条: %s\n' "$n" "$db"
      else
        mkdir -p "$BACKUP/cookies-backup"
        cp -a "$db" "$BACKUP/cookies-backup/$(echo "$db" | tr '/ ' '__')" 2>/dev/null
        m="$(sqlite3 "file:$db" "DELETE FROM cookies WHERE host_key LIKE '%claude%' OR host_key LIKE '%anthropic%'; SELECT changes();" 2>/dev/null || echo 0)"
        ok "已清理 ${m:-0} 条: $db"
      fi
    fi
  done
  [[ $hits -eq 0 ]] && info "所有 cookie 数据库均无 claude/anthropic 命中。"
  warn "注意:LocalStorage / IndexedDB / Service Worker 深层清理与 Safari 见 references/browser-residue.md。"
else
  info "如浏览器里存过 claude.ai/anthropic 的站点数据:加 --include-browser-sites 自动清 cookie;"
  info "或手动:Chrome → 设置 → 隐私和安全 → 第三方 Cookie → 查看所有网站数据 → 搜索删除"
  info "claude.ai / anthropic.com / claude.com。完整指引(含 LocalStorage/Service Worker/Safari)见"
  info "references/browser-residue.md。"
fi

# ---- Claude Code CLI(可选:--include-cli)----
hdr "Claude Code CLI 残留"
if [[ $INC_CLI -eq 1 ]]; then
  if [[ -d "$HOME/.npm-global/lib/node_modules/@anthropic-ai/claude-code" ]]; then
    if [[ $APPLY -eq 0 ]]; then
      info "会卸载 npm 全局包 @anthropic-ai/claude-code(先备份目录)"
    else
      mkdir -p "$BACKUP/npm-global/@anthropic-ai"
      cp -a "$HOME/.npm-global/lib/node_modules/@anthropic-ai/claude-code" "$BACKUP/npm-global/@anthropic-ai/" 2>/dev/null
      if npm uninstall -g @anthropic-ai/claude-code >/dev/null 2>&1; then
        ok "npm 包已卸载"
      else
        warn "npm uninstall 失败,请手动: npm uninstall -g @anthropic-ai/claude-code"
      fi
      rm -f "$HOME/.npm-global/bin/claude" "$HOME/.npm-global/bin/claude.real" 2>/dev/null
    fi
  else
    info "未发现 npm 全局包 @anthropic-ai/claude-code"
  fi
  process_targets "$HOME/Applications/Claude Code URL Handler.app"
  CLINM=()
  while IFS= read -r -d '' f; do CLINM+=( "$f" ); done < <(find "$APPSUP" -maxdepth 5 -path '*NativeMessagingHosts*' \( -iname '*anthropic*' -o -iname '*claude*' \) -print0 2>/dev/null)
  process_targets ${CLINM[@]+"${CLINM[@]}"}
  warn "还需自查:壳层配置(~/.zshrc 里的 claude 函数/别名、ANTHROPIC_* 环境变量)与 ~/.local/bin/claude-*"
  warn "辅助脚本;明细见 references/browser-residue.md 第 4 节。"
else
  info "如需卸载 Claude Code CLI(npm 包 + URL Handler + 浏览器 NativeMessaging):加 --include-cli。"
fi

echo
if [[ $APPLY -eq 0 ]]; then
  warn "以上为预演。确认后执行:  bash $(basename "$0") --yes"
else
  ok "清理完成。备份保存在: $BACKUP"
  info "确认一切正常、用一阵子后,该备份可自行删除。"
fi
