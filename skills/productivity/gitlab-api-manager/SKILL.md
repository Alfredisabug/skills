---
name: gitlab-api-manager
description: 當使用者要求操作 GitLab (Issues、Merge Requests、Pipelines、Releases、Projects 等) 時使用。優先使用 glab CLI，備用 REST API v4。
---

# GitLab API Manager SOP

## 🎯 核心目標

操作 GitLab 資源（Issues、Merge Requests、CI/CD Pipelines、Releases、Projects 等），支援 GitLab.com 與 Self-hosted 自架實例。
**原則：優先使用官方 `glab` CLI，環境無 CLI 時才回退使用 REST API v4。**

---

## 📋 執行步驟 (Execution Steps)

### 步驟一：認證與環境收集 (Authentication & Context)

1. **檢查原生 CLI 登入狀態 (優先)**
   - 執行 `glab auth status` 檢查是否已有登入的憑證與主機資訊。
   - 若已登入，直接進入「步驟二」。

2. **檢查環境變數 (備用)**
   - 檢查系統或工作區是否有設定：
     - `GITLAB_TOKEN` 或 `GITLAB_PRIVATE_TOKEN`
     - 自架實例主機網址：`GITLAB_HOST` 或 `CI_SERVER_URL`（預設為 `https://gitlab.com`）
   - 若有 Token，可直接搭配 `glab` 指令或 HTTP REST 呼叫。

3. **取得當前專案資訊 (Facts)**
   - 執行 `git remote -v` 或 `glab repo view` 取得當前專案的 Group 與 Project 路徑（或 Project ID）。
   - 若當前目錄非 Git 倉儲且使用者未指定，主動詢問目標專案路徑或 ID。

4. **回退引導（無可用憑證時）**
   - 若以上皆無憑證，引導使用者完成認證：
     - 引導使用 CLI 登入：`glab auth login`（若為自架實例：`glab auth login --hostname <your.gitlab.host>`）
     - 或請使用者提供具有必要權限（如 `api` 或 `read_api`）的 Personal Access Token，並設定於環境變數 `GITLAB_TOKEN`。

---

### 步驟二：操作規劃與執行 (Operation Planning & Commands)

優先使用 `glab` CLI 執行；若需自訂查詢或無 CLI 環境，使用 `glab api` 或 `curl` REST API v4。

#### 1. Issues 管理
* **查詢列表**：`glab issue list --state <opened|closed|all> --per-page 20`
* **查看詳情**：`glab issue view <issue_id> --comments`
* **建立 Issue**：`glab issue create --title "<title>" --description "<description>" --label "<label>"`
* **新增討論/留言**：`glab issue note <issue_id> --message "<message>"`
* **關閉/重開**：`glab issue close <issue_id>` / `glab issue reopen <issue_id>`

#### 2. Merge Requests (MR) 管理
* **查詢列表**：`glab mr list --state <opened|closed|merged|all>`
* **查看 Diff / 狀態**：`glab mr diff <mr_id>` / `glab mr view <mr_id>`
* **建立 MR**：`glab mr create --title "<title>" --description "<description>" --target-branch <target_branch> --source-branch <source_branch>`
* **核准 MR**：`glab mr approve <mr_id>`
* **合併 MR**：`glab mr merge <mr_id> --auto-merge` (或 `--squash` / `--rebase`)

#### 3. CI/CD Pipelines 管理
* **查看 Pipeline 狀態**：`glab ci status` / `glab ci list --per-page 10`
* **查看 Pipeline 詳情與 Jobs**：`glab ci view <pipeline_id>`
* **檢視 Job Trace Log**：`glab ci trace <job_id>`
* **重跑失敗 Job / Pipeline**：`glab ci retry <job_or_pipeline_id>`

#### 4. Releases 管理
* **查詢 Release**：`glab release list`
* **建立 Release**：`glab release create <tag> --name "<name>" --notes "<notes>"`

#### 5. REST API v4 備用方案
若需要自訂端點或無 CLI 指令封裝時，使用 `glab api` 或 `curl`：
* **端點前綴**：所有端點皆為 `/api/v4/`（例如：`/api/v4/projects/:id/issues`）
* **專案路徑編碼**：若使用專案名稱而非數字 ID，路徑需做 URL 編碼（例如：`group/project` → `group%2Fproject`）
* **CLI API 呼叫範例**：`glab api "projects/:id/issues?state=opened"`
* **Direct Curl 範例**：
  ```bash
  curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://<gitlab_host>/api/v4/projects/<project_id>/issues"
  ```

---

### 步驟三：結果確認與呈現 (Confirmation & Presentation)

1. **破壞性與狀態變更操作二度確認**：
   - 關閉 Issue、合併 MR、刪除分支、重跑大量 Pipeline 前，必須向使用者確認目標與影響。
2. **結構化呈現結果**：
   - 查詢結果應整理成乾淨的 Markdown 列表或表格（包含 IID/ID、標題、作者、狀態、網址）。

---

## ⚠️ 約束與規則 (Constraints & Rules)

### 安全性 (Security)
* **Token 嚴禁明文輸出**：任何情況下都不得在控制台、輸出或日誌中印出完整 Token。
* **最小權限原則**：建議使用者僅授予必要權限（例如：唯讀操作使用 `read_api`，寫入操作使用最小必要 scope 的 Personal/Project Access Token）。
* **憑證隔離**：不將 Token 寫入版本庫追蹤的檔案（`.env` 等檔案必須已在 `.gitignore` 中）。

### 自架實例規範 (Self-hosted Support)
* 針對非 `gitlab.com` 的私有部署實例，必須明確確認主機位址（Host / Base URL），且預設強制使用 `https://`。

### 事實與決策分離 (Facts vs. Decisions)
* **Facts**：Project ID、IID、分支名稱、MR/Pipeline 狀態必須透過 Git 指令或 API 真實取得，不自行推測。
* **Decisions**：MR 合併策略（Squash / Merge commit）、目標分支選擇、刪除來源分支等決策需由使用者確認。

### 協作規範
* **附件上傳**：若需上傳圖片或檔案至 Issue/MR，呼叫 [`git-asset-manager`](../git-asset-manager/SKILL.md) 處理檔案上傳，本 Skill 負責將 URL 插入至 Markdown Body。
