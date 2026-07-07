#!/usr/bin/env bash
# 阶段 1:8 点体检。只读,不改动任何东西。
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
require_macos

hdr "阶段 1 · 8 点体检(只读)"

CFG="$(mihomo_config)"; HAVE_CFG=$?

# 1/2 出口 IP
hdr "1/2 · 出口 IP(干净住宅 + 稳定)"
IPINFO="$(curl -s --max-time 6 https://ipinfo.io/json 2>/dev/null)"
if [[ -n "$IPINFO" ]]; then
  ip="$(echo "$IPINFO"    | /usr/bin/python3 -c 'import sys,json;print(json.load(sys.stdin).get("ip",""))' 2>/dev/null)"
  org="$(echo "$IPINFO"   | /usr/bin/python3 -c 'import sys,json;print(json.load(sys.stdin).get("org",""))' 2>/dev/null)"
  loc="$(echo "$IPINFO"   | /usr/bin/python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("city",""),d.get("region",""),d.get("country",""))' 2>/dev/null)"
  info "出口 IP : ${ip}"
  info "归属    : ${org}"
  info "位置    : ${loc}"
  warn "请人工判断:是否住宅 ISP(非 datacenter/hosting)、是否固定单节点。跨国跳变=风险。"
else
  bad "取不到出口 IP(检查网络 / 代理)。"
fi

# 3 TCP / 远离 UDP
hdr "3 · 强制 TCP,远离 UDP(QUIC/STUN)"
if [[ $HAVE_CFG -eq 0 ]]; then
  tcpcc="$(echo "$CFG" | /usr/bin/python3 -c 'import sys,json;print(json.load(sys.stdin).get("tcp-concurrent"))' 2>/dev/null)"
  [[ "$tcpcc" == "True" ]] && ok "tcp-concurrent = true" || warn "tcp-concurrent = ${tcpcc:-未知}"
  warn "QUIC(udp/443)/STUN(udp/3478)是否 REJECT 需查规则,见 references/proxy-network.md。"
else
  warn "未连上 Clash Verge(mihomo socket),TCP/UDP 策略无法自动判定。"
fi

# 5 DNS 走代理
hdr "5 · DNS 走代理"
if [[ $HAVE_CFG -eq 0 ]]; then
  dnsen="$(echo "$CFG" | /usr/bin/python3 -c 'import sys,json;print(json.load(sys.stdin).get("dns",{}).get("enable"))' 2>/dev/null)"
  [[ "$dnsen" == "True" ]] && ok "DNS 已由代理接管(enable=true)" || warn "DNS enable = ${dnsen:-未知}"
else
  warn "未连上 Clash Verge,DNS 策略无法自动判定。"
fi

# 6 IPv6
hdr "6 · 关 IPv6"
if [[ $HAVE_CFG -eq 0 ]]; then
  v6="$(echo "$CFG" | /usr/bin/python3 -c 'import sys,json;print(json.load(sys.stdin).get("ipv6"))' 2>/dev/null)"
  [[ "$v6" == "False" ]] && ok "运行时 ipv6 = false" || bad "运行时 ipv6 = ${v6:-未知}(应为 false),见 references/ipv6-clash.md"
else
  warn "未连上 Clash Verge,IPv6 状态无法自动判定。"
fi

# 4 WebRTC 策略
hdr "4 · 浏览器禁 WebRTC(Chrome 托管策略)"
h="$(defaults read com.google.Chrome WebRtcIPHandling 2>/dev/null)"
if [[ "$h" == "disable_non_proxied_udp" ]]; then
  ok "Chrome 策略 WebRtcIPHandling = disable_non_proxied_udp"
else
  bad "未设置 WebRtcIPHandling 策略,浏览器可能经 WebRTC 泄漏真实 IP,见 references/webrtc.md"
fi

# 7 时区 / 语言(本机系统层面,仅供参考;真正生效的是隔离浏览器进程里的伪装)
hdr "7 · 时区 / 语言匹配 IP"
info "系统时区 : $(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##')"
info "系统语言 : $(defaults read -g AppleLocale 2>/dev/null)"
warn "关键看隔离浏览器窗口内的 TZ/accept-lang 是否与出口 IP 一致,见 references/timezone-lang.md。"

# 8 环境隔离
hdr "8 · 指纹 / 环境隔离"
CC="$HOME/Library/Application Support/Google/Chrome-Claude"
if [[ -d "$CC" ]]; then
  ok "存在独立 Claude 环境: $CC"
else
  warn "未发现独立 Chrome-Claude 环境,Claude 与日常浏览可能未隔离,见 references/isolation.md"
fi
[[ -e "$HOME/Desktop/Claude Chrome.app" ]] && ok "存在桌面隔离启动器: Claude Chrome.app" \
  || warn "未发现桌面隔离启动器 Claude Chrome.app"

echo; ok "体检完成。把 ❌/⚠️ 项按 references/ 对应文件逐个加固。"
