# Git Asset Manager

## 🎯 核心功能

管理 Git 遠端平台（GitHub / GitLab）的檔案上傳與 Release 資產，包含：
- **Release Assets**：發布安裝包、二進位執行檔、韌體檔與壓縮包。
- **附件上傳**：上傳圖片、Log 檔至 Issue、PR 或 MR 討論串。

## 📋 使用時機

- 發布新版本時需要上傳建置產物（`gh release upload` / `glab release upload`）。
- 在 Issue 或 PR 留言中需要附帶截圖或診斷檔案（`glab upload`）。
- 下載或管理遠端 Release 的資產檔案。

## 🔗 相關 Skill

- [`github-api-manager`](../github-api-manager/SKILL.md)
- [`gitlab-api-manager`](../gitlab-api-manager/SKILL.md)
- [`git-commit-message`](../git-commit-message/SKILL.md)
- [`git-branch-strategy`](../git-branch-strategy/SKILL.md)
