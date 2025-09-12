FROM alpine:3.18

# 安裝 bash 和 curl
RUN apk add --no-cache bash curl ca-certificates

WORKDIR /usr/local/bin
COPY bin/istioctl .
RUN chmod +x istioctl

# 預設進入 bash，方便互動
ENTRYPOINT ["/bin/bash"]

