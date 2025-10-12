# Dockerfile（用于把 OpenWrt rootfs 放进容器以便运行 OpenWrt 用户空间）
# 用法示例：
#   docker build -t openwrt-run:latest --build-arg ROOTFS=./rootfs_contents .
#
# 注意：
# - 该镜像基于 Ubuntu/Alpine 只是为了简单示例；OpenWrt 使用自己的 init (procd)，
#   在容器中能否完全工作取决于内核和所需功能（例如某些内核模块、网络命名空间、无线驱动等在容器中不可用）。
# - 运行此镜像时通常需要额外的特权和绑定主机网络，例如 --privileged 或 --cap-add=NET_ADMIN 以及 --network host。
FROM ubuntu:22.04

ARG ROOTFS=./rootfs_contents

# 安装必要工具（可根据需要移除以减小镜像）
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates dbus procps iproute2 iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# 将 rootfs 内容拷贝到容器根
COPY ${ROOTFS}/ / 

# 默认使用 OpenWrt 的 init（通常为 /sbin/init 或 /sbin/procd）
# 如果不存在，可以以 /bin/sh 启动用于调试
ENTRYPOINT ["/sbin/init"]
CMD ["/bin/sh"]