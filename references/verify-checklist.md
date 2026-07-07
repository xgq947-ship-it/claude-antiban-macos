# 阶段 3 · 验证与日常自查清单

`scripts/verify.sh` 能自动查的:IPv6 是否关、WebRTC 策略是否设、隔离环境/启动器是否存在、当前出口 IP。
下面这些需在**隔离窗口**(桌面「Claude Chrome」图标打开的那个)里人工过一遍。

## 在隔离窗口里逐项确认

| 检查 | 打开 | 期望 |
|------|------|------|
| 时区 / 语言 | `whoer.net` 或 `browserleaks.com/javascript` | 显示目标地区,如 New York / en-US |
| WebRTC 不泄漏 | `browserleaks.com/webrtc` | 看不到真实 / 本机 IP |
| 策略已加载 | `chrome://policy` | 含 `WebRtcIPHandling` |
| IP 归属 | `ipinfo.io` | 目标住宅 IP(如美东住宅) |

## 命令行速查 IPv6

```bash
curl -s --unix-socket /tmp/verge/verge-mihomo.sock http://localhost/configs \
  | /usr/bin/python3 -c "import sys,json;print('ipv6=',json.load(sys.stdin).get('ipv6'))"
```

## 一致性总原则

时区、语言、IP 归属**三者必须相互一致**。任意一项对不上(经典:美国 IP + 中国时区),
就是最容易被识别的破绽。换节点后重新跑一遍验证。

## 已知缺口(提醒用户)

1. 认准隔离窗口管 Claude 账号;它和日常 Chrome 是两套登录态,不互通。
2. Chrome for Testing / Playwright 不在加固内,手动走那条自动化路会绕过防护。
3. WebRTC 策略仅覆盖 `com.google.Chrome`。
4. 登录、切节点尽量用同一住宅节点,别短时间 IP 跨国跳变。
