# Istioctl Debug Pod

A lightweight debugging environment that builds a **custom `istioctl` binary** (with `debugtool` extension) and packages it into a Docker image, deployable as a pod inside Kubernetes or runnable locally with Docker.

---

## Prerequisites

Before using this project, ensure you have the following tools installed:

- **Docker** (build and run local images)
- **kubectl** (to interact with Kubernetes clusters)
- **kind** (optional, for local multi-cluster testing)
- **git** (for fetching Istio source)

```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-amd64
wget "https://github.com/istio/istio/releases/download/1.29.2/istio-1.29.2-linux-amd64.tar.gz" -O - | tar -xz
wget -qO- https://github.com/open-cluster-management-io/clusteradm/releases/latest/download/clusteradm_linux_amd64.tar.gz | sudo tar -xvz -C /usr/local/bin/
```

---

# Directory Structure
```
deploy-istioctl-debug-pod/
├── bin                          # Compiled istioctl binary (output after build)
├── Dockerfile                   # Dockerfile for packaging istioctl into a debug image
├── Makefile                     # Build automation (clone, patch, build, image, version, clean)
├── manifests                    # Kubernetes manifests for deploying istioctl-debug pod
│   ├── deploy.yaml              # Current deployment manifest for istioctl-debug pod
│   └── clusterrole-istioctl-debug-limited-readonly.yml  # Minimal RBAC for read-only istioctl usage
├── patches                      # Custom patches copied into Istio source before build
│   ├── debugtool                # Custom debugtool command (to extend istioctl CLI)
│   │   └── debugtool.go
│   └── root.go                  # Patched root.go to register the debugtool command
├── .claude/commands
│   ├── github-flow.md           # Claude slash command for GitHub flow automation
│   └── setup-github-ssh.md      # Claude slash command for SSH and gh CLI initial setup
└── README.md                    # Project documentation and usage instructions
```

---

# Supported Versions

| Istio Version | Build Tested | `root.go` Patch | `debugtool` Patch | Notes |
| ------------- | ------------ | --------------- | ----------------- | ----- |
| **1.29.2**    | ✅           | ✅ 相容         | ✅ 相容           | 目前預設版本 |
| 1.24.0        | ✅           | ✅ 相容         | ✅ 相容           | 與 1.29.2 root.go 完全相同 |
| 1.13.5        | ✅           | 使用 `patches/root.go-1.13.5` | ✅ 相容 | 需指定特定 root.go patch |

> `patches/root.go` 與 `patches/debugtool/debugtool.go` 對 1.24.x 和 1.29.x 完全相容，
> 因為兩版本的 `root.go` 結構相同，且 `debugtool` 不依賴任何 Istio SDK，只使用 stdlib 與 cobra。

---

# Build Image Workflow

The Makefile automates the process of building a custom istioctl binary and packaging it into a Docker image.

Targets Overview (Quick Reference)

| Target / Command    | Description                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------- |
| **Version Check**   | Ensures `ISTIO_CODE_VERSION` matches the base version of `OUTPUT_IMAGE_VERSION`; otherwise, build stops. |
| `make` / `make all` | Default: runs `image` (build Docker image) + `version` (print info & cleanup).                    |
| `make clone`        | Clone or update the Istio repo at `$(BUILD_DIR)` and checkout `ISTIO_CODE_VERSION`.               |
| `make patch`        | Apply local patches (copy `debugtool` sources and replace `root.go`).                             |
| `make build`        | Compile `istioctl` from source after cloning and applying patches.                                |
| `make image`        | Build Docker image with the compiled binary. Optionally bundle extra files via `EXTRA_FILES_DIR`. |
| `make image EXTRA_FILES_DIR=<file\|dir>` | Bundle additional files (single file or directory) into `/usr/local/bin/` in the image. |
| `make switch-user`  | Re-run the build as another Linux user (requires `RUN_AS_USER=<username>`).                       |
| `make mylab`        | Run a custom **mylab\_cli** build (requires `OWNER=<owner>`).                                     |
| `make version`      | Print built image tag and cleanup temporary `bin/istioctl`.                                       |
| `make clean`        | Remove build artifacts (`$(BUILD_DIR)` and `./bin`).                                              |
| `make help`         | Show detailed usage instructions and common workflows.                                            |


---
# Usage Examples

Below is an example workflow to build the custom `istioctl` image, load it into a Kind cluster, and run the `debugtool` command.

## 1. Build the image
```bash
make                 # Build docker image (default)
make all             # Same as 'make'
make mylab OWNER=me  # Internal mylab build

# Build a specific version
make ISTIO_CODE_VERSION=1.13.5 OUTPUT_IMAGE_VERSION=1.13.5-custom-v1
```

## 2. Load the image into Kind
```bash
kind load docker-image istioctl-debug:<OUTPUT_IMAGE_VERSION> --name hub
```

## 3. Deploy the debug pod to Kubernetes
```bash
kubectl apply -f manifests/clusterrole-istioctl-debug-limited-readonly.yml
kubectl apply -f manifests/deploy.yaml

# 確認 pod 已 Ready
kubectl rollout status deploy/istioctl-debug -n default
```

## 4. Run istioctl debugtool inside the pod
```bash
# 確認 binary 版本與 debugtool 是否正確載入
kubectl exec -it deploy/istioctl-debug -n default -- istioctl version
kubectl exec -it deploy/istioctl-debug -n default -- istioctl --help | grep debugtool

# Exec into the pod
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod>

# Save debug info to a file
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod> -o /tmp/debug-info
```

## 5. Run locally with Docker (no Kubernetes)
```bash
docker run --rm -it --entrypoint /bin/sh istioctl-debug:<OUTPUT_IMAGE_VERSION>
istioctl version
istioctl --help | grep debugtool
istioctl debugtool
```

---

# Branch Strategy

| Branch | 用途 |
| ------ | ---- |
| `main` | 穩定版本，只接受來自 `1-feat-new-branch-for-develop-and-test` 的 PR merge |
| `1-feat-new-branch-for-develop-and-test` | 主要開發 branch，功能開發從此 branch 切出 |

---

# Claude Commands

本專案提供 Claude Code slash commands，統一開發環境設定與開發流程。

| Command | 說明 |
| ------- | ---- |
| `/setup-github-ssh` | 新環境一次性設定：SSH key 產生、GitHub 綁定、gh CLI 登入（含安全規範） |
| `/github-flow` | 完整開發流程：issue → branch → PR → merge，或批次關閉 PR / Issue |

**建議順序（新環境第一次）：**
```
1. /setup-github-ssh   # 完成 SSH + gh CLI 認證設定
2. /github-flow        # 開始功能開發
```

詳見 [`.claude/commands/`](.claude/commands/) 目錄下的對應 `.md` 檔案。

---

# Quick Reference
```bash
# Load image into another Kind cluster
kind load docker-image istioctl-debug:<OUTPUT_IMAGE_VERSION> --name <kind-cluster>

# Check built images
docker images | grep istioctl-debug

# Remove old image
docker rmi istioctl-debug:<OUTPUT_IMAGE_VERSION>

# Run debugtool against a pod
istioctl debugtool default <pod>
istioctl debugtool default <pod> -o /tmp/debug-info

# Rollback all local changes
git restore .
```

# Tips
- Always ensure `ISTIO_CODE_VERSION` and `OUTPUT_IMAGE_VERSION` are aligned (the Makefile enforces this). `OUTPUT_IMAGE_VERSION` format must be `{version}-{label}`, e.g. `1.24.0-custom-v1`.
- Use `make help` to see available targets and quick usage hints.
- For internal builds (`make mylab`), remember to set `OWNER=<your-org>`.
- For non-root builds, use `make switch-user RUN_AS_USER=<username>`.
- If build fails with `permission denied on /gocache`, run: `docker volume rm gocache`.
- To include extra tools in the image, use `make image EXTRA_FILES_DIR=<file-or-dir>`. Files land in `/usr/local/bin/` inside the container.
- `/github-flow` requires `gh` CLI login（執行 `/setup-github-ssh` 完成初始設定）with Contents / Issues / Pull requests read & write permissions.
