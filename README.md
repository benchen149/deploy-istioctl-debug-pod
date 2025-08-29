#### 目錄架構
```
istioctl-debug/
├── Dockerfile                  # Build a Docker image that includes the local istioctl
├── build.sh                    # Automated build and push script
├── bin/                        # Stores the local istioctl binary (requires executable permission)
│   └── istioctl
├── manifests/                  # Kubernetes resource configuration files
│   ├── deploy.yaml             # Deployment configuration
│   ├── rbac.yaml               # RBAC configuration with admin privileges
│   └── rbac-readonly.yaml      # RBAC configuration with read-only privileges
├── src/                        # Root directory for Golang modules
│   └── debugtool/              # Custom CLI tool for istioctl debug commands
│       ├── debugtool.go        # Source code
└── README.md                   # Project documentation and usage instructions

```
#### Others
```
kind load docker-image istioctl-debug:1.24.0 --name c1
istioctl debugtool default productpage-v1-78b88d9749-h6d4p 
istioctl debugtool default productpage-v1-78b88d9749-h6d4p -o /tmp/debug-info
```