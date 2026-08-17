# 🔐 敏感資訊安全指南

本目錄包含 GitLab 和 GitHub API Manager 等需要存取敏感憑證的 Skill。請務必遵循以下安全規範。

---

## 📋 已實施的安全措施

### 1. ✅ `.gitignore` 配置

已配置 `.gitignore` 自動忽略所有加密憑證檔案：

```gitignore
# 加密憑證檔案
*-credentials.enc
*.enc

# 本地環境配置
.env
.env.local
.env.*.local

# 安全儲存備份
credentials/
secrets/
*.key
*.pem
```

### 2. ✅ 優先使用 VS Code Secure Storage

**推薦方案**（無檔案產生）：
- 使用 VS Code 內建的安全儲存 API
- 憑證儲存在作業系統原生安全區：
  - **Windows**: Credential Manager
  - **macOS**: Keychain
  - **Linux**: Secret Service (gnome-keyring / KWallet)
- **不會產生任何檔案**，完全不會影響 Git

### 3. ✅ 備用方案：跨平台 keyring

若無法使用 VS Code Secure Storage：
- Python: `keyring` 庫
- Node.js: `keytar` 庫
- 同樣使用作業系統原生安全儲存，**不產生檔案**

---

## ⚠️ 注意事項

### 如果看到加密檔案被追蹤

若發現 `*.enc` 檔案已被 Git 追蹤：

```bash
# 從 Git 快取中移除（保留本地檔案）
git rm --cached *-credentials.enc
git rm --cached *.enc

# 提交變更
git commit -m "移除敏感憑證檔案從版本控制"
```

### 檢查是否已洩露

```bash
# 搜尋 Git 歷史中的敏感檔案
git log --all --full-history -- "*credentials*" "**.enc*"

# 如有發現，使用 BFG Repo-Cleaner 或 git filter-branch 清除
```

---

## 🛡️ 最佳實踐

1. **優先使用 VS Code Secure Storage** - 不產生任何檔案
2. **定期更新 Token** - 建議每 3-6 個月
3. **使用最小權限** - 僅授予必要權限
4. **不要手動建立加密檔案** - 讓 Skill 自動管理
5. **檢查 `.git status`** - 提交前確認無敏感檔案

---

## 🔍 驗證配置

執行以下命令確認配置正確：

```bash
# 檢查是否有敏感檔案被追蹤
git ls-files | grep -E "\.enc$|credentials"

# 應無輸出，表示配置正確

# 檢查 .gitignore 是否生效
echo "test-credentials.enc" >> test-credentials.enc
git status test-credentials.enc
# 應顯示 "Untracked files" 且被 .gitignore 忽略
```

---

## 📚 相關資源

- [VS Code Secure Storage API](https://code.visualstudio.com/api/references/vscode-api#SecretStorage)
- [Python keyring](https://pypi.org/project/keyring/)
- [Node.js keytar](https://github.com/atom/node-keytar)
- [Git ignore 最佳實踐](https://git-scm.com/docs/gitignore)
