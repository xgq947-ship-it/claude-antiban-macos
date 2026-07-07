# claude-antiban-macos

一个 **Claude Code / Claude 桌面端 Skill**:在 **macOS** 上给你**自己**的 Claude 账号做「防封号」环境加固。
让浏览器指纹(时区 / 语言 / WebRTC / IPv6)与出口 IP(住宅)保持一致,并把 Claude 环境与日常浏览彻底隔离——
起步前先把历史指纹数据备份到桌面再清干净。

> 面向不懂配置的人:装上后直接对 Claude 说「帮我做 Claude 防封号加固」,它会一步步带你检测、清理、加固、验证。

## 这个 Skill 会做什么

按一份 8 点清单检测与加固:

| # | 要点 | # | 要点 |
|---|------|---|------|
| 1 | 干净 / 住宅 IP | 5 | DNS 走代理 |
| 2 | IP 保持不变 | 6 | 少用 / 关 IPv6 |
| 3 | 强制 TCP,远离 UDP | 7 | 时区 / 语言匹配 IP |
| 4 | 浏览器禁 WebRTC | 8 | 指纹 / 环境隔离 |

流程:**阶段 0 备份并清理历史 Claude 数据 → 阶段 1 八点体检 → 阶段 2 逐项加固 → 阶段 3 验证**。
每个会改动系统的动作都会先展示、让你确认再执行;删除前一律先备份到桌面 `claude-backup-<时间戳>/`。

## 适用范围

- **仅 macOS**。
- 网络出口示例以 **Clash Verge(verge-mihomo 核心)** 为主;用别的代理时,网络层原理相同、位置对照自家工具。
- **只用于加固使用者本人的账号环境**,这是隐私/一致性加固,不是攻击或批量养号工具。

## 安装

**Claude Code:**
```bash
git clone https://github.com/<你的用户名>/claude-antiban-macos.git
mkdir -p ~/.claude/skills
cp -r claude-antiban-macos ~/.claude/skills/claude-antiban-macos
```
重开 Claude Code,说「Claude 防封号加固」即可触发。

**Claude 桌面端 / claude.ai:** 把整个目录打包成 `.skill` 上传,或在支持 Skill 的界面里导入 `SKILL.md`。

## 目录结构

```
claude-antiban-macos/
├── SKILL.md                     # 主向导(Claude 读它来编排整个流程)
├── scripts/
│   ├── 00_backup_and_clean.sh   # 阶段0:备份到桌面后清理(默认预演,--yes 才真删)
│   ├── 01_audit.sh              # 阶段1:8点体检(只读)
│   ├── harden_webrtc.sh         # 第4点:写 Chrome WebRTC 策略
│   ├── verify.sh                # 阶段3:自动验证
│   └── lib/common.sh
├── references/                  # 逐项加固详解(Claude 按需读取)
│   ├── 00-cleanup.md  proxy-network.md  webrtc.md
│   ├── ipv6-clash.md  timezone-lang.md  isolation.md  verify-checklist.md
└── assets/launcher.applescript.template   # 隔离浏览器启动器模板
```

## 安全须知

- **有破坏性**:阶段 0 会删除本机 Claude 相关数据。脚本默认**预演**,只有 `--yes` 才真正执行,且删除前先整体备份到桌面。
- 默认**不动 `~/.claude`**(Claude Code 自己的配置/记忆);要清需 `--include-claude-code` 显式开启并二次确认。
- 每处系统改动都有备份与回退方式,见各 `references/*.md` 末尾。

## License

MIT
