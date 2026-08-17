---
name: python-uv-environment
description: 當需要在專案中使用 Python 時，自動使用 uv 管理虛擬環境與依賴包。
---

# Python UV 環境管理 SOP

## 🎯 執行步驟 (Execution Steps)

### Step 1: 檢查 uv 安裝

```bash
uv --version
```

**若未安裝**：

- **Windows**: `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"`
- **macOS/Linux**: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **備用**: `pip install uv`

### Step 2: 初始化環境

**新專案**：

```bash
uv init              # 建立 pyproject.toml + uv.lock
uv init --python 3.11  # 指定版本
```

**現有專案**：

```bash
uv venv              # 建立 .venv
uv venv --python 3.11  # 指定版本
```

### Step 3: 安裝依賴

```bash
uv add <package>          # 生產依賴 (自動更新 uv.lock)
uv add --dev <package>    # 開發依賴
uv add requests httpx     # 多個套件
```

### Step 4: 執行程式

**推薦方式**：

```bash
uv run python script.py         # 自動管理環境
uv run --python 3.11 script.py  # 指定版本
uv run --with requests python -c "..."  # 臨時腳本
```

**傳統方式**：

```bash
source .venv/bin/activate  # macOS/Linux
.venv\Scripts\activate     # Windows
python script.py
deactivate
```

### Step 5: 驗證環境

```bash
uv pip list        # 列出套件
uv which python    # 顯示環境路徑
uv cache clean     # 清理快取
```

---

## 🔧 常見情境

### API Manager 需要 keyring

```bash
uv add keyring
uv run python main.py
```

### 跨版本測試

```bash
uv run --python 3.9 script.py
uv run --python 3.10 script.py
uv run --python 3.11 script.py
```

---

## ⚠️ 約束與規則 (Constraints & Rules)

### 環境管理

- **優先使用 `uv run`**：避免手動激活環境
- **專案根目錄原則**：所有 `uv add`/`uv run` 在專案根目錄執行
- **鎖定版本**：依賴必須有 `uv.lock`
- **開發分離**：使用 `--dev` 標記開發依賴

### 跨平台

- **路徑**：使用 `pathlib`，避免硬編碼分隔符
- **Shell**：Windows (PowerShell) / macOS/Linux (bash/zsh)
- **權限**：Linux/macOS 可能需要 `chmod +x`

### 依賴管理

- **禁止全域安裝**：所有套件在虛擬環境中
- **最小化依賴**：只安裝必要的
- **定期更新**：`uv update`

---

## 📚 參考資源

- **uv 官方文檔**: https://docs.astral.sh/uv/
- **pyproject.toml (PEP 621)**: https://peps.python.org/pep-0621/
