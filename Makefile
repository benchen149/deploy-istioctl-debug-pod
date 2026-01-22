# ============================================================
# Variables (can be overridden via environment or CLI)
# ============================================================
ISTIO_CODE_VERSION ?= 1.24.0
IMAGE_VERSION      ?= 1.24.0-custom-v1
ISTIO_REPO         ?= https://github.com/istio/istio.git
BUILD_DIR          ?= /tmp/build
DOCKER_IMAGE       ?= istioctl-debug:$(IMAGE_VERSION)
USER               ?=
OWNER              ?=

.DEFAULT_GOAL := all

# ============================================================
# Version Check
# ============================================================
IMAGE_BASE_VERSION := $(word 1,$(subst -, ,$(IMAGE_VERSION)))

ifeq ($(ISTIO_CODE_VERSION),$(IMAGE_BASE_VERSION))
  # OK
else
  $(error ❌ Version mismatch: ISTIO_CODE_VERSION ($(ISTIO_CODE_VERSION)) != IMAGE_VERSION base ($(IMAGE_BASE_VERSION)))
endif

PATCH_ROOT_GO := patches/root.go
# Versions that require special root.go patch
# SPECIAL_ROOT_GO_VERSIONS := 1.13.5 1.14.3
SPECIAL_ROOT_GO_VERSIONS := 1.13.5


ifneq ($(filter $(ISTIO_CODE_VERSION),$(SPECIAL_ROOT_GO_VERSIONS)),)
PATCH_ROOT_GO := patches/root.go-$(ISTIO_CODE_VERSION)
endif

# ============================================================
# Phony Targets
# ============================================================
.PHONY: help all check-root check-tmp clone patch build image \
        switch-user mylab version clean

# ============================================================
# Help
# ============================================================
help:
	@echo "Makefile targets:"
	@echo "  make all            Build docker image and show version"
	@echo "  make clone          Clone/update Istio repo"
	@echo "  make patch          Apply local patches"
	@echo "  make build          Build istioctl binary"
	@echo "  make image          Build docker image (default)"
	@echo "  make switch-user    Re-run as another user (needs USER)"
	@echo "  make mylab          Internal build via mylab_cli (needs OWNER)"
	@echo "  make version        Show built image and cleanup binary"
	@echo "  make clean          Remove build artifacts"
	@echo ""
	@echo "Variables you can override: ISTIO_CODE_VERSION, IMAGE_VERSION, BUILD_DIR, DOCKER_IMAGE, USER, OWNER"

# ============================================================
# Root Check (提示，而不是直接阻斷)
# ============================================================
check-root:
	@if [ "$$(id -u)" -ne 0 ]; then \
	  echo "⚠️  Warning: not running as root. Some commands may fail (e.g., docker)."; \
	fi

# ============================================================
# Pre-checks
# ============================================================
check-tmp:
	@if [ ! -d /tmp ]; then \
	  echo "❌ Error: /tmp directory does not exist. Please create it first."; \
	  exit 1; \
	fi
	@echo "✅ /tmp exists."

# ============================================================
# Clone / Patch
# ============================================================
clone: check-tmp
	@if [ -d $(BUILD_DIR)/istio/.git ]; then \
	  echo "🔄 Updating Istio source at $(BUILD_DIR)/istio ..."; \
          echo "    ↳ target version: $(ISTIO_CODE_VERSION)"; \
          cd $(BUILD_DIR)/istio && \
	  git reset --hard HEAD && \
	  git fetch --all && \
	  echo "    ↳ switching to: $(ISTIO_CODE_VERSION)"; \
	  git checkout $(ISTIO_CODE_VERSION); \
	  git --no-pager log -1 --oneline; \
	else \
	  echo "⬇️  Cloning Istio repo into $(BUILD_DIR)/istio ..."; \
	  echo "    ↳ target version: $(ISTIO_CODE_VERSION)"; \
	  mkdir -p $(BUILD_DIR) && \
	  cd $(BUILD_DIR) && \
	  git clone $(ISTIO_REPO) istio && \
	  cd istio && git checkout $(ISTIO_CODE_VERSION); \
	  git --no-pager log -1 --oneline; \
	fi

patch:
	@if [ -d patches/debugtool ]; then \
	  echo "📂 Applying patches/debugtool ..."; \
	  mkdir -p $(BUILD_DIR)/istio/istioctl/cmd/debugtool; \
	  cp -r patches/debugtool/* $(BUILD_DIR)/istio/istioctl/cmd/debugtool/; \
	else \
	  echo "ℹ️  No patches/debugtool found, skipping..."; \
	fi
	@if [ -f patches/root.go ]; then \
	  echo "📂 Replacing istioctl/cmd/root.go ..."; \
	  echo "    ↳ source: $(PATCH_ROOT_GO)"; \
	  echo "    ↳ target: $(BUILD_DIR)/istio/istioctl/cmd/root.go"; \
	  cp $(PATCH_ROOT_GO) $(BUILD_DIR)/istio/istioctl/cmd/root.go; \
	else \
	  echo "ℹ️  No patches/root.go found, skipping..."; \
	fi

# ============================================================
# Build
# ============================================================
build: clone patch
	@echo "⚙️  Building istioctl ..."
	cd $(BUILD_DIR)/istio && make istioctl
	mkdir -p bin
	cp $(BUILD_DIR)/istio/out/linux_amd64/istioctl bin/istioctl
	@echo "✅ istioctl binary ready at bin/istioctl"

# ============================================================
# Docker image builds
# ============================================================
all: image version

image: build check-root
	@echo "🐳 Building docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) .

switch-user:
	@if [ -z "$(USER)" ]; then \
	  echo "❌ USER not defined. Run with 'make switch-user USER=<username>'"; \
	  exit 1; \
	fi
	sudo -u $(USER) bash -c "echo '🔄 Switching to user: $(USER)'; make mylab OWNER=$(USER)"

mylab: build
	@if [ -z "$(OWNER)" ]; then \
	  echo "❌ OWNER not defined. Run with 'make mylab OWNER=<ownername>'"; \
	  exit 1; \
	fi
	@echo "🚀 Running internal build for $(OWNER)/$(DOCKER_IMAGE)"
	/usr/local/mylab_cli/mylabbuild $(OWNER)/$(DOCKER_IMAGE)

# ============================================================
# Version / Cleanup
# ============================================================
version:
	@echo "✅ Built image: $(DOCKER_IMAGE)"
	@echo "🧹 Cleanup local bin/istioctl ..."
	rm -f bin/istioctl

clean:
	@echo "🧹 Cleaning up build dir and bin ..."
	rm -rf $(BUILD_DIR) bin
