---
name: git-commit-message
description: 當使用者要求撰寫、生成或審查 Git Commit Message 時使用。
---

# Git Commit Message SOP

## 1. 執行步驟 (Execution Steps)

### 步驟一：收集事實 (Context)
- 執行 `git status` 與 `git diff --staged` 讀取暫存區變更事實。
- 若暫存區 (Staging area) 為空，讀取 `git diff` 並提醒使用者是否需要 `git add`。

### 步驟二：分類與規劃 (Plan)
- 根據 `git diff` 分析變更意圖，分類為以下 **Conventional Commit Types**：
  - **`feat`**: New feature or functionality.
  - **`fix`**: Bug fix.
  - **`docs`**: Documentation only changes.
  - **`style`**: Code formatting, punctuation, white-space (no logic change).
  - **`refactor`**: Code refactoring (no bug fix, no new feature).
  - **`chore`**: Maintenance, dependencies, build or tool configuration.
- **決策點 (Decisions)**：若變更過於龐大或包含多個無關修改，主動建議拆分 Commit，請使用者指示，不自行決定併入單一 Commit。

### 步驟三：生成 Commit Message (Execute)
- **必須使用全英文 (English)** 撰寫 Commit Message。
- 採用 **Conventional Commits** 格式：
  ```text
  <type>(<scope>): <imperative summary>

  [optional body]
  ```
- **Header 規範**：
  - 長度不超過 50 字元，句尾不加句點。
  - 使用祈使句動詞 (e.g., `add`, `fix`, `refactor`, `update`, `remove`)。
  - `<scope>` 為選填，代表受影響模組 (e.g., `auth`, `driver`, `parser`)。
- **Body 規範 (選填)**：僅在複雜變更時提供，說明修改原因與背景 (Why & What)，而非實作細節 (How)。

## 2. 約束與規則 (Constraints & Rules)

- **English Only**: Commit header 與 body 必須為全英文。
- **Strict Diff Facts**: 訊息內容必須完全符合 `git diff` 內容，嚴禁捏造或假設未發生的變更。
