FROM --platform=${TARGETPLATFORM} golang:1.22-bookworm as builder
ARG CGO_ENABLED=0
ARG TAG
ARG REPOSITORY=pmkol/mosdns-x

WORKDIR /root
RUN apt-get update && apt-get install -y --no-install-recommends git \
 && echo "Building version: ${TAG} from repo: ${REPOSITORY}" \
 && git clone --depth 1 https://github.com/${REPOSITORY} mosdns \
 && cd mosdns \
 && git checkout main || true \
 && go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o mosdns \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM --platform=${TARGETPLATFORM} debian:bookworm-slim
COPY --from=builder /root/mosdns/mosdns /usr/bin/

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      python3 \
      python3-venv \
      python3-pip \
 && mkdir /etc/mosdns \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

VOLUME /etc/mosdns
EXPOSE 53/udp 53/tcp
CMD ["/usr/bin/mosdns", "start", "--dir", "/etc/mosdns"]