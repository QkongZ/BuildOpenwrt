#!/bin/bash
#
# customize.sh - 编译前的自定义设置
#

# 1. 修改默认 IP 地址 (请修改为您需要的 IP)
# 对应 PVE 虚拟机的 LAN 口设置
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 2. 修改主机名
sed -i 's/OpenWrt/J4125-PVE/g' package/base-files/files/bin/config_generate

# 3. 设置默认时区为上海
sed -i "s/'UTC'/'CST-8'\n   set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

# 4. 默认开启 Wifi (J4125 + AX210)
# 注意：OpenWrt 默认首次安装 Wifi 是禁用的。这里尝试修改 mac80211 配置让其默认开启
# 但由于驱动加载顺序，最稳妥的方式是在 /etc/config/wireless 生成后修改，这里通过修改 triggers 实现
sed -i 's/disabled=1/disabled=0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 5. 修改默认主题 (确保已在 config 中选择 luci-theme-argon)
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 6. 设置 root 密码 (可选，安全性考虑建议 SSH 登录后修改)
# 下面示例设置密码为 password (生成后的固件默认密码)
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# 7. 调整 TTYD 终端为免登录 (可选)
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

echo "系统自定义设置完成"