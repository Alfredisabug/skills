---
name: setup-alfred-skills
description: 當使用者要求在專案中初始化 Alfred Skills 配置、設定 AGENTS.md 或配置 VS Code Copilot 規則時使用。
---

# Setup Alfred Skills SOP

本技能負責在目標專案中自動生成、配置與維護 Alfred Agent Skills 的執行環境與路由協議。

---

## 1. 執行目標與原則 (Goals & Principles)

1. **零痛點配置 (Zero-Friction)**：自動檢查目標專案現況，依據所使用的 AI Agent 自動建立必要的設定檔。
2. **多 Agent 相容 (Multi-Agent Compatibility)**：
    - **Antigravity / Gemini CLI / 通用 Agent**：配置根目錄 `AGENTS.md` 技能路由與工作流目錄。
    - **VS Code Copilot (含 BYOK)**：配置 `.github/copilot-instructions.md` 與可選的 `.github/prompts/`。
    - **Claude Code / Cursor / Windsurf**：相容 `.agents/skills/` 規範。
3. **專案無污染 (Non-Intrusive)**：預設尊重專案原有的 Git 狀態，可選擇將技能與工作流檔案加入 `.git/info/exclude` 或 `.gitignore`，避免污染團隊 Git 歷史。

---

## 2. 執行步驟 (Step-by-Step Procedure)

### 步驟一：環境與專案偵測 (Environment Detection)

1. **偵測專案根目錄結構**：
    - 檢查是否已有 `.agents/skills/`（代表已透過 `npx skills add` 安裝技能）。
    - 檢查是否已有 `AGENTS.md`、`.github/copilot-instructions.md` 或 `.gitignore`。
    - 檢查是否為 Git 專案（是否存在 `.git` 目錄）。
2. **盤點已安裝的技能**：
    - 掃描 `.agents/skills/` 目錄，取得已安裝的技能清單與各技能的 `SKILL.md` 描述。

---

### 步驟二：建立工作流與暫存目錄 (Setup Artifacts Directories)

建立標準 Agent 工作流資料夾（若不存在）：

- `.agents/plans/`：用於存放 AI 需求分析、執行規劃 (Plan) 或工作拆解記錄。
- `.agents/implements/`：用於存放過渡暫存檔、臨時除錯腳本、驗證草稿，避免污染主程式庫。

---

### 步驟三：生成或更新 `AGENTS.md` (通用 Agent 路由入口)

1. 若專案根目錄尚未存在 `AGENTS.md`，建立新檔案。
2. 若已存在 `AGENTS.md`，檢查是否已包含路由協議標記；若無，將以下區塊附加至檔案結尾（保留專案既有內容）：

```markdown
## <!-- BEGIN ALFRED AI SKILLS -->

## 🚨 通用技能庫路由協議 (Universal Skills Routing Protocol)

本專案已啟用 Alfred Agent Skills 規範。在處理專案任務時，AI 助理在每一輪對話 (Every Single Turn) 都應優先比對並遵循 `.agents/skills/` 底下的對應技能規範：

- **持續性 (Persistence)**：一旦套用特定領域技能，後續追問、修改與除錯皆持續遵循該技能規範。
- **領域切換 (Context Switch)**：當任務轉移至新領域（例如改寫程式碼後轉為撰寫 Git Commit 或管理 Python 環境），需即時載入新領域之 SKILL.md。
- **規劃與實作隔離**：規劃記錄請存於 `.agents/plans/`，臨時腳本存於 `.agents/implements/`。
  <!-- END ALFRED AI SKILLS -->
```

---

### 步驟四：生成或更新 VS Code Copilot 指引 (Copilot Instructions)

若專案使用 VS Code 或包含 `.github` 目錄：

1. 確保建立 `.github/` 目錄。
2. 在 `.github/copilot-instructions.md` 中檢查或寫入強制定錨協議與技能對照表：

```markdown
## <!-- BEGIN ALFRED AI SKILLS -->

## 🚨 核心技能路由協議 (Copilot Skills Protocol)

本專案包含以下已安裝的 Agent Skills（位於 `.agents/skills/`）：

- 當使用者需求符合特定技能領域時，在回覆前**請主動讀取對應的 `.agents/skills/<skill-name>/SKILL.md`** 並嚴格遵循其規範。
- 支援每輪定錨標籤：例如 `> 💡 [Skill Applied: <技能名稱>]`，確保跨輪對話規範不被遺忘。
  <!-- END ALFRED AI SKILLS -->
```

3. **Prompt Files 支援（選用）**：
   若使用者需要 Copilot Chat 的斜線選單快速呼叫常用 Prompt（`*.prompt.md`），可協助在 `.github/prompts/` 建立常用提示範本。

---

### 步驟五：Git 排除與隱私保護 (Git Hygiene)

詢問使用者或依專案情境設定忽略規則：

- **個人獨享模式 (推薦，不改動專案 .gitignore)**：
  將以下項目附加至 `.git/info/exclude`：
    ```text
    .agents/
    AGENTS.md
    .github/copilot-instructions.md
    .github/prompts/
    skills-lock.json
    ```
- **團隊共用模式**：
  若該技能庫與規範屬於團隊共同資產，則將 `.agents/skills/` 與 `skills-lock.json` 提交至版本控制，但將 `.agents/implements/` 加入 `.gitignore`。

---

### 步驟六：回報與驗證 (Verification & Feedback)

向使用者列出：

1. 已配置的檔案與目錄清單。
2. 目前已偵測並生效的技能清單。
3. 提示使用者後續可直接輸入對應指令或自然語言觸發各技能。
