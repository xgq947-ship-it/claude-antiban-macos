#!/usr/bin/env bash
# 第 4 点:设置 Chrome 托管策略,强制 WebRTC 只走代理、不泄漏本机/真实 IP。
# 全局生效(所有 com.google.Chrome 实例),需完全退出 Chrome 再打开才加载。
# 注意:不覆盖 Chrome for Testing(com.google.chrome.for.testing)。
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"
require_macos

hdr "第 4 点 · 禁 WebRTC"
defaults write com.google.Chrome WebRtcIPHandling -string "disable_non_proxied_udp"
defaults write com.google.Chrome WebRTCIPHandlingPolicy -string "disable_non_proxied_udp"  # 旧版兼容
ok "已写入 Chrome 策略 WebRtcIPHandling = disable_non_proxied_udp"
info "验证:完全退出 Chrome 再打开,访问 chrome://policy 应能看到 WebRtcIPHandling。"
info "再到 browserleaks.com/webrtc 确认看不到真实/本机 IP。"
