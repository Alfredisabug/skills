---
name: github-api-manager
description: 當使用者要求操作 GitHub (Issues、Pull Requests、Actions、Releases、Repository 等) 時使用。優先使用 gh CLI，備用 REST/GraphQL API。
---

# GitHub API Manager SOP

## 🎯 核心目標

操作 GitHub 資源（Issues、Pull Requests、Actions Workflows、Releases 等），支援 github.com 與 GitHub Enterprise。
**原則：優先使用官方 `gh` CLI，環境無 CLI 時才回退使用 REST/GraphQL API。**

---

## 📋 執行步驟 (Execution Steps)

### 步驟一：認證與環境收集 (Authentication & Context)

1. **檢查原生 CLI 登入狀態 (優先)**
   - 執行 `gh auth status` 檢查是否已有登入的憑證。
   - 若已登入，直接進入「步驟二」。

2. **檢查環境變數 (備用)**
   - 檢查系統或工作區是否有設定：
     - `GH_TOKEN` 或 `GITHUB_TOKEN`
     - 自架實例主機名稱：`GH_HOST`（預設為 `github.com`）
   - 若有 Token，可直接搭配 `gh` 指令或 HTTP REST 呼叫。

3. **取得當前倉儲資訊 (Facts)**
   - 執行 `git remote -v` 或 `gh repo view --json owner,name,defaultBranchRef` 取得目前專案的 `owner/repo`。
   - 若當前目錄非 Git 倉儲且使用者未指定，主動詢問目標 `owner/repo`。

4. **回退引導（無可用憑證時）**
   - 若以上皆無憑證，引導使用者完成認證：
     - 引導使用 CLI 登入：`gh auth login`
     - 或請使用者提供具有最小必要權限的 Personal Access Token (PAT)，並設定於環境變數 `GH_TOKEN`。

---

### 步驟二：操作規劃與執行 (Operation Planning & Commands)

優先使用 `gh` CLI 執行；若需自訂查詢或無 CLI 環境，使用 `gh api` 或 `curl` REST/GraphQL。

#### 1. Issues 管理
* **查詢列表**：`gh issue list --state <open|closed|all> --limit 20`
* **查看詳情**：`gh issue view <issue_number> --comments`
* **建立 Issue**：`gh issue create --title "<title>" --body "<body>" --label "<label>"`
* **新增留言**：`gh issue comment <issue_number> --body "<body>"`
* **關閉/重開**：`gh issue close <issue_number>` / `gh issue reopen <issue_number>`

#### 2. Pull Requests 管理
* **查詢列表**：`gh pr list --state <open|closed|merged|all>`
* **查看 Diff / 狀態**：`gh pr diff <pr_number>` / `gh pr view <pr_number>`
* **建立 PR**：`gh pr create --title "<title>" --body "<body>" --base <target_branch> --head <source_branch>`
* **審查與核准**：`gh pr review <pr_number> --approve` / `gh pr review <pr_number> --comment -b "<body>"`
* **合併 PR**：`gh pr merge <pr_number> --merge` (或 `--squash` / `--rebase`)

#### 3. Actions / Workflows 管理
* **查看執行紀錄**：`gh run list --limit 10`
* **查看特定 Run**：`gh run view <run_id> --log-failed` (僅檢視失敗 Log)
* **手動觸發 Workflow**：`gh workflow run <workflow_file_or_id> --ref <branch>`
* **重跑失敗工作流**：`gh run rerun <run_id> --failed`

#### 4. Releases 管理
* **查詢 Release**：`gh release list`
* **建立 Release**：`gh release create <tag> --title "<title>" --notes "<notes>"`

#### 5. REST & GraphQL API 備用方案
若需要進階資料或無 CLI 指令封裝時，使用 `gh api`：
* **REST 查詢**：`gh api /repos/:owner/:repo/issues`
* **GraphQL 查詢**：
  ```bash
  gh api graphql -f query='
    query($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        issues(first: 10, states: OPEN) {
          nodes { number title state }
        }
      }
    }' -F owner='<owner>' -F repo='<repo>'
  ```

---

### 步驟三：結果確認與呈現 (Confirmation & Presentation)

1. **破壞性與狀態變更操作二度確認**：
   - 關閉 Issue、合併 PR、刪除分支、重跑大量 Workflow 前，必須向使用者確認目標與影響。
2. **結構化呈現結果**：
   - 查詢結果應整理成乾淨的 Markdown 列表或表格（包含 ID/編號、標題、作者、狀態、網址）。

---

## ⚠️ 約束與規則 (Constraints & Rules)

### 安全性 (Security)
* **Token 嚴禁明文輸出**：任何情況下都不得在控制台、輸出或日誌中印出完整 Token。
* **最小權限原則**：建議使用者僅授權所需權限（例如：Fine-grained PAT 僅授權該 Repository 的 `Issues: write`、`Pull requests: write`）。
* **憑證隔離**：不將 Token 寫入版本庫追蹤的檔案（`.env` 等檔案必須已在 `.gitignore` 中）。

### 事實與決策分離 (Facts vs. Decisions)
* **Facts**：Repo 資訊、Branch 名稱、Issue/PR 狀態必須透過 Git 指令或 API 真實取得，不自行推測。
* **Decisions**：合併策略（Merge / Squash / Rebase）、版本號 Tag 命名、是否刪除分支等決策需由使用者確認。

### 協作規範
* **附件上傳**：若需上傳圖片或檔案至 Issue/PR，呼叫 [`git-asset-manager`](../git-asset-manager/SKILL.md) 處理檔案上傳，本 Skill 負責將 URL 插入至 Markdown Body。

### 🚫 禁止混淆之 GitLab CLI 語法 (Anti-Confusion / Platform Boundaries)
GitHub CLI (`gh`) 與 GitLab CLI (`glab`) 語法存在顯著差異，**嚴禁混用**：
* ❌ 嚴禁在 `gh` 使用 `--description`（GitHub 建立 Issue/PR 必須用 `--body` 或 `-b`）。
* ❌ 嚴禁在 `gh` 使用 `--target-branch` / `--source-branch`（GitHub 建立 PR 必須用 `--base` / `--head`）。
* ❌ 嚴禁在 `gh` 使用 `gh issue note`（GitHub 新增留言必須用 `gh issue comment`）。
* ❌ 嚴禁在 `gh` 使用 `--per-page`（GitHub 限制數量必須用 `--limit`）。
* ❌ 嚴禁在 `gh` 使用 `--state opened`（GitHub 狀態篩選必須用 `--state open`）。

