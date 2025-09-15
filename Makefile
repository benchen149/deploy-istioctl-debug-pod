# === Variables ===
ISTIO_CODE_VERSION ?= 1.24.0
IMAGE_VERSION ?= 1.24.0-custom-v1
ISTIO_REPO    ?= https://github.com/istio/istio.git
BUILD_DIR     ?= /tmp/build
DOCKER_IMAGE  ?= istioctl-debug:$(IMAGE_VERSION)

.DEFAULT_GOAL := all   # Recommended to place here; it sets "all" as the default target when running just `make`

# === Targets ===

.PHONY: all clone patch build image version clean

all: image version

## Check /tmp exists
check-tmp:
	@if [ ! -d /tmp ]; then \
	  echo "❌ Error: /tmp directory does not exist. Please create it first."; \
	  exit 1; \
	else \
	  echo "✅ /tmp exists, continue..."; \
	fi

## Clone istio repo (skip if already exists)
clone: check-tmp
	@if [ -d $(BUILD_DIR)/istio/.git ]; then \
	  echo "🔄 Updating Istio source at $(BUILD_DIR)/istio ..."; \
	  cd $(BUILD_DIR)/istio && git fetch --all && git checkout $(ISTIO_CODE_VERSION); \
	else \
	  mkdir -p $(BUILD_DIR) && \
	  cd $(BUILD_DIR) && \
	  git clone $(ISTIO_REPO) istio && \
	  cd istio && git checkout $(ISTIO_CODE_VERSION); \
	fi

## Apply custom code (copy from patches/)
patch:
	@if [ -d patches/debugtool ]; then \
	  echo "Applying custom patches to istioctl/cmd/debugtool ..."; \
	  mkdir -p $(BUILD_DIR)/istio/istioctl/cmd/debugtool; \
	  cp -r patches/debugtool/* $(BUILD_DIR)/istio/istioctl/cmd/debugtool/; \
	else \
	  echo "No patches/debugtool directory found, skipping..."; \
	fi

	@if [ -f patches/root.go ]; then \
	  echo "Replacing istioctl/cmd/root.go with custom version ..."; \
	  cp patches/root.go $(BUILD_DIR)/istio/istioctl/cmd/root.go; \
	else \
	  echo "No patches/root.go found, skipping root.go replacement..."; \
	fi

## Build istioctl binary
build: clone patch
	cd $(BUILD_DIR)/istio && make istioctl
	mkdir -p bin
	cp $(BUILD_DIR)/istio/out/linux_amd64/istioctl bin/istioctl

## Build docker image - default
image: build
	docker build -t $(DOCKER_IMAGE) .

## Build docker image - Internal build
internal: build
	mylabbuild || $(MAKE) clean

## Print version
version:
	@echo "Built image: $(DOCKER_IMAGE)"
	@echo "Cleanup local bin/istioctl ..."
	rm -f bin/istioctl

## Cleanup
clean:
	rm -rf $(BUILD_DIR) bin
