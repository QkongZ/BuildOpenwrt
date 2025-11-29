#!/bin/bash
#
# feeds.sh - 添加第三方插件源
#

# 1. 官方源通常不需要动，默认 feeds.conf.default 已经包含

# 2. 添加常用的第三方源 (包含 Passwall, OpenClash, Argon 等)
# 使用 sed 命令追加到 feeds.conf.default 文件末尾

# 示例：添加 kenzok8 源 (非常全，包含您列表中的大部分代理和工具)
# 注意：官方源码可能与某些第三方源有依赖冲突，kenzok8 small 包通常兼容性较好
echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
echo 'src-git small https://github.com/kenzok8/small' >> feeds.conf.default

# 3. 添加 Docker 相关依赖 (如果官方源里版本过旧)
# echo 'src-git docker https://github.com/lisaac/luci-app-dockerman' >> feeds.conf.default

echo "自定义 Feeds 添加完成"