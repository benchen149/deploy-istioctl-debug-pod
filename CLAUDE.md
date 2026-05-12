# Claude Code — Project Conventions

## 專案簡介

`deploy-istioctl-debug-pod`：建立客製化 `istioctl` binary（含 `debugtool` 擴充），打包為 Docker image，可部署至 Kubernetes 或本地 Docker 執行。

---

## 開發流程

所有功能開發皆走 **GitHub Flow**：

```
issue → feature branch → commit → PR → merge to 1-feat-new-branch-for-develop-and-test → sync PR → merge to main
```

使用 `/github-flow` slash command 自動引導整個流程。

### Branch 策略

| Branch | 用途 |
|--------|------|
| `main` | 穩定版本，只接受來自 `1-feat-new-branch-for-develop-and-test` 的 PR merge |
| `1-feat-new-branch-for-develop-and-test` | 主要開發 branch，feature branch 從此切出、PR 也 merge 回此 |
| `{issue-number}-{slug}` | Feature branch，merge 後自動刪除 |

**絕對不可刪除 `main` 與 `1-feat-new-branch-for-develop-and-test`。**

---

## 環境設定

新環境第一次執行 `/setup-github-ssh` 完成設定：
- SSH key 產生（必須設定 passphrase）
- GitHub known_hosts fingerprint 驗證
- `gh` CLI 登入（Fine-grained Token，限定單一 repo）
- git config user.email / user.name

### GitHub Token（gh CLI）

- 使用 Fine-grained Personal Access Token，限定此 repo
- 最小權限：Contents / Issues / Pull requests Read & Write、Metadata Read-only
- 有效期：建議 90 天
- 儲存位置：`~/.config/gh/hosts.yml`（明文，不可納入 git）

---

## 版本資訊

| Istio Version | Build Tested | Notes |
|---------------|--------------|-------|
| **1.29.2** | ✅ | 目前預設版本 |
| 1.24.0 | ✅ | 與 1.29.2 root.go 完全相同 |
| 1.13.5 | ✅ | 需使用 `patches/root.go-1.13.5` |

- `patches/root.go` 與 `patches/debugtool/debugtool.go` 對 1.24.x / 1.29.x 完全相容
- `OUTPUT_IMAGE_VERSION` 格式必須為 `{version}-{label}`，例如 `1.29.2-custom-v1`
- `ISTIO_CODE_VERSION` 必須與 `OUTPUT_IMAGE_VERSION` 的 base 版本一致

---

## 常用 Make 指令

| 指令 | 說明 |
|------|------|
| `make` / `make all` | 建立 Docker image（預設） |
| `make clone` | Clone / 更新 Istio source |
| `make patch` | 套用 debugtool patch |
| `make build` | 編譯 istioctl binary |
| `make image` | 建立 Docker image |
| `make clean` | 清除 build artifacts |
| `make help` | 顯示所有指令說明 |

指定版本建置：
```bash
make ISTIO_CODE_VERSION=1.29.2 OUTPUT_IMAGE_VERSION=1.29.2-custom-v1
```

**注意**：`/tmp` 空間只有 3.9G，Go 編譯時可能填滿。若出現 `no space left on device`，執行 `rm -rf /tmp/go-build*` 清除快取。

---

## Claude Slash Commands

| Command | 說明 |
|---------|------|
| `/setup-github-ssh` | 新環境一次性設定：SSH key、GitHub known_hosts、gh CLI 登入 |
| `/github-flow` | 完整開發流程（Mode 1：issue → PR → merge；Mode 2：關閉 PR / Issue） |

---

## Issue / PR 標題準則

- **一律使用英文**
- 格式：`<type>: <short description>`
- 範例：`feat: add xxx`、`fix: xxx not working`、`chore: update xxx`

---

## 安全規範

- SSH key passphrase 必須設定，不可留空
- known_hosts 加入前必須對比 GitHub 官方 fingerprint
- `gh` CLI token 不可提交至任何 repo 或 dotfiles
- `~/.ssh/id_ed25519` 不可複製到他處或提交至任何 repo
- Feature branch merge 後自動刪除，`main`、`1-feat-new-branch-for-develop-and-test` 永遠保留
