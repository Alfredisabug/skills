# Alfred's Agent Skills 🚀

相容於標準 **Agent Skills 規範**（相容 `npx skills` / [skills.sh](https://skills.sh)），支援 **GitHub Copilot (含 BYOK)**、**Antigravity**、**Claude Code**、**Cursor**、**Windsurf** 等現代 AI 輔助開發工具。

---

## ⚡ 快速開始 (Quick Start)

透過 `npx skills`，你可以在任何專案甚至全域開發環境中，直接安裝與管理技能，無需手動複製或建立軟連結。

### 推薦方式：全域安裝 (Global Install，最少操作、零專案污染)
如果你希望本機所有專案的 AI 工具（Copilot、Antigravity、Cursor 等）都能直接使用這些技能，只需在終端機執行一次：

```bash
# 全域安裝所有技能
npx skills add Alfredisabug/skills --all -g

# 或透過互動式選單挑選需要的技能：
npx skills add Alfredisabug/skills -g
```

> [!TIP]
> 全域安裝會將技能註冊於本機使用者目錄（如 `~/.agents/skills/` 或各 Agent 全域配置中）。你的程式碼專案庫完全不需要更動任何檔案，即可讓 AI 直接享有專案規範與工作流支援！

---

### 專案層級安裝 (Project-Level Install)
若希望特定專案與團隊成員共用相同技能，請在專案根目錄下執行：

```bash
# 互動式選單挑選：
npx skills add Alfredisabug/skills

# 一鍵安裝所有技能：
npx skills add Alfredisabug/skills --all

# 指定安裝特定技能 (例如：git-commit-message 與 setup-alfred-skills)：
npx skills add Alfredisabug/skills --skill git-commit-message --skill setup-alfred-skills
```

### 更新技能 (Update Skills)
```bash
# 更新專案內已安裝的技能
npx skills update

# 更新全域安裝的技能
npx skills update -g
```

---

## 🛠️ 自動化專案配置：`setup-alfred-skills`

首次在專案中使用時，只要安裝了 `setup-alfred-skills`，AI 助理即可自動為目標專案完成環境建置：

1. **安裝初始化技能**：
   ```bash
   npx skills add Alfredisabug/skills --skill setup-alfred-skills
   ```
2. **喚醒 AI 助理執行初始化**：
   在 VS Code Copilot Chat、Antigravity 或任何對話介面中輸入：
   > 「請執行 `/setup-alfred-skills` 初始化專案配置」
3. **自動完成的事項**：
   - 建立專案工作流目錄（`.agents/plans/` 與 `.agents/implements/`）。
   - 生成或更新 `AGENTS.md` 通用技能路由協議。
   - 生成或更新 `.github/copilot-instructions.md`（讓 VS Code Copilot 自動依任務載入技能）。
   - （選用）將技能與工作流檔案加入 `.git/info/exclude`，確保專案 Git 歷程純淨。

---

## 🤖 VS Code Copilot Chat (BYOK) 建置指引

VS Code Copilot 現已支援 **BYOK (Bring Your Own Key / 自訂模型與自訂端點)**（如 Anthropic Claude 3.7 Sonnet、OpenAI GPT-4o、DeepSeek R1/V3、或 Ollama 本地模型）。在 BYOK 環境下，Copilot 核心仰賴 **Instruction 規範** 與 **Prompt Files** 來實現精準工作流。

### 1. 安裝技能至 GitHub Copilot
在目標專案目錄執行：
```bash
npx skills add Alfredisabug/skills -a github-copilot --all
```
此指令會將技能自動佈署至 `.agents/skills/`，並由 Copilot 自動索引。

### 2. 配置 Copilot Instructions
Copilot Chat 會在每一輪對話自動載入 `.github/copilot-instructions.md`。透過執行 `setup-alfred-skills` 或手動建立該檔案，加入以下指令路由規範：

```markdown
# Workspace Instructions & Skills

## 🚨 核心技能路由協議 (Skills Protocol)
本專案已安裝 Agent Skills（位於 `.agents/skills/`）：
- 當需求符合特定領域時，請先讀取對應的 `.agents/skills/<skill-name>/SKILL.md` 並嚴格遵循規範。
- 每次回覆最上方請輸出定錨標籤（如 `> 💡 [Skill Applied: <技能名稱>]`），確保跨輪對話規範持續生效。
```

### 3. 使用 VS Code 原生 Prompt Files (`.github/prompts/`)
本儲存庫的 `prompts/` 資料夾提供了常用的提示範本（`*.prompt.md`）：
- `資深韌體工程師重構建議.prompt.md`
- `cfpCodeFormaterReview.prompt.md`
- `stm32g4_baremetal.prompt.md`
- `ti_c2000_f28p_driver.prompt.md`

**使用方式**：
- 將這些檔案拷貝至專案的 `.github/prompts/` 目錄。
- 在 VS Code Copilot Chat 輸入框中輸入 `/`，即可在原生選單中看到自訂指令（例如 `/資深韌體工程師重構建議`），一鍵代入專屬系統提示。

---

## 📚 可用技能列表 (Available Skills)

| 技能名稱 (`name`)               | 領域分類     | 用途說明                                                           |
|:--------------------------------|:-------------|:-------------------------------------------------------------------|
| `setup-alfred-skills`           | Productivity | 目標專案首次執行時自動生成 `AGENTS.md`、Copilot 指引與工作流環境。   |
| `git-commit-message`            | Productivity | 依據暫存區差異自動生成 Conventional Commits 英文 Commit Message。   |
| `git-branch-strategy`           | Productivity | Git 分支命名、開發流程與發佈策略規範。                               |
| `git-asset-manager`             | Productivity | 透過 CLI 或 API 自動上傳與管理 GitHub / GitLab Release 資產與附件。 |
| `github-api-manager`            | Productivity | 操作 GitHub Issues、Pull Requests、Actions 等 REST / GraphQL / CLI。  |
| `gitlab-api-manager`            | Productivity | 操作 GitLab Issues、Merge Requests、Pipelines 等 REST API / CLI。     |
| `grillme-productivity`          | Productivity | 產品與工作流深入對齊引導（Product Grill Me）。                        |
| `write-great-skill`             | Productivity | 撰寫、重構與優化高規格 AI Skill SOP。                                |
| `python-uv-environment`         | Engineering  | 使用 modern uv 快速管理 Python 虛擬環境與依賴套件。                 |
| `pyside6-gui-generator`         | Engineering  | PyQt6 / PySide6 桌面 GUI 程式架構與代碼生成。                       |
| `python-clean-architecture-gui` | Engineering  | Python GUI 潔淨架構與 DDD 領域驅動設計實作。                        |
| `c-clean-architecture-firmware` | Engineering  | C 語言 MCU / RTOS 韌體 Clean Architecture 與硬體解耦設計。          |
| `stm32g4-bare-metal-driver`     | Engineering  | STM32G4 (Cortex-M4F) 底層暫存器驅動開發與審核規範。                 |
| `ti-c2000-f28p-driver`          | Engineering  | TI C2000 F28P 系列底層暫存器驅動開發規範。                          |
| `grillme-engineering`           | Engineering  | 資深軟體架構師引導式提問，深挖工程技術盲點與邊界條件。               |

---

## 🧹 舊版使用者遷移指南 (Migration from Legacy Symlink)

如果你過去曾使用根目錄的 `link.ps1` 或 `link.sh` 進行本機軟連結掛載：

1. **一鍵清理舊專案的軟連結與配置**：
   在**目標專案根目錄**下執行：
   ```powershell
   # Windows (PowerShell)
   & <本儲存庫路徑>\deprecated\link.ps1 -Clean
   ```
   ```bash
   # Linux / macOS (Bash)
   bash <本儲存庫路徑>/deprecated/link.sh --clean
   ```
2. **切換為新版 `npx skills` 安裝**：
   ```bash
   npx skills add Alfredisabug/skills -g
   ```

相關舊版過渡腳本已收納於 [deprecated/](deprecated/) 資料夾中。
