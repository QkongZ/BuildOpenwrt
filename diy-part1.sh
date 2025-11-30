#!/bin/bash
# DIY Part 1: Feeds

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add Custom Feeds
cat >> feeds.conf.default <<EOF
src-git small https://github.com/kenzok8/small
src-git kenzo https://github.com/kenzok8/openwrt-packages
EOF
