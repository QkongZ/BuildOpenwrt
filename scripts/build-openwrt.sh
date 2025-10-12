#!/usr/bin/env bash
set -euo pipefail

# 用法: ./scripts/build-openwrt.sh <arch> <openwrt_tag> <out_dir>
ARCH="$1"
OPENWRT_TAG="$2"
OUT_DIR="$3"

echo "开始构建: ARCH=${ARCH}, OPENWRT_TAG=${OPENWRT_TAG}, OUT_DIR=${OUT_DIR}"

ROOT=$(pwd)
BUILD_DIR=${ROOT}/build/openwrt-src
SRC_DIR=${BUILD_DIR}/openwrt

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# clone or fetch official openwrt
if [ -d "${SRC_DIR}/.git" ]; then
  cd "${SRC_DIR}"
  git fetch --tags --prune
  git checkout "${OPENWRT_TAG}" || git checkout -b build-${OPENWRT_TAG} "${OPENWRT_TAG}"
else
  git clone --depth 1 --branch "${OPENWRT_TAG}" https://github.com/openwrt/openwrt.git "${SRC_DIR}"
  cd "${SRC_DIR}"
fi

# 使用仓库中的 feeds.conf（若存在）
if [ -f "${ROOT}/openwrt/feeds.conf" ]; then
  echo "使用仓库 openwrt/feeds.conf"
  cp "${ROOT}/openwrt/feeds.conf" feeds.conf
fi

# 拷贝 overlay files（若有）
if [ -d "${ROOT}/files" ]; then
  echo "拷贝 overlay files 到源码目录"
  rm -rf files || true
  cp -a "${ROOT}/files" "${SRC_DIR}/"
fi

# 如果有 configs/{arch}.config 则复制为 .config
CONFIG_SRC="${ROOT}/openwrt/configs/${ARCH}.config"
if [ -f "${CONFIG_SRC}" ]; then
  echo "使用自定义 config 片段: ${CONFIG_SRC}"
  cp "${CONFIG_SRC}" .config
fi

# 更新 feeds 并安装
./scripts/feeds update -a
./scripts/feeds install -a

# 若仓库根有 package-list.txt，则把包加入 .config（尝试简单启用）
if [ -f "${ROOT}/openwrt/package-list.txt" ]; then
  echo "处理 package-list.txt"
  while IFS= read -r pkg || [ -n "$pkg" ]; do
    [[ "$pkg" =~ ^#.*$ ]] && continue
    [ -z "$pkg" ] && continue
    # 包含注释后面带说明的行，取首个字段为包名
    name=$(echo "$pkg" | awk '{print $1}')
    # 生成 CONFIG_PACKAGE_<NAME>=y
    key="CONFIG_PACKAGE_$(echo "$name" | tr '+-/' '___' | tr '[:lower:]' '[:upper:]')=y"
    if ! grep -q "^${key}$" .config 2>/dev/null; then
      echo "${key}" >> .config || true
    fi
  done < "${ROOT}/openwrt/package-list.txt"
fi

# 复制 overlay files（如果之前未复制）
if [ -d "${ROOT}/files" ]; then
  rm -rf files || true
  cp -a "${ROOT}/files" .
fi

# 执行 defconfig 合并并构建
make defconfig

# 并行度（可按需调整）
NPROC=$(nproc || echo 2)
echo "开始 make -j${NPROC} ..."
make -j"${NPROC}" || { echo "构建失败"; exit 2; }

# 复制 bin 产物
mkdir -p "${ROOT}/${OUT_DIR}"
# 复制所有 bin/targets 下的产物到输出目录
if [ -d bin/targets ]; then
  cp -a bin/targets/* "${ROOT}/${OUT_DIR}/" || true
fi

# 尝试找到 rootfs tarball（openwrt 有时会生成 rootfs.tar.gz）
ROOTFS_TAR=$(find bin/targets -type f -name '*rootfs*.tar*' | head -n1 || true)
if [ -n "$ROOTFS_TAR" ]; then
  echo "找到 rootfs tar: $ROOTFS_TAR"
  mkdir -p "${ROOT}/${OUT_DIR}/docker"
  cp "$ROOTFS_TAR" "${ROOT}/${OUT_DIR}/docker/rootfs.tar.gz"
else
  # 尝试从 staging_dir 做一个 rootfs 打包
  STAGING_ROOT=$(find staging_dir -maxdepth 3 -type d -name 'root-*' | head -n1 || true)
  if [ -n "$STAGING_ROOT" ]; then
    echo "从 staging_dir 打包 rootfs: $STAGING_ROOT"
    mkdir -p "${ROOT}/${OUT_DIR}/docker"
    tar -C "$STAGING_ROOT" -czf "${ROOT}/${OUT_DIR}/docker/rootfs.tar.gz" . || true
  else
    echo "未找到可直接打包的 rootfs 文件，docker rootfs tar 未生成"
  fi
fi

echo "构建完成，产物位于 ${ROOT}/${OUT_DIR}"