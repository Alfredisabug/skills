---
name: asset-manager
description: 當使用者要求上傳、管理或刪除檔案附件時使用（支援 GitLab、GitHub）。與 API Manager 協作處理關聯資源。
---

# Asset Manager

## 🎯 核心目標

將「檔案上傳」從 Issue/MR/Release 管理流程中解耦，提供統一的 Asset 上傳介面，與 GitLab/GitHub API Manager 協作完成資源關聯。

---

## 📋 執行步驟 (Execution Steps)

### 步驟一：收集上下文 (Context Collection)

1. **確認 Asset 資訊**
    - **檔案路徑**：本地絕對路徑或相對路徑
    - **檔案類型**：Image / Document / Binary
    - **檔案大小**：自動檢查（GitLab ≤10MB, GitHub ≤100MB）

2. **確認目標平台與專案**
    - **平台**：GitLab / GitHub（若未指定，嘗試從 Remote URL 偵測）
    - **專案識別碼**：
        - **優先**：使用者明確提供 `owner/repo` 或 `group/project`
        - **支援**：Project ID（數字，僅 GitLab）
        - **自動偵測**：若未提供，執行 `git remote -v` 解析 Remote URL
    - **關聯資源**：
        - Issue / MR / PR ID
        - Release Tag
        - Commit SHA
        - 或僅為一般檔案上傳

3. **事實查證 (Facts)**
    - **若提供字串**（`owner/repo`）→ 呼叫 API Manager 查詢 Project ID（GitLab）
    - **若提供數字** → 直接使用（GitLab）
    - **若自動偵測** → 驗證 Remote URL 格式，解析平台與專案
    - 確認資源存在與上傳權限

### 步驟二：驗證與規劃 (Validation & Planning)

1. **檔案驗證**
    - ✅ 檔案存在且可讀取
    - ✅ 大小符合平台限制
    - ✅ 類型在白名單內（PNG/JPG/GIF/SVG/WebP/PDF/ZIP/TXT）
    - ⚠️ 建議掃描惡意檔案（基本副檔名檢查）

2. **專案 ID 解析策略**
    - **GitLab**：
        - 若輸入是數字 → 直接使用
        - 若輸入是 `group/project` → 呼叫 `GET /api/v4/projects?search=...` 取得 ID
        - 若自動偵測 → 從 Remote URL 提取 `group/project`，再查詢 ID
    - **GitHub**：
        - 直接使用 `owner/repo` 字串（GitHub API 支援字串識別碼）
        - 若輸入是數字 ID → 呼叫 `GET /api/v3/repos/:id` 轉換為 `owner/repo`

3. **選擇上傳策略**
    - **GitLab**:
        - 一般上傳：`POST /api/v4/projects/:id/uploads`
        - Release Assets: `POST /api/v4/projects/:id/releases/:tag/assets/links`
    - **GitHub**:
        - Release Assets: `POST /api/v3/repos/:owner/:repo/releases/:id/assets`
        - Issue Attachments: `POST /api/v3/repos/:owner/:repo/issues/:number/attachments`

4. **決策點 (Decisions)**
    - 若檔案超過限制 → 提供壓縮或外部連結選項
    - 若專案偵測失敗 → 提示使用者手動輸入 `owner/repo`
    - 若資源不存在 → 確認 ID 是否正確

### 步驟三：執行上傳 (Execute Upload)

1. **呼叫對應平台 API**
    - 使用已認證的 Token（從 API Manager 或 Secure Storage）
    - 設定正確的 `Content-Type` 與 `Accept` 頭

2. **錯誤處理與重試**
    - **自動重試機制**：網路錯誤時重試最多 3 次
    - **重試間隔**：指數退避（1s → 2s → 4s）
    - **錯誤分類**：
        - `401/403` → 權限問題，停止重試，提示檢查權限
        - `413` → 檔案過大，停止重試，提供替代方案
        - `5xx` → 伺服器錯誤，執行重試

3. **回傳結果**
    - **成功**：提供公開存取連結、MD5 校驗碼、檔案元資料
    - **失敗**：詳細錯誤訊息、建議解決方案

### 步驟四：關聯資源 (Link to Resource)

**與 API Manager 協作**：

- 若為 Issue/MR/PR 附件 → 呼叫對應 API Manager 將連結附加到資源
- 若為 Release Asset → 呼叫 API Manager 更新 Release 資訊
- 若為一般上傳 → 僅回傳連結，由使用者決定如何使用

---

## ⚠️ 約束與規則 (Constraints & Rules)

### 安全性 (Security)

- **檔案類型白名單**：僅允許 Image (PNG/JPG/GIF/SVG/WebP)、PDF、ZIP、TXT
- **禁止執行檔**：嚴禁上傳 .exe、.bat、.sh、.ps1 等可執行檔
- **病毒掃描建議**：上傳前建議執行基本掃描（可整合 ClamAV）
- **Token 保護**：上傳過程使用 HTTPS，Token 絕不明文輸出

### 平台限制

| 平台   | 單檔案上限 | 支援類型                         | API 端點                                         |
| ------ | ---------- | -------------------------------- | ------------------------------------------------ |
| GitLab | 10 MB      | 任意檔案                         | `/api/v4/projects/:id/uploads`                   |
| GitHub | 100 MB     | 任意檔案（建議圖片/文档/壓縮檔） | `/api/v3/repos/:owner/:repo/releases/:id/assets` |

### 事實與決策分離

- **Facts**：檔案大小、類型、資源存在性、權限狀態必須從 API 真實取得
- **Decisions**：上傳策略、重試次數、替代方案需向使用者確認

### 協作規範

- **不直接修改資源**：Asset Manager 僅負責上傳，不修改 Issue/MR/Release 內容
- **明確分工**：
    - Asset Manager：檔案處理、上傳、回傳連結
    - API Manager：資源管理、關聯、內容更新

---

## 🔧 實作參考 (Implementation Reference)

### 專案 ID 解析與 Git Remote 偵測 (Python)

```python
import subprocess
import re
import requests

def detect_git_remote():
    """自動偵測 Git Remote URL 並解析平台與專案"""
    try:
        result = subprocess.run(
            ['git', 'remote', '-v'],
            capture_output=True,
            text=True,
            check=True
        )

        # 解析第一行 remote (origin)
        lines = result.stdout.strip().split('\n')
        if not lines:
            return None

        # 格式：origin  https://gitlab.com/group/project.git (fetch)
        remote_url = lines[0].split('\t')[1].split()[0]

        # 解析 URL
        patterns = {
            'gitlab': r'(?:gitlab\.com|git\.lab\.com)[/:]([^/]+/[^\.]+)',
            'github': r'(?:github\.com)[/:]([^/]+/[^\.]+)'
        }

        for platform, pattern in patterns.items():
            match = re.search(pattern, remote_url)
            if match:
                return {
                    'platform': platform,
                    'project': match.group(1).replace('.git', ''),
                    'remote_url': remote_url
                }

        return None
    except subprocess.CalledProcessError:
        return None

def resolve_project_id(project_identifier: str, platform: str, api_token: str, base_url: str):
    """
    解析專案識別碼為 API 可用的 Project ID
    - GitLab: 返回數字 ID
    - GitHub: 返回 owner/repo 字串
    """
    if platform == 'github':
        # GitHub 直接使用 owner/repo
        if project_identifier.isdigit():
            # 若輸入是數字 ID，需查詢轉換
            response = requests.get(
                f'{base_url}/api/v3/repositories/{project_identifier}',
                headers={'Authorization': f'token {api_token}'}
            )
            if response.status_code == 200:
                data = response.json()
                return f"{data['owner']['login']}/{data['name']}"
        return project_identifier

    elif platform == 'gitlab':
        if project_identifier.isdigit():
            return int(project_identifier)

        # 查詢 Project ID
        response = requests.get(
            f'{base_url}/api/v4/projects',
            params={'search': project_identifier},
            headers={'PRIVATE-TOKEN': api_token}
        )

        if response.status_code == 200:
            projects = response.json()
            # 精確匹配
            for project in projects:
                if project['path_with_namespace'] == project_identifier:
                    return project['id']
            # 模糊匹配取第一筆
            if projects:
                return projects[0]['id']

        raise ValueError(f'找不到專案：{project_identifier}')

    raise ValueError(f'不支援的平台：{platform}')
```

### 檔案驗證範例 (Python)

```python
import os
import magic

ALLOWED_TYPES = {
    'image': ['image/png', 'image/jpeg', 'image/gif', 'image/svg+xml', 'image/webp'],
    'document': ['application/pdf', 'text/plain'],
    'archive': ['application/zip']
}

MAX_SIZES = {
    'gitlab': 10 * 1024 * 1024,  # 10 MB
    'github': 100 * 1024 * 1024  # 100 MB
}

def validate_file(file_path: str, platform: str) -> dict | None:
    """驗證檔案是否符合上傳條件"""
    if not os.path.exists(file_path):
        return {'error': '檔案不存在'}

    file_size = os.path.getsize(file_path)
    if file_size > MAX_SIZES[platform]:
        return {'error': f'檔案過大 ({file_size} bytes)，{platform} 限制為 {MAX_SIZES[platform]} bytes'}

    file_type = magic.from_file(file_path, mime=True)
    is_allowed = any(file_type in types for types in ALLOWED_TYPES.values())
    if not is_allowed:
        return {'error': f'不支援的檔案類型：{file_type}'}

    return {
        'valid': True,
        'size': file_size,
        'type': file_type,
        'md5': calculate_md5(file_path)
    }

def calculate_md5(file_path: str) -> str:
    """計算檔案 MD5 校驗碼"""
    import hashlib
    hash_md5 = hashlib.md5()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()
```

### 重試機制範例 (Python)

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

def create_retry_session():
    """建立具有重試機制的 Session"""
    session = requests.Session()
    retry = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[500, 502, 503, 504],
        allowed_methods=['POST']
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('https://', adapter)
    return session

def upload_asset(session, url: str, file_path: str, token: str) -> dict:
    """上傳 Asset 並處理重試"""
    headers = {'PRIVATE-TOKEN': token} if 'gitlab' in url else {'Authorization': f'token {token}'}

    with open(file_path, 'rb') as f:
        files = {'file': f}
        response = session.post(url, headers=headers, files=files)

    if response.status_code == 200 or response.status_code == 201:
        return {'success': True, 'data': response.json()}
    elif response.status_code in [401, 403, 413]:
        return {'success': False, 'error': f'錯誤 {response.status_code}: {response.json().get("message", "未知錯誤")}'}
    else:
        return {'success': False, 'error': f'上傳失敗：{response.text}'}
```

---

## 📚 參考資源 (References)

- **GitLab File Uploads**: https://docs.gitlab.com/ee/api/project_file_uploads.html
- **GitLab Release Assets**: https://docs.gitlab.com/ee/api/release_links.html
- **GitHub Release Assets**: https://docs.github.com/en/rest/releases/assets?apiVersion=2022-11-28
- **GitHub Issue Attachments**: https://docs.github.com/en/rest/issues/attachments?apiVersion=2022-11-28
- **MIME Type Detection**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types

---

## 🔄 使用範例 (Usage Examples)

### 範例 1：上傳圖片到 GitLab Issue

```
使用者：在 GitLab 專案 my-project 的 Issue #123 上傳圖片 error.png
Asset Manager:
  1. 驗證 error.png (大小、類型)
  2. 呼叫 GitLab API Manager 確認 Issue #123 存在
  3. 上傳至 /api/v4/projects/:id/uploads
  4. 回傳連結：https://gitlab.com/uploads/...
  5. 呼叫 GitLab API Manager 將連結附加到 Issue
```

### 範例 2：上傳 Release Asset 到 GitHub

```
使用者：上傳 v1.2.3 的 Release Asset release-notes.pdf
Asset Manager:
  1. 驗證 release-notes.pdf
  2. 呼叫 GitHub API Manager 取得 Release ID (由 tag v1.2.3)
  3. 上傳至 /api/v3/repos/:owner/:repo/releases/:id/assets
  4. 回傳公開連結與 MD5 校驗碼
```

---

## 🚧 未來擴充方向 (Future Enhancements)

- [ ] **A2 擴充**：圖片壓縮、縮圖生成、格式轉換
- [ ] **C2 擴充**：斷點續傳（支援 >50MB 大檔案）
- [ ] **外部儲存**：整合 S3、Cloudflare R2、Azure Blob
- [ ] **CDN 整合**：自動生成加速連結
- [ ] **版本控制**：Asset 版本管理與歷史追蹤
