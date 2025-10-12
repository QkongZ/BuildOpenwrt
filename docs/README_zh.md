```markdown
# OpenWrt 自动构建（GitHub Actions）说明（中文）

说明：
- 该仓库包含一个 GitHub Actions 工作流，用于在 GitHub 上自动编译 OpenWrt（官方源码）。
- 支持架构：x86_64（amd64）、aarch64（arm64）。
- 构建在 Docker 容器内进行（docker/Dockerfile），并在完成后将产物上传到 GitHub Releases（按 OpenWrt 版本创建 Release）。

主要路径说明：
- .github/workflows/build-openwrt.yml：Actions 工作流（触发方式：push 到 main、手动 dispatch、每日定时检查官方 release 并在版本更新时构建）。
- docker/Dockerfile：构建环境镜像。
- scripts/build-openwrt.sh：实际在容器内运行的构建脚本。
- openwrt/feeds.conf：自定义 feeds（可编辑并添加第三方源）。
- openwrt/package-list.txt：要安装的包清单（每行一个包名，支持注释 #）。
- openwrt/configs/：两个示例的 .config 片段（x86_64.config、aarch64.config），可按需修改。
- files/：overlay（rootfs overlay），可以放置默认的 /etc/config/* 等以设置默认网络、无线、web/ssh 等配置（示例文件见仓库）。
- openwrt/LAST_OPENWRT_TAG：定时检查触发构建后会更新此文件用来记录已构建的上次版本（仅在 schedule 触发时自动提交）。

如何自定义（建议）：
1. 编辑 openwrt/feeds.conf，添加/删除第三方 feeds。
2. 编辑 openwrt/package-list.txt，添加你想要默认编译入固件的包（示例清单见下）。
3. 在 openwrt/configs/ 下创建或修改 <arch>.config（例如 x86_64.config），可以在 .config 中使用注释以中文说明。构建脚本会将其直接复制为 .config 并执行 make defconfig -> make。
4. 在 files/ 下添加 UCI 配置文件覆盖（例如 files/etc/config/network、files/etc/config/wireless、files/etc/config/dropbear），以设置开机默认值（注意：不要将密钥或密码直接放在仓库中）。

示例插件清单（openwrt/package-list.txt 示例）：
- luci
- luci-ssl
- openssh-sftp-server
- htop
- iptables-mod-tproxy
- kmod-sched-cake
- luci-app-adblock
- luci-app-openvpn
- vpn-policy-routing
- mwan3

第三方插件源示例（openwrt/feeds.conf 格式示例）：
- src-git lienol https://github.com/Lienol/openwrt-package
- src-git vcs https://github.com/someuser/some-openwrt-feed.git

默认配置模板（示例文件位于 files/，含中文注释）：
- files/etc/config/network：默认 LAN/WAN 分区与静态 IP 或 DHCP。
- files/etc/config/system：启用/关闭某些系统服务、设置时区等。
- files/etc/config/dropbear：默认 ssh 监听 IP/端口（请勿放置密码/私钥）。

常见注意事项：
- OpenWrt 编译需要较多磁盘和内存（建议 8GB+ 内存，100GB 磁盘空间用于完整构建）。GitHub Actions Hosted runner 资源有限，可能导致超时/内存不足，建议：
  - 使用 self-hosted runner（有足够资源）
  - 或在 Dockerfile 内减少并行度（修改 scripts/build-openwrt.sh 的 make -j 参数）
- 若你需要签名或加入私有 feed（需要凭据），请不要把凭据放在仓库，应使用 Actions secrets 并在构建脚本内部注入（脚本示例目前不包含 secret 处理）。
- 如果需要按某一官方分支（比如 openwrt-23.05）持续构建，工作流会每天检查 openwrt/openwrt 的最新 release tag 并在变化时触发构建；也可以手动触发。

如果你愿意，我可以：
- 根据你目标设备/平台（你可以告诉我设备型号或需要的 profile）帮你微调 configs 下的 .config 片段与 PROFILE 设置。
- 增加更细化的构建步骤（比如按 profile 单独构建 iso/combined-squashfs 等）。
```