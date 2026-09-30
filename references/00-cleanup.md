# 阶段 0 · 备份并清理历史 Claude 数据

目的:清掉历史缓存 / 指纹 / 登录态,得到干净起点。`scripts/00_backup_and_clean.sh` 会**先把每个目标
整体复制到 `~/Desktop/claude-backup-<时间戳>/`,再删除原件**——所以永远可回退。默认预演,`--yes` 才真删。

## 清理前

- **退出 Claude 桌面端**(⌘Q)、相关 **Chrome** 和 **Safari**,否则文件被占用,拷贝/删除不干净。
- 先跑预演,把清单念给用户听,确认没有误伤。

## 自动清理的目标(默认)

| 路径 | 说明 |
|------|------|
| `~/Library/Application Support/Claude` | 桌面端主数据(含登录态、设备 ID `ant-did`/`ant-device-registry.json`、本地缓存) |
| `~/Library/Caches/com.anthropic.claude`、`~/Library/Caches/Claude` | 缓存 |
| `~/Library/Preferences/com.anthropic.claude.plist` | 偏好设置 |
| `~/Library/Saved Application State/com.anthropic.claude.savedState` | 窗口状态 |
| `~/Library/HTTPStorages/com.anthropic.claude*` | HTTP 存储 / cookie |
| `~/Library/WebKit/com.anthropic.claude` | WebKit 存储 |
| `~/Library/Logs/Claude` | 日志 |
| `~/Library/Application Support/CrashReporter/Claude_*.plist` | 崩溃报告残留 |
| `$(getconf DARWIN_USER_CACHE_DIR)com.anthropic.claudefordesktop*` | app 容器缓存 |

> 另外注意:桌面端和 CLI 可能在 Keychain 留条目、`/private/tmp` 留 `claude-*` 会话临时目录,
> 见下文与 `browser-residue.md`。

## 可选目标(需显式开启)

- `--include-chrome-claude`:连独立的 `Google/Chrome-Claude`(隔离浏览器 profile)一起清。
  清掉 = 全新指纹,**需要重新登录 Claude**。想要「彻底干净」时用它。
- `--include-browser-sites`:扫描各浏览器(Chrome/Brave/Edge/Arc/Vivaldi/Codex 等)的 cookie 数据库,
  删除其中 claude.ai / anthropic.com 的行(逐个先备份再删)。
  LocalStorage / IndexedDB / Service Worker / Safari 的深层清理见 `references/browser-residue.md`。
- `--include-claude-code`:清 `~/.claude`。**默认不清**,因为里面是 Claude Code 自己的配置与记忆。
  只有用户明确要连 Claude Code 一起重置时才开,且要单独二次确认。
- `--include-cli`:卸载 Claude Code CLI 残留(npm 包 + URL Handler + 浏览器 NativeMessaging 清单)。
  shell 配置与 `~/.local/bin/claude-*` 脚本的手动自查项见 `references/browser-residue.md`。

## 浏览器站点数据(claude.ai / anthropic.com)

三种方式(界面手动 / 命令行精确 / CDP 深度清)与 Safari、隔离 profile 重置的完整步骤,
见 `references/browser-residue.md`。

## Keychain 里的 Claude 凭据

桌面端与 CLI 可能在钥匙串留有:

- `Claude Safe Storage`(桌面端加密密钥,account 常为 `Claude Key`)
- `Claude Code-credentials`(CLI 登录凭据)

查看 / 删除(会导致下次重新登录):

```bash
security find-generic-password -s "Claude Safe Storage" 2>/dev/null
security find-generic-password -s "Claude Code-credentials" 2>/dev/null
# 确认后再删:
# security delete-generic-password -s "Claude Safe Storage" -a "Claude Key"
# security delete-generic-password -s "Claude Code-credentials"
```

## 回退

需要恢复时,把 `~/Desktop/claude-backup-<时间戳>/` 里对应子目录拷回原位即可(路径与备份内相对路径一致)。
Safari cookie 文件被脚本改动时会自带 `.bak-<时间戳>` 备份。
