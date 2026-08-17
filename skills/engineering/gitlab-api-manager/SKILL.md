---
name: gitlab-api-manager
description: 當使用者要求操作 GitLab API (Issues、MRs、Pipelines) 時使用。自動偵測 GitLab 請求或手動觸發。
---

# GitLab API Manager

## 🎯 核心目標

操作 GitLab REST API v4，管理 Issues、Merge Requests、Pipelines。支援 GitLab.com 與 Self-hosted 實例。

---

## 📋 執行步驟 (Execution Steps)

### 步驟一：認證與上下文收集

1. **檢查安全儲存**
    - 優先使用 VS Code Secure Storage API 載入憑證
    - **事實查證**：發送 `GET {{base_url}}/api/v4/user` 驗證 Token 有效性
    - 若返回 `401` 或儲存不存在，進入重新認證

2. **重新認證流程**
    - 清除舊憑證
    - **向使用者收集**：
        - GitLab 實例網址 (`https://gitlab.com` 或自架實例)
        - Private Token (指引：Profile → Access Tokens)
        - 可選：Token 標籤
    - **安全儲存**：使用 VS Code Secure Storage (優先) 或 keyring/keytar

### 步驟二：操作規劃

**識別操作類型**：

| 資源           | Endpoint                                   | 方法                |
| -------------- | ------------------------------------------ | ------------------- |
| Issues         | `/api/v4/projects/:id/issues`              | GET/POST/PUT/DELETE |
| Merge Requests | `/api/v4/projects/:id/merge_requests`      | GET/POST/PUT/DELETE |
| Pipelines      | `/api/v4/projects/:id/pipelines`           | GET/POST            |
| Projects       | `/api/v4/projects`                         | GET/POST            |
| Branches       | `/api/v4/projects/:id/repository/branches` | GET/POST            |

**決策點**：

- 未提供 Project ID → 列出最近 5 個專案請使用者選擇
- 批量操作 → 確認分頁策略

### 步驟三：執行 API 呼叫

**請求格式**：

```
Headers:
  - PRIVATE-TOKEN: <decrypted_token>
  - Content-Type: application/json

Query Parameters:
  - state: opened/closed/merged
  - order_by: created_at/updated_at
  - per_page: 20 (預設)
```

**錯誤處理**：

- `401` → Token 失效，重新認證
- `403` → 權限不足，檢查 Token 權限範圍
- `404` → 資源不存在，確認 ID 正確性
- `429` → 速率限制，等待 60 秒後重試 (最多 3 次)

**結果呈現**：

- **Issues**: 標題、狀態、指派者、標籤、建立時間
- **Merge Requests**: 標題、源/目標分支、狀態、合併狀態、審議進度
- **Pipelines**: 狀態、觸發器、覆蓋時間、失敗 Job 列表

---

## ⚠️ 約束與規則

### 安全性 (Security)

- **Token 絕不明文輸出**：禁止在控制台/日誌顯示完整 Token
- **優先使用 VS Code Secure Storage**：作業系統原生安全儲存 (Windows Credential Manager / macOS Keychain / Linux Secret Service)
- **備用方案**：Python `keyring` 或 Node.js `keytar`
- **最小權限原則**：建議生成僅需權限的 Token (`api` 或 `read_api`)
- **Git 忽略**：加密檔案已加入 `.gitignore` (`*-credentials.enc`、`*.enc`)，確保憑證不會提交到倉儲

### API 規範

- **GitLab API v4**：所有端點使用 `/api/v4/` 路徑
- **分頁處理**：預設每頁 20 筆，超過需自動分頁或詢問
- **URL 驗證**：自架實例必須以 `https://` 開頭 (本地開發除外)

### 事實與決策分離

- **Facts**：Project ID、Issue ID、MR ID 等必須從 API 真實取得
- **Decisions**：合併策略、分支命名等需向使用者確認

### 協作規範

- **Asset 上傳**：當使用者要求上傳附件時，呼叫 [`asset-manager`](../asset-manager/SKILL.md) 處理檔案，本 Skill 負責資源關聯
- **職責分離**：Asset Manager 負責檔案處理與上傳，本 Skill 負責將連結附加到 Issue/MR/Pipeline

---

## 🔧 加密實作參考

### ✅ 推薦方案：VS Code Secure Storage API

```typescript
import * as vscode from "vscode";

const SECRET_KEY_TOKEN = "gitlab-private-token";
const SECRET_KEY_BASE_URL = "gitlab-base-url";

async function saveGitLabCredentials(
    base_url: string,
    token: string,
): Promise<void> {
    await vscode.workspace.secrets.store(SECRET_KEY_BASE_URL, base_url);
    await vscode.workspace.secrets.store(SECRET_KEY_TOKEN, token);
}

async function loadGitLabCredentials(): Promise<
    { base_url: string; token: string } | undefined
> {
    const base_url = await vscode.workspace.secrets.get(SECRET_KEY_BASE_URL);
    const token = await vscode.workspace.secrets.get(SECRET_KEY_TOKEN);
    return base_url && token ? { base_url, token } : undefined;
}

async function deleteGitLabCredentials(): Promise<void> {
    await vscode.workspace.secrets.delete(SECRET_KEY_BASE_URL);
    await vscode.workspace.secrets.delete(SECRET_KEY_TOKEN);
}
```

### 🔧 備用方案：Python keyring

```python
import keyring

SERVICE_NAME = "GitLabAPIManager"

def save_credentials(base_url: str, token: str):
    keyring.set_password(SERVICE_NAME, "base_url", base_url)
    keyring.set_password(SERVICE_NAME, "token", token)

def load_credentials() -> dict | None:
    base_url = keyring.get_password(SERVICE_NAME, "base_url")
    token = keyring.get_password(SERVICE_NAME, "token")
    return ({"base_url": base_url, "token": token}) if (base_url and token) else None

def delete_credentials():
    keyring.delete_password(SERVICE_NAME, "base_url")
    keyring.delete_password(SERVICE_NAME, "token")
```

### 🔧 備用方案：Node.js keytar

```javascript
const keytar = require("keytar");
const SERVICE_NAME = "GitLabAPIManager";

async function saveCredentials(baseUrl, token) {
    await keytar.setPassword(SERVICE_NAME, "base_url", baseUrl);
    await keytar.setPassword(SERVICE_NAME, "token", token);
}

async function loadCredentials() {
    const baseUrl = await keytar.getPassword(SERVICE_NAME, "base_url");
    const token = await keytar.getPassword(SERVICE_NAME, "token");
    return baseUrl && token ? { base_url: baseUrl, token } : null;
}

async function deleteCredentials() {
    await keytar.deletePassword(SERVICE_NAME, "base_url");
    await keytar.deletePassword(SERVICE_NAME, "token");
}
```

> **注意**：不推薦使用 PowerShell `ConvertFrom-SecureString` 或純 AES 檔案加密，這些方案缺乏跨平台相容性。

---

## 📚 參考資源

- **GitLab REST API v4**: https://docs.gitlab.com/ee/api/
- **Personal Access Tokens**: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html
- **API Rate Limiting**: https://docs.gitlab.com/ee/user/gitlab_com/#api-rate-limit
