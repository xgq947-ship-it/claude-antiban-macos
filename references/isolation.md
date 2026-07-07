# 第 8 点 · 独立环境隔离 + 桌面启动器

**为什么重要**:Claude 环境和日常浏览混用,cookie / 指纹会交叉污染。给 Claude 配**独立
`--user-data-dir`** = 独立浏览器进程,时区/语言伪装永远生效、与日常 Chrome 互不污染、不必每次先退出 Chrome。

## 1) 建独立数据目录

给 Claude 用独立目录:`~/Library/Application Support/Google/Chrome-Claude`。

- **想全新指纹(推荐,配合阶段 0 的彻底清理)**:直接建空目录,首次打开重新登录 Claude 即可。
- **想免重新登录**:从日常 Chrome 克隆放 Claude 账号的那个 profile。**必须连根目录 `Local State`
  一起拷**(它是 cookie 解密密钥引用),否则 cookie 解不开:
  ```bash
  SRC="$HOME/Library/Application Support/Google/Chrome"
  DEST="$HOME/Library/Application Support/Google/Chrome-Claude"
  mkdir -p "$DEST"
  cp "$SRC/Local State" "$DEST/Local State"
  rsync -a --exclude='Cache' --exclude='Code Cache' --exclude='GPUCache' \
    --exclude='Service Worker/CacheStorage' --exclude='Service Worker/ScriptCache' \
    "$SRC/Profile 1/" "$DEST/Profile 1/"        # Profile 1 换成放 Claude 账号的那个
  ```

**账号分离拓扑建议**:日常 Chrome 只留日常账号;隔离 `Chrome-Claude` 只放 Claude 账号。
把日常 Chrome 里的 Claude profile 移到备份目录(非硬删,可回退),两套登录态互不相通。

## 2) 桌面启动器(注入 TZ / 语言 / 独立目录)

用 `assets/launcher.applescript.template`,替换里面的占位符:

- `__TZ__` → 目标时区(如 `America/New_York`)
- `__ACCEPT_LANG__` → 目标语言(如 `en-US,en`)
- `__USER_DATA_DIR__` → `/Users/你的用户名/Library/Application Support/Google/Chrome-Claude`
- `__PROFILE_DIR__` → `Profile 1`(或你放 Claude 账号的 profile 名)

核心命令形如:
```applescript
do shell script "TZ='America/New_York' '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' \
  --user-data-dir='/Users/你/Library/Application Support/Google/Chrome-Claude' \
  --profile-directory='Profile 1' --accept-lang='en-US,en' \
  --no-first-run --no-default-browser-check --new-window 'https://claude.ai' >/dev/null 2>&1 &"
```

## 3) 编译成 .app 并**重新签名**(否则报「已损坏」打不开)

```bash
APP="$HOME/Desktop/Claude Chrome.app"
# 首次可用「脚本编辑器」导出为应用程序;更新脚本时:
osacompile -o "$APP/Contents/Resources/Scripts/main.scpt" launcher.applescript
xattr -cr "$APP"
codesign -f -s - "$APP"     # adhoc 重签名,必须做
```

改启动器脚本后**每次都要** `xattr -cr` + `codesign -f -s -`,否则 macOS 报「已损坏」。

## 注意

- 该 WebRTC/时区 加固只覆盖 `com.google.Chrome`,**不含 Chrome for Testing**
  (`com.google.chrome.for.testing`,Playwright 用的),那条路不在加固范围。
- 以后管 Claude 账号,认准桌面「Claude Chrome」图标打开的窗口。

## 回退

- 启动器:恢复 `main.scpt` 备份后重新 `codesign -f -s -`。
- 日常 profile:把移走的 profile 目录挪回 `Google/Chrome/`,恢复 `Local State.bak`。
