---
name: git-asset-manager
description: 當使用者要求上傳、管理或附加檔案至 GitHub/GitLab (Release Assets、Issue/PR/MR 附件等) 時使用。優先使用 gh/glab CLI，備用 REST API。
---

# Git Asset Manager SOP

## 🎯 核心目標

處理 Git 遠端平台（GitHub 與 GitLab）的檔案上傳與資產關聯，包含：
1. **Release 二進位資產發布**（安裝包、ZIP、韌體 `.bin`/`.hex`、編譯成品）。
2. **Issue / PR / MR 附件與截圖上傳**（Log 檔、錯誤截圖、說明文件）。

**原則：優先使用官方 CLI (`gh` / `glab`)，無 CLI 環境時回退使用 REST API。**

---

## 📋 執行步驟 (Execution Steps)

### 步驟一：檔案與環境查驗 (File & Context Verification)

1. **查驗檔案 (Facts)**：
   - 確認本地檔案存在且路徑正確。
   - 檢查檔案大小與平台限制：
     - **GitHub Release Asset**：單檔上限 2 GB。
     - **GitLab Uploads**：單檔預設上限 10 MB ~ 100 MB（依自架實例配置）。
   - 嚴禁上傳未經驗證的敏感資訊（如 `.env`、憑證私鑰、未編譯的機密配置）。

2. **確認目標平台與專案 (Facts)**：
   - 執行 `git remote -v` 判斷當前為 GitHub 還是 GitLab，並取得 `owner/repo` 或專案路徑。
   - 若使用者未指定目標 Tag 或 Issue/MR ID，主動確認。

---

### 步驟二：執行上傳操作 (Execute Upload via CLI)

#### 🐙 1. GitHub 平台

* **建立 Release 並同時上傳資產 (一步到位 / 推薦)**：
  ```bash
  gh release create <tag_name> <file_paths...> --title "<title>" --notes "<notes>"
  ```

* **向「已存在」的 Release 追加資產 (Release Assets)**：
  ```bash
  # 基本發布
  gh release upload <tag_name> <file_path>

  # 覆蓋已存在的同名資產 (需先與使用者確認)
  gh release upload <tag_name> <file_path> --clobber
  ```

* **下載 Release 資產**：
  ```bash
  gh release download <tag_name> -p "<pattern>"
  ```

* **刪除 Release 資產**：
  ```bash
  gh release delete-asset <tag_name> <asset_name> -y
  ```

---

#### 🦊 2. GitLab 平台

* **建立 Release 並同時附加資產 (一步到位 / 推薦)**：
  ```bash
  glab release create <tag_name> <file_paths...> --name "<title>" --notes "<notes>"
  ```

* **向「已存在」的 Release 追加資產 (Release Assets)**：
  ```bash
  # 上傳檔案並關聯至既有 Release（若 tag 名稱含斜線如 release/v1.0，部分環境需 URL 編碼如 release%2Fv1.0）
  glab release upload <tag_name> <file_path>
  ```
  > ⚠️ **注意**：`glab` **不支援** `--clobber` 參數。若需替換同名資產，需先透過 API 或 Web UI 刪除既有資產後再重新上傳。

* **上傳通用專案附件 (Issue / MR / 討論區使用)**：
  ```bash
  glab upload <file_path>
  ```
  *輸出範例*：`{"alt": "error", "url": "/uploads/12345/error.png", "markdown": "![error](/uploads/12345/error.png)"}`

* **下載 Release 資產**：
  ```bash
  glab release download <tag_name>
  ```

---

#### 🌐 3. REST API 備用方案 (無 CLI 工具時)

* **GitHub Release Asset 上傳 (REST)**：
  ```bash
  # 需先取得 release_id
  curl -H "Authorization: token $GH_TOKEN" \
       -H "Content-Type: application/octet-stream" \
       --data-binary @"<file_path>" \
       "https://uploads.github.com/repos/<owner>/<repo>/releases/<release_id>/assets?name=<file_name>"
  ```

* **GitLab 通用上傳 (REST)**：
  ```bash
  curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
       --form "file=@<file_path>" \
       "https://<gitlab_host>/api/v4/projects/<project_id>/uploads"
  ```

---

### 步驟三：產出引用語法與協作 (Markdown Formatting & Linking)

1. **自動生成 Markdown 引用語法**：
   - 圖片類：`![<檔案名稱>](<上傳後回傳之公開_URL>)`
   - 文件/壓縮檔類：`[下載 <檔案名稱>](<上傳後回傳之公開_URL>)`

2. **跨 Skill 協作**：
   - 若上傳目的為補充 Issue / PR 內容，產出 Markdown 後轉交由 [`github-api-manager`](../github-api-manager/SKILL.md) 或 [`gitlab-api-manager`](../gitlab-api-manager/SKILL.md) 附加至指定 Issue / PR / MR。

---

## ⚠️ 約束與規則 (Constraints & Rules)

### 安全性 (Security)
* **禁止洩漏金鑰**：嚴禁上傳包含 API Key、PAT、私鑰或密碼的檔案。
* **破壞性覆蓋確認 (Decisions)**：覆蓋同名 Release Asset（GitHub 的 `--clobber`）或刪除資產前，必須取得使用者確認。

### 事實與決策分離 (Facts vs. Decisions)
* **Facts**：檔案大小、SHA256 校驗碼、遠端 Release Tag 存在性必須透過指令真實取得。
* **Decisions**：Release 版本命名、是否覆蓋舊檔案、資產名稱變更需由使用者指示。

### 平台與環境相容性 (Platform & Environment Guidelines)
* **Release 建立策略**：若 Release 尚未建立，優先使用 `create` 一步到位（`glab release create <tag> <files...>` / `gh release create <tag> <files...>`），避免分步上傳因 Release 尚不存在報 404。
* **Tag 名稱含斜線**：若 Tag 名稱含有斜線（如 `release/v1.0`），在 `upload` 或 REST API 端點呼叫時需進行 URL 編碼（如 `release%2Fv1.0`）。
* **CLI 旗標差異（嚴禁混用）**：
  - Release 名稱：GitHub 用 `--title`；GitLab 必須用 `--name`（或 `-n`）。
  - 覆蓋檔案：`--clobber` 僅為 GitHub CLI (`gh`) 專有旗標，GitLab CLI (`glab`) 並無此參數。
  - 刪除資產：GitHub 有 `gh release delete-asset`；GitLab 需透過 REST API 或 Web 介面刪除資產連結。
* **路徑處理（特別是 Windows）**：路徑參數應優先使用相對路徑，並保持指令單行無多餘換行符號，避免系統 `CreateFile` 因換行字元報語法錯誤。
* **GitLab 依賴機制**：GitLab CLI 發布 Release 資產底層會託管於 Generic Package Registry，需確保專案已啟用 Package Registry 且 Token 具備足夠權限。


