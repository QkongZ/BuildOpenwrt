#!/usr/bin/env bash
set -euo pipefail

# 用法: ./scripts/dockerize-rootfs.sh <arch> <artifacts_dir> <image_name:tag>
ARCH="$1"
ART_DIR="$2"
IMAGE_NAME="${3:-openwrt-${ARCH}:latest}"

ROOT=$(pwd)
SRC_ROOTFS="${ROOT}/${ART_DIR}/docker/rootfs.tar.gz"

if [ ! -f "${SRC_ROOTFS}" ]; then
  echo "未找到 ${SRC_ROOTFS}，请先确保 build 脚本已生成 rootfs tar（见 artifacts）"
  exit 1
fi

# 创建临时目录来构建镜像上下文
TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

# 解压 rootfs 到上下文
mkdir -p "${TMPDIR}/rootfs"
tar -xzf "${SRC_ROOTFS}" -C "${TMPDIR}/rootfs"

# 将 Dockerfile（仓库中 docker/Dockerfile）与 rootfs 放入上下文
cp docker/Dockerfile "${TMPDIR}/Dockerfile"
# 把 rootfs 内容打包到 context 根下（Dockerfile 会 COPY rootfs 内容到 /）
cp -a "${TMPDIR}/rootfs/." "${TMPDIR}/rootfs_contents" || true

# 构建镜像（注：需要 Docker 在 runner 可用，GitHub Hosted runners 默认不允许 docker build 直接推镜像到 GHCR，需要额外权限）
tar -C "${TMPDIR}" -czf "${TMPDIR}/context.tar.gz" .
docker build -t "${IMAGE_NAME}" --build-arg ROOTFS=context/rootfs_contents -f "${TMPDIR}/Dockerfile" "${TMPDIR}" || {
  echo "docker build 失败，请在可用 docker 的环境执行脚本"
  exit 1
}

echo "Docker 镜像已构建: ${IMAGE_NAME}"