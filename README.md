#### 目錄架構
```
deploy-istioctl-debug-pod/
├── Dockerfile                # 建構 Docker image
├── build.sh                  # 自動化建構 script
├── manifests/                # K8s YAML 放這裡
│   ├── deploy.yaml
│   ├── rbac.yaml
│   └── rbac-readonly.yaml
├── bin/                      # 存放 istioctl binary 的目錄
│   └── 1-24-0/
│       └── istioctl          # 請確保 binary 存在且已賦予執行權限
└── README.md                 # 說明用法和指令
```
#### command
kind load docker-image istioctl-debug:1.24.0 --name c1
istioctl debug-tool default productpage-v1-78b88d9749-h6d4p 
istioctl debug-tool default productpage-v1-78b88d9749-h6d4p -o /tmp/debug-info
