# Asset Manager

## 🎯 核心功能

統一處理檔案上傳與附件管理，支援 GitLab 和 GitHub 平台。

## 📋 使用時機

當使用者要求：
- ✅ 上傳圖片到 Issue/MR/PR
- ✅ 建立 Release 並上傳 Asset
- ✅ 附加檔案到 Commit 或 Pipeline
- ✅ 管理檔案版本與連結

## 🔄 工作流程

```
使用者請求上傳
    ↓
Asset Manager 驗證檔案
    ↓
解析專案識別碼
    ├→ 明確提供 owner/repo → 查詢 Project ID
    ├→ 提供數字 ID → 直接使用 (GitLab)
    └→ 未提供 → 自動偵測 Git Remote
    ↓
呼叫對應 API Manager 確認資源
    ├→ GitLab API Manager (若目標是 GitLab)
    └→ GitHub API Manager (若目標是 GitHub)
    ↓
執行上傳並回傳連結
    ↓
API Manager 將連結關聯到資源
```

## ⚙️ 技術規格

| 項目       | GitLab                             | GitHub            |
|------------|------------------------------------|-------------------|
| 單檔案上限 | 10 MB                              | 100 MB            |
| 支援類型   | 任意檔案                           | 任意檔案          |
| 重試機制   | ✅ 3 次 (指數退避)                  | ✅ 3 次 (指數退避) |
| ID 解析    | ✅ 自動查詢 / 手動輸入 / Git Remote | ✅ owner/repo      |
| 斷點續傳   | ❌ (MVP)                            | ❌ (MVP)           |
| CDN 整合   | ❌ (Future)                         | ❌ (Future)        |

## 🔗 相關 Skill

- [`gitlab-api-manager`](../gitlab-api-manager/SKILL.md)
- [`github-api-manager`](../github-api-manager/SKILL.md)

## � 使用範例 (Usage Examples)

### 範例 1：明確提供專案資訊

```
使用者：在 GitLab 專案 my-group/my-project 的 Release v1.2.3 上傳圖片 error.png

執行流程：
1. Asset Manager 驗證 error.png (大小、類型)
2. 解析專案：my-group/my-project → 呼叫 GitLab API 查詢 Project ID (12345)
3. 上傳至 /api/v4/projects/12345/releases/v1.2.3/assets/links
4. 回傳連結：https://gitlab.com/uploads/...
5. GitLab API Manager 確認 Asset 已關聯到 Release
```

### 範例 2：自動偵測 Git Remote

```
使用者：在當前專案的 Release v2.0.0 上傳檔案 installer.exe
(使用者位於: /projects/my-app/)

執行流程：
1. 執行 git remote -v → 取得 https://github.com/owner/my-app.git
2. 自動偵測：平台=github, 專案=owner/my-app
3. 驗證 installer.exe (大小 ≤100MB)
4. 呼叫 GitHub API Manager 取得 Release ID (由 tag v2.0.0)
5. 上傳至 /api/v3/repos/owner/my-app/releases/:id/assets
6. 回傳公開連結：https://github.com/.../releases/download/v2.0.0/installer.exe
```

### 範例 3：使用 Project ID (GitLab)

```
使用者：在 GitLab 專案 12345 的 Issue #789 上傳附件

執行流程：
1. 直接使用 Project ID: 12345 (無需查詢)
2. 驗證附件檔案
3. 上傳至 /api/v4/projects/12345/uploads
4. 回傳連結並附加到 Issue #789
```

## �🚧 未來擴充

- [ ] 圖片壓縮與縮圖生成
- [ ] 斷點續傳 (大檔案支援)
- [ ] 外部儲存 (S3、Cloudflare R2)
- [ ] CDN 加速連結
- [ ] Asset 版本控制
