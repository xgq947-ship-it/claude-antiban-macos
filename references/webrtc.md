# 第 4 点 · 浏览器禁 WebRTC(防 IP 泄漏)

**为什么重要**:WebRTC 为了做 P2P,会尝试直接获取本机 / 真实公网 IP 并可能绕过代理,
让你精心伪装的住宅出口 IP 前功尽弃。要强制 WebRTC 只走代理、不泄漏本机地址。

## 一键设置

直接跑脚本:
```bash
bash scripts/harden_webrtc.sh
```

它等价于设置 Chrome 托管策略:
```bash
defaults write com.google.Chrome WebRtcIPHandling -string "disable_non_proxied_udp"
defaults write com.google.Chrome WebRTCIPHandlingPolicy -string "disable_non_proxied_udp"   # 旧版兼容 key
```

## 要点与坑

- **全局生效**:覆盖所有 `com.google.Chrome` 实例,但需**完全退出 Chrome 再打开**才加载。
  用独立启动器的隔离 profile 天然是新进程,新开即生效。
- **只覆盖 `com.google.Chrome`**,**不覆盖 Chrome for Testing**(`com.google.chrome.for.testing`,Playwright 用的)。
- `disable_non_proxied_udp` = 允许走代理的 UDP,但禁止不经代理的直连 UDP,从而堵住 WebRTC 泄漏路径。

## 验证

1. `chrome://policy` → 应能看到 `WebRtcIPHandling`。
2. `browserleaks.com/webrtc` → 看不到真实 / 本机 IP。

## 回退

```bash
defaults delete com.google.Chrome WebRtcIPHandling
defaults delete com.google.Chrome WebRTCIPHandlingPolicy
```
