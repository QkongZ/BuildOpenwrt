#!/bin/bash
#
# customize.sh - 编译前的自定义设置
#

# 1. IP 设置
# 注意：由于您已上传了 files/etc/config/network，IP 设置将由该文件接管
# 因此这里不需要再用 sed 修改 IP

# 2. 修改主机名
sed -i 's/OpenWrt/J4125-PVE/g' package/base-files/files/bin/config_generate

# 3. 设置默认时区为上海
sed -i "s/'UTC'/'CST-8'\n   set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

# 4. 默认开启 Wifi (J4125 + AX210)
# 尝试修改 mac80211 配置让其默认开启 (disabled=0)
sed -i 's/disabled=1/disabled=0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 5. 修改默认主题 (确保已在 config 中选择 luci-theme-argon)
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 6. 设置 Docker 相关的防火墙转发 (防止容器网络不通)
# OpenWrt 新版防火墙通常使用 nftables，Docker 可能需要 iptables-nft 兼容
# 这里添加一行确保转发默认允许 (可选，视具体情况)
# sed -i '/config defaults/a \\toption forward "ACCEPT"' package/network/config/firewall/files/firewall.config

echo "系统自定义设置完成 (Network config injected via 'files/' directory)"