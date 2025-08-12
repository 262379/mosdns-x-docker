FROM --platform=${TARGETPLATFORM} golang:alpine as builder
ARG CGO_ENABLED=0
ARG TAG
ARG REPOSITORY=pmkol/mosdns-x

WORKDIR /root
RUN apk add --update git \
    && echo "Building version: ${TAG} from repo: ${REPOSITORY}" \
    # 尝试直接按 tag 克隆（速度快）
    && if git ls-remote --tags https://github.com/${REPOSITORY} | grep -q "refs/tags/${TAG}$"; then \
         echo "Tag ${TAG} found, cloning directly..."; \
         git clone --depth 1 --branch ${TAG} https://github.com/${REPOSITORY} mosdns; \
       else \
         echo "Tag ${TAG} not found by direct clone, fetching all tags..."; \
         git clone https://github.com/${REPOSITORY} mosdns && cd mosdns && git fetch --all --tags && git checkout "tags/${TAG}"; \
       fi \
    && cd mosdns \
    && go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o mosdns

FROM --platform=${TARGETPLATFORM} alpine:latest
COPY --from=builder /root/mosdns/mosdns /usr/bin/

RUN apk add --no-cache ca-certificates \
    && mkdir /etc/mosdns

VOLUME /etc/mosdns
EXPOSE 53/udp 53/tcp
CMD ["/usr/bin/mosdns", "start", "--dir", "/etc/mosdns"]
