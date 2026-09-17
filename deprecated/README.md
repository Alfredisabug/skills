# 舊版軟連結與掛載腳本 (Legacy Link Scripts - Deprecated)

此資料夾包含過往用於建立軟連結（Symlink / Junction）以掛載 Skills 的舊腳本。

> [!WARNING]
> **本儲存庫已全面升級為標準 Agent Skills 規範（相容 `npx skills` / [skills.sh](https://skills.sh)）**。
> 原本的本機軟連結掛載方式已正式棄用，請勿再使用舊腳本進行新專案的掛載。

---

## 🧹 舊專案清理指南 (Clean Up Legacy Links)

若你的專案過去曾透過 `link.ps1` 或 `link.sh` 掛載過技能，請在**目標專案目錄**下執行清理指令以移除舊有 Junction、軟連結與配置：

### Windows (PowerShell)
```powershell
# 在目標專案根目錄下執行：
& <本儲存庫路徑>\deprecated\link.ps1 -Clean
```

### Linux / macOS (Bash)
```bash
# 在目標專案根目錄下執行：
bash <本儲存庫路徑>/deprecated/link.sh --clean
```

---

## 🚀 升級至新版使用方式 (Upgrade to npx skills)

清理完成後，即可直接透過 `npx skills` 安裝所需的技能（無須手動 clone 或建立軟連結）：

```bash
# 推薦：全域安裝（本機所有專案的 AI 助理皆可直接使用）
npx skills add Alfredisabug/skills -g

# 或：專案層級安裝
npx skills add Alfredisabug/skills
```

詳情請參閱根目錄的 [README.md](../README.md)。

