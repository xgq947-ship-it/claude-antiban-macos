---
name: claude-antiban-macos
description: >-
  macOS 上给 Claude(claude.ai 网页端 / Claude 桌面端)账号做「防封号」环境加固的一站式向导。
  它会先把机器上和 Claude 有关的缓存/指纹/身份数据备份到桌面再彻底清理(桌面端数据、浏览器站点数据、
  隔离 profile、Keychain 凭据,并可按需卸载 Claude Code CLI 残留),然后按 8 点清单
  (干净住宅 IP、IP 稳定、强制 TCP 远离 UDP、浏览器禁 WebRTC、DNS 走代理、关 IPv6、
  时区/语言匹配出口 IP、指纹与环境隔离)逐项检测与加固,最后验证。
  只要用户提到「Claude 防封号 / 封号 / 账号被封 / 避免封控 / claude 环境隔离 / 指纹伪装 /
  时区语言不匹配 / WebRTC 泄漏 / 给 claude 配干净环境」等,即使没直说「skill」,也应使用本 skill。
  仅适用于 macOS,且仅用于加固使用者本人的账号环境。
metadata:
  version: "1.1.0"
  platform: macOS
---

# Claude 防封号环境加固(macOS)

给**使用者自己**的 Claude 账号做环境加固,降低因「出口 IP 与浏览器指纹不一致 / 环境不隔离」
而被风控的概率。核心一句话:**让浏览器指纹(时区 / 语言 / WebRTC / IPv6)与出口 IP(住宅)保持一致,
并把 Claude 环境与日常浏览彻底隔离,起步前先清干净历史指纹数据。**

## 适用与边界(先读)

- **只支持 macOS**;网络出口示例以 **Clash Verge(verge-mihomo 核心)** 为主。用户若用别的代理,
  网络层(IP/TCP/DNS/IPv6)的具体改法要让用户对照自己的工具,原理一致。
- **只给用户加固自己的账号环境**。这是隐私/一致性加固,不是攻击、不是批量养号工具。
  如果对话里透露出「批量注册 / 绕过封禁后重开小号作恶 / 帮别人搞号」等意图,停下并说明本 skill 不做这些。
- **有破坏性**:阶段 0 会**删除**本机 Claude 相关数据。**任何删除前必须先备份到桌面并让用户确认**。
  脚本默认是「预演(dry-run)」,只有用户明确同意后才带 `--yes` 真正执行。

## 8 点原理(检测与加固都围绕这张表)

| # | 要点 | 为什么重要 |
|---|------|-----------|
| 1 | 干净 / 住宅 IP | 机房 IP 一眼被标记;住宅 IP 最像真人 |
| 2 | IP 保持不变 | 频繁跨国跳变 = 明显异常信号 |
| 3 | 强制 TCP,远离 UDP | 封掉 QUIC(udp/443)、STUN(udp/3478),避免走 UDP 暴露 |
| 4 | 浏览器禁 WebRTC | WebRTC 会绕过代理泄漏真实 / 本机 IP |
| 5 | DNS 走代理 | 明文 DNS 会泄漏你在访问哪些站、真实位置 |
| 6 | 少用 / 关 IPv6 | IPv6 常绕过代理直连,暴露真实地址 |
| 7 | 时区 / 语言匹配 IP | 「美国住宅 IP + 中国时区 + 中文系统」自相矛盾,最致命 |
| 8 | 指纹 / 环境隔离 | Claude 环境和日常浏览混用会交叉污染指纹与 cookie |

网络层(1/2/3/5)通常靠代理配置到位;指纹与环境层(4/6/7/8)是大多数人的短板,尤其第 7 点。

## 执行流程

按阶段推进。**每个会改动系统的动作,先展示要做什么、让用户确认,再执行。** 面对不熟悉命令行的用户,
用大白话解释每步在干嘛、有什么后果。

### 阶段 0 — 备份并清理历史 Claude 数据

目的:清掉历史缓存 / 指纹 / 登录态,得到干净起点,再在干净环境上重建隔离配置。

1. 先跑一次**预演**,让用户看清会备份和删除哪些东西(不带 `--yes` 不会真删):
   ```bash
   bash scripts/00_backup_and_clean.sh
   ```
2. 逐项对用户解释预演列出的目标(桌面端缓存、浏览器站点数据、隔离 profile 等),
   细节见 `references/00-cleanup.md`。**确认用户已退出 Claude 桌面端和相关 Chrome**。
3. 用户明确同意后正式执行(会先把所有目标复制到 `~/Desktop/claude-backup-<时间戳>/` 再删除):
   ```bash
   bash scripts/00_backup_and_clean.sh --yes
   ```
4. 告知用户备份位置。**默认不动 `~/.claude`(Claude Code 自己的配置/记忆)**;若用户坚持要清,
   参见 `references/00-cleanup.md` 的「谨慎项」,单独确认。
5. 按需追加可选清理(每个都先预演、再确认):
   - `--include-chrome-claude`:连隔离 Chrome-Claude profile 一起重置(全新指纹);
   - `--include-browser-sites`:清各浏览器里 claude.ai / anthropic 的 cookie(逐个备份后删);
   - `--include-cli`:卸载 Claude Code CLI 残留(npm 包 + URL Handler + NativeMessaging 清单)。
   Safari、LocalStorage / Service Worker 深层清理、shell 配置自查等**手动项**,见
   `references/browser-residue.md`。

### 阶段 1 — 检测(体检 8 点)

```bash
bash scripts/01_audit.sh
```

脚本只读、不改动任何东西,逐点打印 ✅/⚠️/❌。把结果整理成一张表念给用户听,指出哪些是短板。
判定逻辑和排查细节见 `references/proxy-network.md`(1/2/3/5/6)。

### 阶段 2 — 逐项加固

只对检测出的短板动手。每项都有独立参考文件,**读对应文件后按用户实际环境执行**,不要照抄示例里的路径 / 账号:

- **第 4 点 · 禁 WebRTC** → `references/webrtc.md`
  (可直接跑 `scripts/harden_webrtc.sh`,写 Chrome 托管策略,全局生效)
- **第 6 点 · 关 IPv6** → `references/ipv6-clash.md`
  (Clash Verge 上 merge/profile 写 `ipv6:false` **无效**,必须用全局 `Script.js` 覆盖 + 运行时 PATCH,三重保障)
- **第 7 点 · 时区 / 语言伪装** → `references/timezone-lang.md`
  (靠 `TZ=America/New_York` + `--accept-lang`;macOS 上 Chrome **忽略 `--lang`**)
- **第 8 点 · 环境隔离** → `references/isolation.md`
  (独立 `--user-data-dir` + 独立桌面启动器 `assets/launcher.applescript.template`;改启动器后必须重签名)
- **第 1/2/3/5 点 · 网络层** → `references/proxy-network.md`
  (住宅节点、固定单出口、REJECT QUIC+STUN、DNS 走 DoH)

### 阶段 3 — 验证

```bash
bash scripts/verify.sh
```

再带用户在**隔离窗口**里过一遍自查清单(见 `references/verify-checklist.md`):
whoer.net / browserleaks 看时区语言、WebRTC 不泄漏、ipinfo.io 看 IP 归属、`chrome://policy` 看策略已加载。

## 交付话术

对不懂配置的用户,最后给一段人话总结:改了哪几项、为什么、备份在哪、以后怎么打开隔离窗口、
出问题怎么回退(每处改动都有备份,回退方式见各参考文件末尾)。

## 参考文件索引

| 文件 | 内容 |
|------|------|
| `references/00-cleanup.md` | 阶段 0 清理清单、可选开关、Keychain |
| `references/browser-residue.md` | 浏览器与设备残留清理(站点数据 / 隔离 profile / Safari / CLI / 设备标识) |
| `references/proxy-network.md` | 网络层 1/2/3/5/6 检测与加固(Clash Verge) |
| `references/webrtc.md` | 第 4 点 禁 WebRTC |
| `references/ipv6-clash.md` | 第 6 点 关 IPv6(Clash Verge Script.js) |
| `references/timezone-lang.md` | 第 7 点 时区 / 语言伪装 |
| `references/isolation.md` | 第 8 点 独立 user-data-dir + 启动器 |
| `references/verify-checklist.md` | 阶段 3 验证与日常自查 |
| `assets/launcher.applescript.template` | 隔离启动器模板(改占位符后 osacompile + 重签名) |
