# 构建阶段
FROM --platform=${TARGETPLATFORM} golang:1.21-bookworm as builder
ARG CGO_ENABLED=0
ARG TAG
ARG REPOSITORY=pmkol/mosdns-x

WORKDIR /root

# 安装 git
RUN apt-get update && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

# 克隆源码并构建
RUN echo "Building version: ${TAG} from repo: ${REPOSITORY}" \
 && git clone --depth 1 https://github.com/${REPOSITORY} mosdns \
 && cd mosdns \
 && git checkout main || true \
 && go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o mosdns

# 运行阶段
FROM --platform=${TARGETPLATFORM} debian:bookworm

# 安装 ca-certificates 和 Python3 环境
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-venv \
    python3-pip \
 && rm -rf /var/lib/apt/lists/*

# 拷贝可执行文件
COPY --from=builder /root/mosdns/mosdns /usr/bin/

# 配置目录与端口
RUN mkdir -p /etc/mosdns
VOLUME /etc/mosdns
EXPOSE 53/udp 53/tcp

# 默认启动命令
CMD ["/usr/bin/mosdns", "start", "--dir", "/etc/mosdns"]