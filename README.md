#### Prerequisites
```
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-amd64
wget "https://github.com/istio/istio/releases/download/1.24.0/istio-1.24.0-linux-amd64.tar.gz" -O - | tar -xz
wget -qO- https://github.com/open-cluster-management-io/clusteradm/releases/latest/download/clusteradm_linux_amd64.tar.gz | sudo tar -xvz -C /usr/local/bin/

```
---
#### Directory Structure
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

#### Build Image Workflow

The Makefile automates the process of building a custom istioctl binary and packaging it into a Docker image.

Targets Overview (Quick Reference)

| Target / Command  | Description                                                                                                      |
| ----------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Version Check** | Ensures `ISTIO_CODE_VERSION` matches the base version of `IMAGE_VERSION`; otherwise, `make` stops with an error. |
| `make` (default)  | Runs `all`, which triggers `image` (build Docker image) and `version` (print info & cleanup).                    |
| `make build`      | Compiles `istioctl` from source after cloning and applying patches.                                              |
| `make image`      | Builds the Docker image with the compiled binary.                                                                |
| `make mylab`        | Runs a custom lab build command (falls back to `make clean` on failure).                                |
| `make clean`      | Removes build artifacts (`/tmp/build` and `bin/`).                                                               |

---
#### Usage Examples

Below is an example workflow to build the custom `istioctl` image, load it into a Kind cluster, and run the `debugtool` command.

##### 1. Build the image
```
- make or make all 
- make mylab or  make mylab USER=<USER> OWNER=<owner>
```

##### 2. Load the image into Kind
```
kind load docker-image istioctl-debug:1.24.0-custom-v1 --name hub
```

##### 3. Deploy the debug pod
```
kubectl apply -f rbac-istioctl-min-read.yaml
kubectl apply -f manifests/deploy.yaml
```

##### 4. Run istioctl debugtool
```
Exec into the pod or run directly inside the container:
From Kubernetes pod
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod>

Save debug info to a file
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod> -o /tmp/debug-info
```

##### 5. Run locally with Docker (without Kubernetes)
```
docker run --rm -it --entrypoint /bin/sh istioctl-debug:<IMAGE_VERSION>
istioctl debugtool
```

---

#### Others
```
kind load docker-image istioctl-debug:<IMAGE_VERSION> --name c1
istioctl debugtool default <pod>
istioctl debugtool default <pod> -o /tmp/debug-info
docker run --rm -it --entrypoint /bin/sh istioctl-debug:<IMAGE_VERSION>
kind load docker-image istioctl-debug:<IMAGE_VERSION> --name <kind-cluster>

```
