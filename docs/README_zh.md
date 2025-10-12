```markdown
# OpenWrt 自动构建与 Docker 运行镜像说明（中文）

更新要点：
- 构建在 Actions runner（./scripts/build-openwrt.sh）上执行，不再把构建过程放进仓库 Dockerfile 中。
- Dockerfile (docker/Dockerfile) 用于把已编译的 OpenWrt rootfs 打包成可运行的容器镜像（适用于测试/服务容器），而不是用于执行编译。
- scripts/dockerize-rootfs.sh 提供了一个示例流程：把 artifacts 中的 rootfs.tar.gz 解压/放入上下文并构建 Docker 镜像。

重要警告：
- 容器运行的 OpenWrt 受限于宿主机内核与权限：无线驱动、某些内核模块和真实硬件功能在容器中不可用。若目标是发布固件到路由器，请直接使用构建出的固件/镜像并刷机。
- 若你需要在 Actions 中构建并推送 Docker 镜像到 registry，请确保 runner 有 docker 权限、并且在仓库 secrets 中配置了相应凭据。

包清单：
- 我已把你提供的包清单放入 openwrt/package-list.txt（保留中文注释）。

触发方式：
- push 到 main、手动 workflow_dispatch、每日 schedule（与 openwrt 官方 release 检查并在版本更新时构建）。

如需我进一步帮你：
- 针对某个具体目标设备（profile）生成 .config（我可以基于设备型号生成更精确的配置）。
- 把 dockerize 的过程集成进工作流（例如在有 docker 权限 runner 上自动构建并推送镜像）。
- 帮你把 package 名称与 feeds 对应关系校验并修正可能的包名差异（有些 luci 插件在不同 feed 下包名可能不同）。
```