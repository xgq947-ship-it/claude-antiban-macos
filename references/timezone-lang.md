# 第 7 点 · 时区 / 语言伪装为出口 IP 所在地

**为什么最致命**:「美国住宅 IP + 中国时区 + 中文系统」自相矛盾,风控一眼识别。目标是让浏览器里的
时区 / 语言与出口 IP 一致(示例:美东 → `America/New_York` + `en-US`)。

**做法**:不改整台 macOS 系统,而是**只给 Claude 用的那个隔离浏览器进程**注入环境变量与参数。
这样干净、可控、不影响日常。具体在启动器里做,见 `references/isolation.md`。

## 两个关键点

- **时区** 靠环境变量 `TZ`:
  ```
  TZ='America/New_York'
  ```
  Chrome 走 ICU 读 `TZ`,最干净、全栈一致(`Date`、`Intl`、页面显示都跟着变)。
  注意:必须**直起 Chrome 二进制**并带上该环境变量;`open` 命令不传环境变量,所以不能用 `open`。

- **语言** 靠 `--accept-lang`(不是 `--lang`):
  ```
  --accept-lang='en-US,en'
  ```
  macOS 上 Chrome **忽略 `--lang`**。`--accept-lang` 同时改 `navigator.language/languages` 和
  HTTP `Accept-Language` 头。

## 目标地区对照(按需替换)

| 出口地区 | TZ | accept-lang |
|----------|----|-------------|
| 美东 | `America/New_York` | `en-US,en` |
| 美西 | `America/Los_Angeles` | `en-US,en` |
| 英国 | `Europe/London` | `en-GB,en` |
| 日本 | `Asia/Tokyo` | `ja-JP,ja,en` |

**务必与出口 IP 的实际归属一致**——先用 `ipinfo.io` 确认 IP 在哪,再选对应时区/语言。

## 验证

在隔离窗口打开 `browserleaks.com/javascript` 或 whoer.net,应显示目标时区与语言
(如 `timezone=America/New_York`、`language=en-US`、`GMT-0400 (EDT)`)。
