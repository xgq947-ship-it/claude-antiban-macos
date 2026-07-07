# 阶段 0 · 备份并清理历史 Claude 数据

目的:清掉历史缓存 / 指纹 / 登录态,得到干净起点。`scripts/00_backup_and_clean.sh` 会**先把每个目标
整体复制到 `~/Desktop/claude-backup-<时间戳>/`,再删除原件**——所以永远可回退。默认预演,`--yes` 才真删。

## 清理前

- **退出 Claude 桌面端**(⌘Q)和相关 **Chrome**,否则文件被占用,拷贝/删除不干净。
- 先跑预演,把清单念给用户听,确认没有误伤。

## 自动清理的目标(桌面端)

| 路径 | 说明 |
|------|------|
| `~/Library/Application Support/Claude` | Claude 桌面端主数据(含登录态、本地缓存) |
| `~/Library/Caches/com.anthropic.claude`、`~/Library/Caches/Claude` | 缓存 |
| `~/Library/Preferences/com.anthropic.claude.plist` | 偏好设置 |
| `~/Library/Saved Application State/com.anthropic.claude.savedState` | 窗口状态 |
| `~/Library/HTTPStorages/com.anthropic.claude*` | HTTP 存储 / cookie |
| `~/Library/WebKit/com.anthropic.claude` | WebKit 存储 |
| `~/Library/Logs/Claude` | 日志 |

## 可选目标(需显式开启)

- `--include-chrome-claude`:连独立的 `Google/Chrome-Claude`(隔离浏览器 profile)一起清。
  清掉 = 全新指纹,**需要重新登录 Claude**。想要「彻底干净」时用它。
- `--include-claude-code`:清 `~/.claude`。**默认不清**,因为里面是 Claude Code 自己的配置与记忆。
  只有用户明确要连 Claude Code 一起重置时才开,且要单独二次确认。

## 浏览器站点数据(claude.ai / anthropic.com)—— 手动

默认 Chrome 里按站点精确删 cookie/storage 比较脆弱,脚本不自动做。**先完全退出 Chrome**,再选一种:

- **省事(推荐给小白)**:Chrome → 设置 → 隐私和安全 → 第三方 Cookie / 网站数据 →
  搜索 `claude.ai`、`anthropic.com`、`claude.com`,逐个删除。
- **彻底**:既然阶段 2 要建全新的隔离 profile,直接对默认 Chrome 用
  `--include-chrome-claude` 思路——把 Claude 账号从默认 Chrome 迁走、只在隔离 profile 里登录,
  默认 Chrome 就不再持有 Claude 站点数据。见 `references/isolation.md`。

## Keychain 里的 Claude 凭据(可选)

桌面端可能在钥匙串留有令牌。查看 / 删除(会导致下次重新登录):

```bash
security find-generic-password -l "Claude" 2>/dev/null      # 先看有没有
# 确认后再删(名字以实际输出为准):
# security delete-generic-password -l "Claude"
```

## 回退

需要恢复时,把 `~/Desktop/claude-backup-<时间戳>/` 里对应子目录拷回原位即可(路径与备份内相对路径一致)。
