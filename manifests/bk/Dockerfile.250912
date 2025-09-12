# istioctl-debug/Dockerfile

FROM alpine:3.18

#ARG ISTIO_VERSION=1.24.0
#ARG KUBECTL_VERSION=v1.28.0

# 安裝 bash 和 curl
RUN apk add --no-cache bash curl ca-certificates

# 安裝 kubectl
#RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
#    chmod +x kubectl && mv kubectl /usr/local/bin/

# 安裝 istioctl
#RUN curl -L "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-amd64.tar.gz" \
#    | tar xz && mv istioctl /usr/local/bin/

# 複製本機的 istioctl binary 到 image
COPY ./bin/1-24-0/istioctl /usr/local/bin/istioctl

# 預設進入 bash，方便互動
ENTRYPOINT ["/bin/bash"]

