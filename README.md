#### 目錄架構
```
istioctl-debug/
├── Dockerfile                  # 建立含本地 istioctl 的 Docker image
├── build.sh                    # 自動化建構與推送腳本
├── bin/                        # 放置本地 istioctl binary，需具執行權限
│   └── istioctl
├── manifests/                  # Kubernetes 資源配置檔存放處
│   ├── deploy.yaml             # Deployment 配置檔
│   ├── rbac.yaml               # 擁有管理權限的 RBAC 設定
│   └── rbac-readonly.yaml      # 僅讀取權限的 RBAC 設定
├── src/                        # Golang 程式碼模組根目錄
│   └── debugtool/              # 自訂 istioctl debug 指令的 CLI 工具
│       ├── debugtool.go        # 程式
名稱）
└── README.md                   # 專案說明文件與使用方式
```

#### command
```
kind load docker-image istioctl-debug:1.24.0 --name c1
istioctl debug-tool default productpage-v1-78b88d9749-h6d4p 
istioctl debug-tool default productpage-v1-78b88d9749-h6d4p -o /tmp/debug-info
```