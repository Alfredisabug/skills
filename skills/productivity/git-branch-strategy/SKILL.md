---
name: git-branch-strategy
description: 當使用者要求建立 Git 分支、合併分支或執行版本控制流程時使用。
disable-model-invocation: false
---

# Git Branch Strategy (Git 分支策略規範)

## 🎯 執行步驟 (Execution Steps)

1. **確認目標與命名 (Identify Goal & Naming)**
   - 釐清當前任務屬於：新功能 (feature)、一般修復 (fix) 或緊急修復 (hotfix)。
   - **決策**：如果使用者未提供具體的分支後綴 (`xxx`)，**必須暫停並主動向人類請教**，不可自行猜測命名。

2. **建立分支 (Create Branch)**
   - `feature/xxx`：從 `develop` 分支建立。
   - `fix/xxx`：從 `develop` 分支建立。
   - `hotfix/xxx`：從 `main` 分支建立（針對正式環境嚴重問題）。

3. **合併與進版 (Merge & Release)**
   - `feature/xxx` & `fix/xxx`：開發與驗證完成後，合併回 `develop`。
   - `hotfix/xxx`：修復完成後，**必須同時合併回 `main` 與 `develop`**。
   - **進版**：當 `develop` 準備發布時，合併回 `main`。`main` 的推進即代表新版本發布。

## ⚠️ 約束與規則 (Constraints & Rules)

- **No Fast-Forward (`--no-ff`)**：**嚴禁使用 fast-forward 合併**。所有分支合併必須強制加上 `--no-ff` 保留 merge commit，以維護清晰的 Git Graph。
- **命名強制使用斜線**：必須為 `feature/xxx`、`fix/xxx`、`hotfix/xxx` 格式，嚴禁使用連字號 (`feature-xxx`)。
- **`main` 的唯一來源**：除了 `hotfix/xxx` 之外，`main` **只能**從 `develop` 接受合併。
