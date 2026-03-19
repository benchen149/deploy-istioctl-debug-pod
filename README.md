# Istioctl Debug Pod

A lightweight debugging environment that builds a **custom `istioctl` binary** (with the `debugtool` extension) and packages it into a Docker image. You can run it:

- **locally** with Docker for quick validation
- **inside Kubernetes** as a debug pod
- **against a local Kind cluster** for end-to-end testing

---

## Prerequisites

Install the tools below before building or testing:

- **Docker** — build and run images
- **git** — fetch Istio source
- **kubectl** — talk to Kubernetes clusters
- **Go** — required to compile `istioctl` from source
- **kind** *(optional)* — recommended for local cluster testing

> Use a Go version compatible with the Istio release you are building.

Example helper installs:

```bash
# kind
[ "$(uname -m)" = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# istioctl release archive example
wget "https://github.com/istio/istio/releases/download/1.24.0/istio-1.24.0-linux-amd64.tar.gz" -O - | tar -xz

# clusteradm (optional)
wget -qO- https://github.com/open-cluster-management-io/clusteradm/releases/latest/download/clusteradm_linux_amd64.tar.gz | sudo tar -xvz -C /usr/local/bin/
```

---

## Repository Structure

```text
deploy-istioctl-debug-pod/
├── bin                              # Compiled istioctl binary (output after build)
├── Dockerfile                       # Packages istioctl into a debug image
├── Makefile                         # Build automation
├── manifests
│   ├── deploy.yaml                  # Deployment manifest for istioctl-debug pod
│   └── rbac-istioctl-min-read.yaml  # Minimal read-only RBAC for istioctl usage
├── patches
│   ├── debugtool
│   │   └── debugtool.go             # Custom debugtool command
│   └── root.go                      # Patched root.go to register debugtool
├── README.md
└── src
```

---

## Quick Start

### 1) Build locally

If you want to test the binary directly on your machine:

```bash
make build
```

Sanity check the binary:

```bash
./bin/istioctl version --remote=false
./bin/istioctl debugtool --help
```

If you want the Docker image:

```bash
make image
```

> `make` / `make all` also builds the image, but the `version` target may clean `./bin/istioctl` afterward.  
> If you need the local binary for testing, use `make build` first.

---

### 2) Run locally with Docker

Basic shell access:

```bash
docker run --rm -it --entrypoint /bin/sh istioctl-debug:1.24.0-custom-v1
```

Run the custom command help:

```bash
docker run --rm -it istioctl-debug:1.24.0-custom-v1 istioctl debugtool --help
```

If you want the container to access your current kubeconfig:

```bash
docker run --rm -it \
  -v "$HOME/.kube:/root/.kube:ro" \
  istioctl-debug:1.24.0-custom-v1 \
  istioctl version
```

> Mounting kubeconfig is enough for most local tests.  
> If your cluster is only reachable from your host network, you may need extra Docker networking options depending on your environment.

---

## End-to-End Local Testing with Kind

This is the simplest way to test the full workflow locally.

### 1) Create a Kind cluster

```bash
kind create cluster --name hub
kubectl cluster-info --context kind-hub
```

### 2) Build the image

```bash
make image
```

### 3) Load the image into Kind

```bash
kind load docker-image istioctl-debug:1.24.0-custom-v1 --name hub
```

### 4) Deploy RBAC and debug pod

```bash
kubectl apply -f manifests/rbac-istioctl-min-read.yaml
kubectl apply -f manifests/deploy.yaml
```

### 5) Wait for the pod

```bash
kubectl get pods
kubectl rollout status deploy/istioctl-debug -n default
```

### 6) Run `debugtool` inside the pod

```bash
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod>
```

Save output to a file inside the container:

```bash
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod> -o /tmp/debug-info
```

> Replace `default` and `<pod>` with the namespace and pod you want to inspect.

---

## How to Test the Workflow

Use this order when validating changes locally.

### Fastest validation path

#### A. Validate the source patching and binary build

```bash
make clean
make build
./bin/istioctl debugtool --help
```

What this confirms:

- Istio source can be cloned
- local patches apply cleanly
- custom `istioctl` binary compiles
- `debugtool` is registered correctly

---

#### B. Validate the image

```bash
make image
docker run --rm -it istioctl-debug:1.24.0-custom-v1 istioctl debugtool --help
```

What this confirms:

- the compiled binary is copied into the container correctly
- the image starts successfully
- `istioctl debugtool` is available in the runtime image

---

#### C. Validate in Kubernetes

Use Kind and run the deployment:

```bash
kind create cluster --name hub
kind load docker-image istioctl-debug:1.24.0-custom-v1 --name hub
kubectl apply -f manifests/rbac-istioctl-min-read.yaml
kubectl apply -f manifests/deploy.yaml
kubectl rollout status deploy/istioctl-debug -n default
kubectl exec -it deploy/istioctl-debug -n default -- istioctl debugtool --help
```

What this confirms:

- the image is deployable
- RBAC is sufficient for basic read-only usage
- the pod can run the custom command in-cluster

---

#### D. Validate GitHub Actions behavior

For workflow validation, the safest path is:

1. run the local steps above first
2. open a branch/PR to trigger CI
3. only add secrets if the workflow includes image push/publish steps

If you use a local GitHub Actions runner such as `act`, only publish jobs usually need secrets.

---

## Build Targets

The `Makefile` automates the full build flow.

| Target / Command    | Description |
|---------------------|-------------|
| `make` / `make all` | Default: build Docker image and print version info |
| `make clone`        | Clone or update the Istio repo and checkout `ISTIO_CODE_VERSION` |
| `make patch`        | Apply local patches (`debugtool`, patched `root.go`) |
| `make build`        | Compile `istioctl` from source |
| `make image`        | Build Docker image with the compiled binary |
| `make switch-user`  | Re-run the build as another Linux user (`USER=<username>`) |
| `make mylab`        | Run custom `mylab_cli` build (`OWNER=<owner>`) |
| `make version`      | Print built image tag and cleanup temporary `bin/istioctl` |
| `make clean`        | Remove build artifacts |
| `make help`         | Show detailed usage instructions |

> The Makefile enforces version alignment between `ISTIO_CODE_VERSION` and the base version of `IMAGE_VERSION`.

---

## Required Secrets

### Local build and testing

**No secrets are required** for:

- `make build`
- `make image`
- local Docker runs
- Kind-based testing
- applying the Kubernetes manifests locally

---

### CI / workflow runs that push images

Secrets are only needed if your workflow publishes images to a registry.

Typical examples:

- **Docker Hub**
  - registry username
  - registry token/password
- **GHCR**
  - `GITHUB_TOKEN` with package write permission, or a PAT if your workflow requires one

Use the **exact secret names referenced in `.github/workflows/*.yml`**.

If you are only testing build/validation jobs and not pushing images, you usually do **not** need secrets.

---

## Usage Examples

### Build the image

```bash
make
make all
make mylab OWNER=me
```

### Load image into a Kind cluster

```bash
kind load docker-image istioctl-debug:1.24.0-custom-v1 --name hub
```

### Deploy to Kubernetes

```bash
kubectl apply -f manifests/rbac-istioctl-min-read.yaml
kubectl apply -f manifests/deploy.yaml
```

### Run debugtool against a pod

```bash
kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod>

kubectl exec -it deploy/istioctl-debug -n default -- \
  istioctl debugtool default <pod> -o /tmp/debug-info
```

### Run with local binary

```bash
./bin/istioctl debugtool default <pod>
./bin/istioctl debugtool default <pod> -o /tmp/debug-info
```

---

## Troubleshooting

### 1) Build fails with a version mismatch

Symptom:

- Make stops before build starts
- error mentions `ISTIO_CODE_VERSION` and `IMAGE_VERSION`

Cause:

- the Makefile enforces matching versions

Fix:

- update the variables so the Istio source version matches the image tag base version

---

### 2) `./bin/istioctl` is missing after `make`

Symptom:

- binary was built, then disappears

Cause:

- `make` / `make all` may run cleanup through `make version`

Fix:

```bash
make clean
make build
ls -l ./bin/istioctl
```

Use `make build` when you want to test the binary directly.

---

### 3) `debugtool` command does not exist

Symptom:

- `istioctl debugtool` returns unknown command

Cause:

- patches were not applied correctly
- build reused stale source
- binary/image is not the one built from this repo

Fix:

```bash
make clean
make build
./bin/istioctl debugtool --help
make image
docker run --rm -it istioctl-debug:1.24.0-custom-v1 istioctl debugtool --help
```

---

### 4) Kind cluster cannot find the image

Symptom:

- pod image pull fails in Kind

Cause:

- image exists only on the host Docker daemon, not inside Kind nodes

Fix:

```bash
kind load docker-image istioctl-debug:1.24.0-custom-v1 --name hub
kubectl get pods
```

Also confirm the tag in `manifests/deploy.yaml` matches the image you loaded.

---

### 5) `kubectl exec deploy/istioctl-debug ...` fails

Symptom:

- deployment exists, but exec fails

Cause:

- pod is not ready yet
- deployment name or namespace differs from your manifest

Fix:

```bash
kubectl get deploy,pods -A
kubectl rollout status deploy/istioctl-debug -n default
kubectl get pod -n default -l app=istioctl-debug
```

Then exec into the actual pod if needed.

---

### 6) RBAC errors when running `istioctl`

Symptom:

- forbidden errors from Kubernetes API

Cause:

- RBAC manifest not applied
- current test requires permissions beyond the minimal read-only RBAC

Fix:

```bash
kubectl apply -f manifests/rbac-istioctl-min-read.yaml
kubectl auth can-i get pods --as=system:serviceaccount:default:default -n default
```

If your `debugtool` workflow needs broader access, extend RBAC deliberately.

---

### 7) Docker container cannot reach the cluster

Symptom:

- `istioctl` inside Docker cannot talk to Kubernetes

Cause:

- kubeconfig not mounted
- kubeconfig points to a cluster not reachable from the container
- VPN/network/DNS issues

Fix:

```bash
docker run --rm -it \
  -v "$HOME/.kube:/root/.kube:ro" \
  istioctl-debug:1.24.0-custom-v1 \
  istioctl version
```

If that still fails, verify the same kubeconfig works from the host first.

---

### 8) Patch/build breaks after changing Istio version

Symptom:

- compile errors after bumping `ISTIO_CODE_VERSION`

Cause:

- upstream Istio CLI code changed and local patches no longer apply cleanly

Fix:

- compare your patched `root.go` and `debugtool` integration with the target Istio version
- rebuild from a clean state:

```bash
make clean
make clone
make patch
make build
```

---

## Useful Commands

```bash
# Build binary only
make build

# Build image
make image

# Show Makefile help
make help

# Load image into another Kind cluster
kind load docker-image istioctl-debug:<IMAGE_VERSION> --name <kind-cluster>

# Roll back local file changes
git restore .

# Clean build artifacts
make clean
```

---

## Tips

- Keep `ISTIO_CODE_VERSION` and `IMAGE_VERSION` aligned.
- Use `make build` when testing the local binary.
- Use `make image` + Kind for the most realistic local validation.
- For `make mylab`, set `OWNER=<your-dockerhub-org>` and ensure your registry auth is configured if you push images.
