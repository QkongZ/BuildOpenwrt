#!/usr/bin/env bash
set -euo pipefail

# 用法: ./scripts/build-openwrt.sh <arch> <openwrt_tag> <out_dir>
# arch: x86_64 或 aarch64
ARCH="$1"
OPENWRT_TAG="$2"
OUT_DIR="$3"

echo "开始构建: ARCH=${ARCH}, OPENWRT_TAG=${OPENWRT_TAG}, OUT_DIR=${OUT_DIR}"

# 将构建目录放在 /work/openwrt-build
BUILD_DIR=/work/openwrt-build
SRC_DIR=${BUILD_DIR}/openwrt

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# 克隆官方源码（若已有则 fetch）
if [ -d "${SRC_DIR}" ]; then
  cd "${SRC_DIR}"
  git fetch --tags --prune
  git checkout ${OPENWRT_TAG} || git checkout -b build-${OPENWRT_TAG} ${OPENWRT_TAG}
else
  git clone --depth 1 --branch ${OPENWRT_TAG} https://github.com/openwrt/openwrt.git ${SRC_DIR}
  cd ${SRC_DIR}
fi

# 将仓库根目录的一些自定义配置/feeds 移入源码
# feeds.conf 默认路径是 feeds.conf.default，允许覆盖或追加
if [ -f /work/openwrt/feeds.conf ]; then
  echo "使用仓库中的 feeds.conf"
  cp /work/openwrt/feeds.conf feeds.conf
fi

# 覆盖或追加 package list（仓库中的 package-list.txt）
if [ -f /work/openwrt/package-list.txt ]; then
  echo "检测到 package-list.txt，脚本会尝试将这些包加入 .config 的 PACKAGE_SELECTED"
fi

# 如果提供了架构特定的 config 片段，则覆盖 .config
CONFIG_SRC="/work/openwrt/configs/${ARCH}.config"
if [ -f "${CONFIG_SRC}" ]; then
  echo "使用自定义 .config 片段: ${CONFIG_SRC}"
  cp "${CONFIG_SRC}" .config
else
  echo "未检测到 ${CONFIG_SRC}，将使用默认 defconfig (或你可以提供 configs/${ARCH}.config)"
fi

# 更新 feeds 并安装
./scripts/feeds update -a
./scripts/feeds install -a

# 向 .config 中添加 package-list（仅示例逻辑：把包设置为 y）
if [ -f /work/openwrt/package-list.txt ]; then
  while read -r pkg; do
    # 忽略注释和空行
    [[ "$pkg" =~ ^#.*$ ]] && continue
    [ -z "$pkg" ] && continue
    # 将包加入 .config（简单策略：CONFIG_PACKAGE_<pkg>=y）
    # 将包名中非法字符转换为下划线
    key="CONFIG_PACKAGE_$(echo "$pkg" | tr '+-/' '___' | tr '[:lower:]' '[:upper:]')=y"
    if ! grep -q "${key}" .config 2>/dev/null; then
      echo "${key}" >> .config
    fi
  done < /work/openwrt/package-list.txt
fi

# 若工作区含 files 目录（overlay），copy 到 openwrt/files
if [ -d /work/files ]; then
  echo "拷贝 overlay 文件以便 image 构建时包含默认配置"
  rm -rf files || true
  cp -a /work/files ./files
fi

# 执行 defconfig 合并并构建镜像
make defconfig

# 多核编译
NPROC=$(nproc || echo 2)
echo "开始 make (并行: ${NPROC}) ..."
# 按需修改 make 参数以节省时间或生成特定 image
make -j${NPROC} || ( echo "构建失败，查看上面日志" && exit 2 )

# 构建完毕，将 bin 目录下产物复制到 OUT_DIR
mkdir -p /work/${OUT_DIR}
cp -a bin/targets/* /work/${OUT_DIR}/ || true
# 也拷贝可用的基础映像
if [ -d bin/targets ]; then
  echo "构建成功，产物已复制到 /work/${OUT_DIR}"
else
  echo "警告：未发现 bin/targets 下的产物，请检查构建日志"
fi

echo "构建完成"