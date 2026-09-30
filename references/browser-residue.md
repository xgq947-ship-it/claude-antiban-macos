# 浏览器与设备残留清理

「同机换号会被关联」最常见的载体不是电脑硬件,而是**浏览器里的设备标识/存储**与系统里的零散残留。
本文件覆盖:站点数据、隔离 profile、Safari、系统小残留、Claude Code CLI、设备标识说明。

## 1. 浏览器站点数据(cookie / LocalStorage / IndexedDB / Service Worker)

可能残留 Claude 痕迹的浏览器(逐一处理):

- 默认 Chrome 的每个 profile(如 `Default`)
- 专给 Claude 的隔离 profile / user-data-dir(如 `Chrome-Claude`)——**直接整个重置**最干净
  (=全新指纹,需重新登录;启动器留着即可,指向的目录清空后就是新环境)
- 其它 Chromium 系(Brave / Edge / Chromium / Arc / Vivaldi)
- 内置浏览器(如 Codex 的 `Default` / `Partitions/codex-browser-app` 等)

### 做法 A:界面手动(简单,推荐给不熟命令行的用户)

Chrome → 设置 → 隐私和安全 → 第三方 Cookie → 查看所有网站数据 → 搜索并逐个删除:
`claude.ai`、`claude.com`、`platform.claude.com`、`anthropic.com`、`console.anthropic.com`。
(删站点数据会连它的 cookie / LocalStorage / IndexedDB / Service Worker 一起清掉。)

### 做法 B:命令行精确(先完全退出对应浏览器)

- **cookie 行删除**(对应浏览器 cookie 数据库,先备份再删):
  ```bash
  sqlite3 "file:<…>/Cookies" "DELETE FROM cookies WHERE host_key LIKE '%claude%' OR host_key LIKE '%anthropic%'; SELECT changes();"
  ```
- **IndexedDB**:直接删除对应目录,如 `IndexedDB/https_claude.ai_0.indexeddb.leveldb`(连同 `.blob`)
- **LocalStorage / Service Worker / CacheStorage** 不能按文件精确删:
  用做法 A 让 Chrome 自己清,或走做法 C。

### 做法 C:CDP 深度清(实测可行;Chrome 136+ 有限制需绕过)

较新 Chrome(≥136)出于安全考虑,**默认数据目录上禁止开启远程调试**——直接加
`--remote-debugging-port` 会静默无效(端口不绑定)。绕过步骤:

1. 完全退出 Chrome,把数据目录临时改名(同卷 mv,秒完成):
   `Google/Chrome` → `Google/Chrome-scrub`
2. 启动 headless 并指向改名后的目录(**必须带 `--remote-allow-origins`**):
   ```bash
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --headless=new --remote-debugging-port=9224 --remote-allow-origins='*' \
     --user-data-dir="$HOME/Library/Application Support/Google/Chrome-scrub" \
     --profile-directory=Default --no-first-run
   ```
3. 用 CDP 对每个 origin 清 `storageTypes:"all"`(可用 python `websocket-client`,
   连接时 `suppress_origin=True`;或先手动连接看 403 提示):
   `Storage.clearDataForOrigin({origin, storageTypes:"all"})`
   origins: `https://claude.ai`、`https://claude.com`、`https://platform.claude.com`、
   `https://console.anthropic.com`、`https://anthropic.com` 及各自的 www 变体。
4. 关闭 headless,把目录名改回 `Chrome`。

## 2. Safari(系统保护,最稳的是手动)

Safari → 设置 → 隐私 → 管理网站数据 → 搜索 `claude` / `anthropic` → 全部移除。

> 参考:它的 `Cookies.binarycookies` 为二进制格式(头部大端、页内字段小端、尾部还有一段
> bplist 元数据如 `NSHTTPCookieAcceptPolicy`)。**不建议手改**;如确需脚本处理,务必先备份 +
> 写后重新解析验证,并注意 Safari 需先完全退出。

## 3. 系统小残留

- `~/Library/Application Support/CrashReporter/Claude_*.plist`
- `$(getconf DARWIN_USER_CACHE_DIR)com.anthropic.claudefordesktop*`(app 容器缓存)
- `/private/tmp/claude-*`(会话临时目录;Claude Code / VM 的暂存,常见几百 MB 量级)
- 桌面端 / CLI 在 Keychain 的条目:见 `00-cleanup.md`「Keychain 里的 Claude 凭据」

## 4. Claude Code CLI 残留(可选;脚本 `--include-cli`)

- npm 全局包 `@anthropic-ai/claude-code`(`npm uninstall -g @anthropic-ai/claude-code`)
  以及 `~/.npm-global/bin/` 下可能残留的 `claude` / `claude.real` 符号链接
- `~/Applications/Claude Code URL Handler.app`(claude-cli:// 深链处理器)
- 各浏览器 `NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json`
- shell 配置自查(~/.zshrc 等):`claude()` 函数/别名、`ENABLE_PROMPT_CACHING_1H`、
  CC Switch 相关 `ANTHROPIC_*` 变量清理块
- `~/.local/bin/` 下的 `claude-*` 辅助脚本(如 `claude-oauth-browser`;
  **隔离浏览器的打开器如 `claude-profile1` 若还想用,注意保留**)

## 5. 设备标识说明(为什么这些要清)

- **桌面端**:`Application Support/Claude/` 内的 `ant-did`、`ant-device-registry.json`(设备 ID 注册表)
- **CLI**:`~/.claude.json` 的 `machineID`;`~/.claude/.credentials.json`
- **Keychain**:「Claude Safe Storage」(桌面端加密密钥)、「Claude Code-credentials」(CLI 登录凭据)
- **浏览器**:站点 cookie 里的 `anthropic-device-id`、`claudeai.v1.<uuid>` 等客户端标识

以上全部清掉 = 设备侧标识重置;重装 / 重登会生成全新 ID。**注意**:网站读不到电脑序列号/主板
UUID 这类硬件信息,关联主要发生在「浏览器存储 + 网络出口 + 账号信息」三条线上,别把重点放错。

## 6. 验证

- 各浏览器:`chrome://settings/content/all` 搜 claude;或重跑清理命令应 0 命中。
- Safari:管理网站数据里搜 claude 应无结果。
- 如卸载了 CLI:`command -v claude` 应无输出。
- (leveldb 类文件可能残留未被压实的旧字节,grep 偶有命中属正常,数据层已删除。)

## 回退

- cookie 数据库 / 清单在 `claude-backup-<时间戳>/` 里都有副本。
- Safari cookie 文件被脚本改动时会自带 `.bak-<时间戳>` 备份。
