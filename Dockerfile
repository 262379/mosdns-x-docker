# ========================
# 构建阶段
# ========================
FROM golang:1.22-bookworm AS builder

ARG CGO_ENABLED=0
ARG TAG=dev
ARG REPOSITORY=pmkol/mosdns-x

WORKDIR /root

# 安装构建依赖
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates build-essential \
 && update-ca-certificates

# 克隆源码并编译
RUN echo "Building version: ${TAG} from repo: ${REPOSITORY}" \
 && git clone --depth 1 https://github.com/${REPOSITORY} mosdns \
 && cd mosdns \
 && git checkout main || true \
 && go mod tidy \
 && go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o mosdns \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ========================
# 运行阶段
# ========================
FROM debian:bookworm-slim

# 拷贝 mosdns 可执行文件
COPY --from=builder /root/mosdns/mosdns /usr/bin/

# 安装 Python3 相关和 ca-certificates
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      python3 \
      python3-venv \
      python3-pip \
 && mkdir /etc/mosdns \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# 挂载配置目录
VOLUME /etc/mosdns

# 暴露 DNS 端口
EXPOSE 53/udp 53/tcp

# 启动 mosdns
CMD ["/usr/bin/mosdns", "start", "--dir", "/etc/mosdns"]