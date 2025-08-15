FROM --platform=${TARGETPLATFORM} golang:alpine as builder
ARG CGO_ENABLED=0
ARG TAG
ARG REPOSITORY=pmkol/mosdns-x

WORKDIR /root
RUN apk add --no-cache git \
&& echo "Building version: ${TAG} from repo: ${REPOSITORY}" \
&& git clone --depth 1 https://github.com/${REPOSITORY} mosdns \
&& cd mosdns \
&& git checkout main || true \
&& go build -ldflags "-s -w -X main.version=${TAG}" -trimpath -o mosdns

FROM --platform=${TARGETPLATFORM} alpine:latest
COPY --from=builder /root/mosdns/mosdns /usr/bin/

RUN apk add --no-cache ca-certificates \
&& mkdir /etc/mosdns

VOLUME /etc/mosdns
EXPOSE 53/udp 53/tcp
CMD ["/usr/bin/mosdns", "start", "--dir", "/etc/mosdns"]


