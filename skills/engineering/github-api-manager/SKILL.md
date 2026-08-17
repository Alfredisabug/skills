---
name: github-api-manager
description: 當使用者要求操作 GitHub API (Issues、Pull Requests、Actions 等) 時使用。自動偵測 GitHub 相關請求或手動觸發。
---

# GitHub API Manager SOP

## 🎯 核心目標

操作 GitHub REST API v3 與 GraphQL API，管理 Issues、Pull Requests、Actions Workflows 等功能。支援 github.com 與 GitHub Enterprise。

---

## 📋 執行步驟 (Execution Steps)

### 步驟一：認證與上下文收集 (Authentication & Context)

1. **檢查本地加密儲存**
    - 讀取本地加密配置檔案：`{{VSCODE_USER_PROMPTS_FOLDER}}/../github-credentials.enc`
    - 若檔案不存在或解密失敗，進入 **步驟一-B**

2. **解密與驗證 Token**
    - 使用 AES-256-GCM 解密儲存檔
    - 提取：`base_url`, `token`, `token_type`, `encrypted_at`
    - **Token 類型判斷**：
        - `fine-grained`: 細粒度個人存取令牌 (推薦)
        - `classic`: 經典個人存取令牌
        - `installation`: GitHub App 安裝令牌
    - **事實查證 (Facts)**：發送 `GET {{base_url}}/user` 驗證 Token 有效性
    - 若返回 `401 Unauthorized`，進入 **步驟一-B**

3. **步驟一-B：重新認證流程**
    - 清除舊憑證 (刪除或覆蓋加密檔)
    - **向使用者收集資訊**：
        - GitHub 實例網址 (預設：`https://github.com`，自架：`https://github.your-company.com`)
        - Personal Access Token (提示：可在 Settings → Developer settings → Personal access tokens 取得)
        - Token 類型選擇 (Fine-grained 或 Classic)
    - **加密儲存**：
        - 使用 AES-256-GCM 加密後寫入本地檔案
        - 記錄加密時間戳與 Token 類型

### 步驟二：操作規劃 (Operation Planning)

根據使用者需求，識別操作類型：

| 類別              | REST API Endpoint                                | GraphQL Field                 |
| ----------------- | ------------------------------------------------ | ----------------------------- |
| **Issues**        | `/api/v3/repos/:owner/:repo/issues`              | `repository.issue`            |
| **Pull Requests** | `/api/v3/repos/:owner/:repo/pulls`               | `repository.pullRequest`      |
| **Actions**       | `/api/v3/repos/:owner/:repo/actions/runs`        | `repository.workflowRun`      |
| **Repositories**  | `/api/v3/repos/:owner/:repo`                     | `repository`                  |
| **Branches**      | `/api/v3/repos/:owner/:repo/branches`            | `repository.defaultBranchRef` |
| **Comments**      | `/api/v3/repos/:owner/:repo/issues/:id/comments` | `issue.comments`              |

**決策點 (Decisions)**：

- 若使用者未提供 `owner/repo`，列出最近操作的 5 個倉儲請使用者選擇
- 若操作涉及大量資料 (如批量 Issues)，確認是否需要使用 GraphQL 批量查詢

### 步驟三：執行 API 呼叫 (Execute API Calls)

1. **構建 REST 請求**

    ```
    Headers:
      - Authorization: token <decrypted_token>
      - Accept: application/vnd.github.v3+json
      - User-Agent: <skill-name>

    Query Parameters (如需要):
      - state: open/closed/all
      - sort: created/updated/pushed
      - direction: asc/desc
      - page: <page_number>
      - per_page: 30 (GitHub 預設最大值)
    ```

2. **構建 GraphQL 查詢 (如需要)**

    ```graphql
    query {
        repository(owner: "owner", name: "repo") {
            issues(first: 10, states: OPEN) {
                nodes {
                    number
                    title
                    state
                    author {
                        login
                    }
                    labels(first: 5) {
                        nodes {
                            name
                        }
                    }
                }
            }
        }
    }
    ```

3. **錯誤處理**
    - **401**: Token 失效 → 清除舊憑證，重新認證
    - **403**: 權限不足或速率限制 →
        - 檢查 `X-RateLimit-Remaining` 頭
        - 若剩餘為 0，等待重置時間或提示升級
    - **404**: 資源不存在 → 確認 owner/repo/ID 是否正確
    - **422**: 驗證失敗 → 顯示詳細錯誤訊息，請使用者確認參數

4. **結果呈現**
    - **Issues**: 編號、標題、狀態、作者、標籤、建立時間
    - **Pull Requests**: 編號、標題、源分支、目標分支、狀態、合併狀態、審查狀態
    - **Actions**: 工作流名稱、狀態、觸發器、執行時間、重啟選項

---

## ⚠️ 約束與規則 (Constraints & Rules)

### 安全性 (Security)

- **Token 絕不明文輸出**：任何情況下都不得在控制台或日誌中顯示完整 Token
- **推薦使用 VS Code Secure Storage**：利用作業系統原生安全儲存 (Keychain/Keyring/Credential Manager)
- **備用方案**：若無法使用 VS Code API，使用跨平台 `keyring` 庫 (Python) 或 `keytar` (Node.js)
- **最小權限原則**：
    - **Fine-grained Token**: 僅授予必要倉儲與權限 (如 `contents: read`, `issues: write`)
    - **Classic Token**: 避免使用 `repo` 全域權限，改用細粒度權限
- **Git 忽略**：加密檔案已加入 `.gitignore` (`*-credentials.enc`、`*.enc`)，確保憑證不會提交到倉儲

### API 規範

- **REST API v3**: 預設使用 REST API，端點必須為 `/api/v3/` 路徑
- **GraphQL API**: 大量關聯資料查詢時優先使用 GraphQL (`/api/graphql`)
- **分页處理**: REST 預設每頁 30 筆，GraphQL 使用 `first/after` 游標分頁
- **URL 驗證**: GitHub Enterprise 網址必須以 `https://` 開頭

### 使用者體驗

- **預測性**: 操作前顯示預期影響 (例如：「這將關閉 5 個 Issues，是否繼續？」)
- **確認機制**: 破壞性操作 (刪除、合併、關閉) 必須二次確認
- **回滾建議**: 提供可逆操作建議 (例如：「關閉後可重新開啟，但刪除不可恢復」)

### 事實與決策分離

- **Facts**: Repository 資訊、Issue/PR 狀態、Commit 歷史等必須從 GitHub API 真實取得
- **Decisions**: 合併方法 (merge/squash/rebase)、分支保護策略等需向使用者確認

### 協作規範

- **Asset 上傳**：當使用者要求上傳附件時，呼叫 [`asset-manager`](../asset-manager/SKILL.md) 處理檔案，本 Skill 負責資源關聯
- **職責分離**：Asset Manager 負責檔案處理與上傳，本 Skill 負責將連結附加到 Issue/PR/Release

---

## 🔧 加密實作參考 (Encryption Implementation Reference)

### ✅ 推薦方案：VS Code Secure Storage API

**優勢**：

- 跨平台支援 (Windows Credential Manager / macOS Keychain / Linux Secret Service)
- **不需要額外環境或依賴** (不需要 Python、不需要安裝任何套件)
- VS Code 擴展開發的標準做法
- 自動處理加密解密，安全性由作業系統保障

**實作方式 (TypeScript)**：

```typescript
import * as vscode from "vscode";

const SECRET_KEY_TOKEN = "github-personal-access-token";
const SECRET_KEY_BASE_URL = "github-base-url";
const SECRET_KEY_TOKEN_TYPE = "github-token-type";

async function saveGitHubCredentials(
    base_url: string,
    token: string,
    token_type: string,
): Promise<void> {
    await vscode.workspace.secrets.store(SECRET_KEY_BASE_URL, base_url);
    await vscode.workspace.secrets.store(SECRET_KEY_TOKEN, token);
    await vscode.workspace.secrets.store(SECRET_KEY_TOKEN_TYPE, token_type);
}

async function loadGitHubCredentials(): Promise<
    { base_url: string; token: string; token_type: string } | undefined
> {
    const base_url = await vscode.workspace.secrets.get(SECRET_KEY_BASE_URL);
    const token = await vscode.workspace.secrets.get(SECRET_KEY_TOKEN);
    const token_type = await vscode.workspace.secrets.get(
        SECRET_KEY_TOKEN_TYPE,
    );

    if (!base_url || !token || !token_type) {
        return undefined;
    }

    return { base_url, token, token_type };
}

async function deleteGitHubCredentials(): Promise<void> {
    await vscode.workspace.secrets.delete(SECRET_KEY_BASE_URL);
    await vscode.workspace.secrets.delete(SECRET_KEY_TOKEN);
    await vscode.workspace.secrets.delete(SECRET_KEY_TOKEN_TYPE);
}
```

### 🔧 備用方案：跨平台 Python keyring (需使用 uv 環境)

若需要在非 VS Code 環境使用 Python，請先載入 [`python-uv-environment`](../python-uv-environment/SKILL.md) Skill 來管理環境。

**使用步驟**：

```bash
# 1. 使用 uv 建立環境並安裝 keyring
uv add keyring

# 2. 執行程式
uv run python github_api.py
```

**Python 實作範例**：

```python
import keyring

SERVICE_NAME = "GitHubAPIManager"

def save_credentials(base_url: str, token: str, token_type: str):
    """使用系統原生安全儲存"""
    keyring.set_password(SERVICE_NAME, "base_url", base_url)
    keyring.set_password(SERVICE_NAME, "token", token)
    keyring.set_password(SERVICE_NAME, "token_type", token_type)

def load_credentials() -> dict | None:
    """載入憑證，若不存在則返回 None"""
    base_url = keyring.get_password(SERVICE_NAME, "base_url")
    token = keyring.get_password(SERVICE_NAME, "token")
    token_type = keyring.get_password(SERVICE_NAME, "token_type")

    if not base_url or not token or not token_type:
        return None

    return {"base_url": base_url, "token": token, "token_type": token_type}

def delete_credentials():
    """刪除儲存的憑證"""
    keyring.delete_password(SERVICE_NAME, "base_url")
    keyring.delete_password(SERVICE_NAME, "token")
    keyring.delete_password(SERVICE_NAME, "token_type")

# keyring 自動使用系統原生安全儲存
# Windows: Credential Manager
# macOS: Keychain
# Linux: Secret Service (gnome-keyring / KWallet)
```

### 🔧 備用方案：跨平台 Node.js keytar

若使用 Node.js 環境：

```javascript
const keytar = require("keytar");
const SERVICE_NAME = "GitHubAPIManager";

async function saveCredentials(baseUrl, token, tokenType) {
    await keytar.setPassword(SERVICE_NAME, "base_url", baseUrl);
    await keytar.setPassword(SERVICE_NAME, "token", token);
    await keytar.setPassword(SERVICE_NAME, "token_type", tokenType);
}

async function loadCredentials() {
    const baseUrl = await keytar.getPassword(SERVICE_NAME, "base_url");
    const token = await keytar.getPassword(SERVICE_NAME, "token");
    const tokenType = await keytar.getPassword(SERVICE_NAME, "token_type");

    if (!baseUrl || !token || !tokenType) return null;

    return { base_url: baseUrl, token, token_type: tokenType };
}

async function deleteCredentials() {
    await keytar.deletePassword(SERVICE_NAME, "base_url");
    await keytar.deletePassword(SERVICE_NAME, "token");
    await keytar.deletePassword(SERVICE_NAME, "token_type");
}

// 安裝：npm install keytar
// keytar 自動使用系統原生安全儲存，無需額外配置
```

### ⚠️ 不推薦：PowerShell 或純檔案加密方案

PowerShell 的 `ConvertFrom-SecureString` 僅在 Windows 有效，且綁定特定使用者/機器。
純 AES 加密檔案需要處理 Master Key 的安全儲存問題，不建議使用。

---

## 📚 參考資源 (References)

- **GitHub REST API 文檔**: https://docs.github.com/en/rest
- **GitHub GraphQL API 文檔**: https://docs.github.com/en/graphql
- **Personal Access Tokens**: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
- **API 速率限制**: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
- **GitHub Explorer (GraphQL)**: https://docs.github.com/en/graphql/overview/explorer
