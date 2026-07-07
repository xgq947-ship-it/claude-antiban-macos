#!/usr/bin/env bash
# 阶段 3:加固后自动验证(能自动查的部分)。
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
require_macos

hdr "阶段 3 · 验证"

# IPv6 已关
v6="$(mihomo_config | /usr/bin/python3 -c 'import sys,json;print(json.load(sys.stdin).get("ipv6"))' 2>/dev/null)"
[[ "$v6" == "False" ]] && ok "IPv6 已关(运行时 ipv6=false)" || warn "IPv6 状态: ${v6:-未知(未连上 Clash Verge)}"

# WebRTC 策略
h="$(defaults read com.google.Chrome WebRtcIPHandling 2>/dev/null)"
[[ "$h" == "disable_non_proxied_udp" ]] && ok "WebRTC 策略已设置" || bad "WebRTC 策略未设置"

# 隔离环境
[[ -d "$HOME/Library/Application Support/Google/Chrome-Claude" ]] && ok "隔离环境 Chrome-Claude 存在" || warn "未发现隔离环境"
[[ -e "$HOME/Desktop/Claude Chrome.app" ]] && ok "桌面隔离启动器存在" || warn "未发现桌面隔离启动器"

# 出口 IP
ip="$(curl -s --max-time 6 https://ipinfo.io/ip 2>/dev/null)"
[[ -n "$ip" ]] && info "当前出口 IP: $ip(人工确认为住宅、与时区/语言一致)" || warn "取不到出口 IP"

echo
info "以下需在【隔离窗口】里人工过一遍(见 references/verify-checklist.md):"
dim "  · whoer.net / browserleaks.com/javascript → 时区 New York、语言 en-US"
dim "  · browserleaks.com/webrtc               → 看不到真实/本机 IP"
dim "  · chrome://policy                        → 含 WebRtcIPHandling"
dim "  · ipinfo.io                              → 美东住宅(或你的目标归属)"
