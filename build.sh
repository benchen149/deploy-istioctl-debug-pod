#!/bin/bash
# istioctl-debug/build.sh

set -e

IMAGE_NAME=istioctl-debug:1.24.0

echo "🔧 Building Docker image: $IMAGE_NAME"
docker build -f Dockerfile -t $IMAGE_NAME .
echo "✅ Build complete."

kind load docker-image istioctl-debug:1.24.0 --name c1

