# Dockerfile: 用于在容器内完整构建 OpenWrt 的基础环境
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# 常见编译依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc g++ binutils patch bzip2 gzip gawk gettext git subversion flex \
    curl unzip file libncurses5-dev zlib1g-dev libssl-dev python3-distutils python3 \
    python3-pip ca-certificates ccache rsync bzr make wget jq \
    && rm -rf /var/lib/apt/lists/*

# 安装 repo（非必须），和一些工具
RUN pip3 install --no-cache-dir ==

# 安装 gh CLI（用于 release 上传也可用）
RUN apt-get update && apt-get install -y --no-install-recommends gnupg2 dirmngr \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh

# 创建工作目录
WORKDIR /work

# 减小镜像层：清理apt缓存
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 默认 entrypoint（你也可以把脚本直接传入 docker run）
ENTRYPOINT ["/bin/bash", "-l", "-c"]