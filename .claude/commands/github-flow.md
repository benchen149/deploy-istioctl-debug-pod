# GitHub Flow 自動化

執行完整的 GitHub issue → branch → PR → merge 工作流程，或關閉指定的 PR / Issue。

## 使用方式

```
/github-flow
```

執行後會詢問要執行哪個模式。

---

## 模式一：完整開發流程（issue → branch → PR → merge）

### Step 1：收集資訊
詢問使用者：
- **Issue 標題**（例如：`feat: add xxx`）
- **Issue 描述**（問題背景、預計異動）
- **Branch slug**（例如：`add-xxx`，會自動加上 issue 編號變成 `{number}-add-xxx`）
- **目標 base branch**（預設 `1-feat-new-branch-for-develop-and-test`）

### Step 2：開 GitHub Issue
使用 GitHub API 建立 issue，取得 issue 編號。

```bash
curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/benchen149/deploy-istioctl-debug-pod/issues \
  -d "{\"title\": \"$TITLE\", \"body\": \"$BODY\"}"
```

### Step 3：建立並切換 branch
```bash
git checkout $BASE_BRANCH
git pull origin $BASE_BRANCH
git checkout -b {issue-number}-$SLUG
```

### Step 4：等待使用者完成改動
提示使用者進行程式碼修改，完成後告知 Claude 繼續。

### Step 5：Commit & Push
```bash
git add <changed files>
git commit -m "feat/fix/chore: $TITLE

$DESCRIPTION

Closes #{issue-number}"
git push origin {issue-number}-$SLUG
```

### Step 6：開 Pull Request
使用 GitHub API 建立 PR，base 指向 `$BASE_BRANCH`。

```bash
curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/benchen149/deploy-istioctl-debug-pod/pulls \
  -d "{\"title\": \"$TITLE\", \"body\": \"$BODY\", \"head\": \"{branch}\", \"base\": \"$BASE_BRANCH\"}"
```

### Step 7：確認是否 merge
詢問使用者是否直接 merge，若是則：
- merge PR（`merge_method: merge`）
- sync local base branch（`git pull origin $BASE_BRANCH`）
- 詢問是否刪除 feature branch（local + remote）

---

## 模式二：關閉 PR / Issue

詢問使用者要關閉的類型（PR 或 Issue）與編號，支援一次關閉多個。

### 關閉 Issue
```bash
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/benchen149/deploy-istioctl-debug-pod/issues/{number} \
  -d '{"state":"closed"}'
```

### 關閉 PR
```bash
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/benchen149/deploy-istioctl-debug-pod/pulls/{number} \
  -d '{"state":"closed"}'
```

---

## 注意事項

- `GITHUB_TOKEN` 需要有 Contents / Issues / Pull requests 的 Read and write 權限
- 若環境沒有 `GITHUB_TOKEN`，流程開始前會提示設定
- base branch 預設為 `1-feat-new-branch-for-develop-and-test`，若要 merge 到 `main` 請在 Step 1 指定
- feature branch merge 後是否刪除由使用者決定，長期 branch 不刪除
