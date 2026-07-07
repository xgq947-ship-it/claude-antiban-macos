# 网络层 · 第 1/2/3/5/6 点(以 Clash Verge / verge-mihomo 为例)

网络层通常靠代理配置到位。用户若用别的代理工具,原理相同,具体位置对照自家工具。

## 1/2 · 干净 / 住宅 IP + 保持不变

- **住宅 IP**:选**住宅 ISP** 出口(如 Comcast/AT&T 等),避免 datacenter/hosting。
  `curl -s https://ipinfo.io/json` 看 `org` 字段;含 hosting/cloud/datacenter 字样即机房 IP,风险高。
- **稳定**:固定**单出口节点**,别开自动切换/负载均衡。登录、日常使用尽量同一节点,
  避免短时间内 IP 跨国跳变(最明显的异常信号)。

## 3 · 强制 TCP,远离 UDP

封掉 QUIC 和 STUN,逼流量走 TCP。在 Clash 规则里对以下目标 `REJECT`:

```yaml
rules:
  - 'DST-PORT,443,REJECT,udp'     # QUIC
  - 'DST-PORT,3478,REJECT,udp'    # STUN
```

并开启 `tcp-concurrent: true`。验证:
```bash
curl -s --unix-socket /tmp/verge/verge-mihomo.sock http://localhost/configs \
  | /usr/bin/python3 -c 'import sys,json;print("tcp-concurrent=",json.load(sys.stdin).get("tcp-concurrent"))'
```

> 具体规则写法因订阅/配置而异;若用 merge/profile,注意本机上「merge 覆盖可能失效」的坑(见 ipv6-clash.md),
> 必要时用全局 `Script.js` 注入。

## 5 · DNS 走代理

用加密 DNS(DoH),别用系统明文 DNS:

```yaml
dns:
  enable: true
  enhanced-mode: fake-ip
  nameserver:
    - https://1.1.1.1/dns-query
    - https://8.8.8.8/dns-query
```

验证 `dns.enable=true`。国内域名可走 DoT。目的:不让明文 DNS 泄漏你访问了哪些站、真实位置。

## 6 · 关 IPv6

见独立文档 `references/ipv6-clash.md`(本机有「merge 无效、必须用 Script」的坑)。

## 回退

改配置前备份对应 yaml(`cp x.yaml x.yaml.bak.$(date +%s)`),需要时覆盖回。
