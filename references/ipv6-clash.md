# 第 6 点 · 关闭 IPv6(Clash Verge)

**为什么重要**:IPv6 常绕过代理直连,暴露你的真实 IPv6 地址,让「住宅 IP 伪装」前功尽弃。

## 关键坑

在这类机器上,用 **Merge / profile 写 `ipv6: false` 无效**——底座 / 内置增强会在最终阶段把它强制改回 `true`。
必须用**全局 Script** 在最终阶段覆盖。采用**三重保障**:运行时热改 + live 文件 + Script 持久化。

## 1) 持久化 —— 全局 Script.js(最终阶段运行,能覆盖)

编辑 `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js`,
在 `main(config)` 里加:

```js
function main(config) {
  config["ipv6"] = false;
  if (config["dns"]) { config["dns"]["ipv6"] = false; }
  return config;
}
```

> 若 `main` 已有内容,合并进去、保留原逻辑,最后仍 `return config`。改前先备份该文件。

## 2) 立即热生效(不重载代理、不断流)

通过 mihomo unix socket PATCH 运行时配置:

```bash
SOCK=/tmp/verge/verge-mihomo.sock
curl -s --unix-socket "$SOCK" -X PATCH http://localhost/configs -d '{"ipv6": false}'
```

## 3) 同步 live 文件(抗 mihomo 重启)

把生成的 `clash-verge.yaml` 里两处 `ipv6: true` 改成 `false`(全局一处、`dns` 一处)。

## 验证

```bash
curl -s --unix-socket /tmp/verge/verge-mihomo.sock http://localhost/configs \
  | /usr/bin/python3 -c 'import sys,json;print("ipv6=",json.load(sys.stdin).get("ipv6"))'
```
应输出 `ipv6= False`。

## 回退

恢复 `Script.js` 备份;PATCH 回 `{"ipv6": true}`;把 live 文件改回。
