# Istioctl Debug Pod

A lightweight debugging environment that builds a **custom `istioctl` binary** (with `debugtool` extension) and packages it into a Docker image, deployable as a pod inside Kubernetes or runnable locally with Docker.

---

## Prerequisites

Before using this project, ensure you have the following tools installed:

- **Docker** (build and run local images)
- **kubectl** (to interact with Kubernetes clusters)
- **kind** (optional, for local multi-cluster testing)
- **git** (for fetching Istio source)

```
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-amd64
wget "https://github.com/istio/istio/releases/download/1.24.0/istio-1.24.0-linux-amd64.tar.gz" -O - | tar -xz
wget -qO- https://github.com/open-cluster-management-io/clusteradm/releases/latest/download/clusteradm_linux_amd64.tar.gz | sudo tar -xvz -C /usr/local/bin/

```
---

# Directory Structure
```
deploy-istioctl-debug-pod/
├── bin                          # Compiled istioctl binary (output after build)
├── Dockerfile                   # Dockerfile for packaging istioctl into a debug image
├── Makefile                     # Build automation (clone, patch, build, image, version, clean)
├── manifests                    # Kubernetes manifests for deploying istioctl-debug pod│  
│   ├── deploy.yaml              # Current deployment manifest for istioctl-debug pod
│   └── rbac-istioctl-min-read.yaml # Minimal RBAC for read-only istioctl usage
├── patches                      # Custom patches copied into Istio source before build
│   ├── debugtool                # Custom debugtool command (to extend istioctl CLI)
│   │   └── debugtool.go
│   └── root.go                  # Patched root.go to register the debugtool command
├── README.md                    # Project documentation and usage instructions
└── src                          # Source code directory for additional tooling/modules
```
---

# Build Image Workflow

The Makefile automates the process of building a custom istioctl binary and packaging it into a Docker image.

Targets Overview (Quick Reference)

| Target / Command    | Description                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------- |
| **Version Check**   | Ensures `ISTIO_CODE_VERSION` matches the base version of `IMAGE_VERSION`; otherwise, build stops. |
| `make` / `make all` | Default: runs `image` (build Docker image) + `version` (print info & cleanup).                    |
| `make clone`        | Clone or update the Istio repo at `$(BUILD_DIR)` and checkout `ISTIO_CODE_VERSION`.               |
| `make patch`        | Apply local patches (copy `debugtool` sources and replace `root.go`).                             |
| `make build`        | Compile `istioctl` from source after cloning and applying patches.                                |
| `make image`        | Build Docker image with the compiled binary.                                                      |
| `make switch-user`  | Re-run the build as another Linux user (requires `USER=<username>`).                              |
| `make mylab`        | Run a custom **mylab\_cli** build (requires `OWNER=<owner>`).                                     |
| `make version`      | Print built image tag and cleanup temporary `bin/istioctl`.                                       |
| `make clean`        | Remove build artifacts (`$(BUILD_DIR)` and `./bin`).                                              |
| `make help`         | Show detailed usage instructions and common workflows.                                            |


---
# Usage Examples

Below is an example workflow to build the custom `istioctl` image, load it into a Kind cluster, and run the `debugtool` command.

## 1. Build the image
```
make                 # Build docker image (default)
make all             # Same as 'make'
make mylab OWNER=me  # Internal mylab build

```

## 2. Load the image into Kind
```
kind load docker-image istioctl-debug:1.24.0-custom-v1 --name hub
```

## 3. Deploy the debug pod to Kubernetes
```
kubectl apply -f rbac-istioctl-min-read.yaml
kubectl apply -f manifests/deploy.yaml
```

## 4. Run istioctl debugtool inside the pod
```
# Exec into the pod
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod>

# Save debug info to a file
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod> -o /tmp/debug-info

```

## 5. Run locally with Docker (no Kubernetes)
```
docker run --rm -it --entrypoint /bin/sh istioctl-debug:1.24.0-custom-v1
istioctl debugtool

```

---

# Others
```
# Load image into another Kind cluster
kind load docker-image istioctl-debug:<IMAGE_VERSION> --name <kind-cluster>

# Run debugtool against a pod
istioctl debugtool default <pod>
istioctl debugtool default <pod> -o /tmp/debug-info

```

# Tips
- Always ensure ISTIO_CODE_VERSION and IMAGE_VERSION are aligned (the Makefile enforces this).

- Use make help to see available targets and quick usage hints.

- For internal builds (make mylab), remember to set OWNER=<your-dockerhub-org>.

- AI-assisted development and optimization were applied to this project using GPT technologies.
