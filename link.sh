#!/usr/bin/env bash
# link.sh - 自動以動態路徑掛載 Skills 與 Prompts 至當前專案
# 執行方式：在目標專案目錄下執行： bash <skills庫路徑>/link.sh [--clean]

SKILLS_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

if [ "$SKILLS_REPO" = "$TARGET_DIR" ]; then
    echo -e "\033[31m⚠️ 請在「目標專案目錄」下執行此腳本，不要在 skills 庫本身執行！\033[0m"
    exit 1
fi

MARKER_START="<!-- BEGIN PERSONAL AI SKILLS -->"
MARKER_END="<!-- END PERSONAL AI SKILLS -->"
EXCLUDE_START="# BEGIN PERSONAL AI SKILLS EXCLUDE"
EXCLUDE_END="# END PERSONAL AI SKILLS EXCLUDE"

# ----------------- 清理流程 (--clean) -----------------
if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
    echo -e "\033[33m🧹 正在移除當前專案 ($TARGET_DIR) 的 Skills 連結與配置...\033[0m"
    
    # 1. 移除軟連結與生成檔案
    rm -f .agents .ignore .github/prompts
    echo -e "\033[32m [OK] 已移除軟連結 (.agents, .ignore, .github/prompts)\033[0m"

    # 2. 安全清理 AGENTS.md 標記區塊
    if [ -f "AGENTS.md" ]; then
        if grep -qF "$MARKER_START" "AGENTS.md"; then
            sed -i "/$MARKER_START/,/$MARKER_END/d" "AGENTS.md"
            # 檢查檔案是否只剩空白行
            if [ -z "$(grep -v '^[[:space:]]*$' "AGENTS.md")" ]; then
                rm -f "AGENTS.md"
                echo -e "\033[32m [OK] 已移除 AGENTS.md (由腳本建立之檔案)\033[0m"
            else
                echo -e "\033[32m [OK] 已自現有 AGENTS.md 移除 Skills 區塊 (保留專案原內容)\033[0m"
            fi
        fi
    fi

    # 3. 安全清理 .github/copilot-instructions.md 標記區塊
    if [ -f ".github/copilot-instructions.md" ]; then
        if grep -qF "$MARKER_START" ".github/copilot-instructions.md"; then
            sed -i "/$MARKER_START/,/$MARKER_END/d" ".github/copilot-instructions.md"
            if [ -z "$(grep -v '^[[:space:]]*$' ".github/copilot-instructions.md")" ]; then
                rm -f ".github/copilot-instructions.md"
                echo -e "\033[32m [OK] 已移除 .github/copilot-instructions.md (由腳本建立之檔案)\033[0m"
            else
                echo -e "\033[32m [OK] 已自現有 copilot-instructions.md 移除 Skills 區塊 (保留專案原內容)\033[0m"
            fi
        fi
    fi

    if [ -d ".github" ] && [ -z "$(ls -A .github 2>/dev/null)" ]; then
        rmdir .github
    fi

    # 4. 清理 .git/info/exclude 中的規則
    if [ -f ".git/info/exclude" ]; then
        if grep -qF "$EXCLUDE_START" ".git/info/exclude"; then
            sed -i "/$EXCLUDE_START/,/$EXCLUDE_END/d" ".git/info/exclude"
            echo -e "\033[32m [OK] 已從 .git/info/exclude 清除個人 Skills 規則\033[0m"
        fi
    fi

    echo -e "\033[36m🎉 清理完成！\033[0m"
    exit 0
fi

# ----------------- 掛載流程 (Link) -----------------
echo -e "\033[36m🔗 正在將 Skills 庫 ($SKILLS_REPO) 連結至當前專案 ($TARGET_DIR)...\033[0m"

# 1. 建立 .agents 軟連結
if [ ! -e ".agents" ]; then
    ln -s "$SKILLS_REPO" .agents
    echo -e "\033[32m [OK] 建立 .agents 軟連結\033[0m"
else
    echo -e "\033[33m [SKIP] .agents 已存在\033[0m"
fi

# 動態從 agents.md 提取技能路由清單
EXTRACTED_ROUTING=""
if [ -f "$SKILLS_REPO/agents.md" ]; then
    EXTRACTED_ROUTING=$(awk '/Skills Routing/{flag=1; next} /^## /{flag=0} flag && /^[[:space:]]*- \*\*/{print}' "$SKILLS_REPO/agents.md" | sed 's|skills/|.agents/skills/|g')
fi

if [ -z "$EXTRACTED_ROUTING" ]; then
    EXTRACTED_ROUTING="- 請調用讀檔工具查閱 \`.agents/agents.md\` 以取得完整可用技能列表與對應路徑。"
fi

# 2. 建立或附加 AGENTS.md
AGENTS_BLOCK=$(cat << EOF
$MARKER_START
---
## 🚨 個人通用技能庫強制路由 (Universal Skills Routing Protocol)
本專案已掛載個人專屬技能與標準作業程序庫。
**【強制執行規則】**：在處理專案任務時，AI 助理在**每一輪對話 (Every Single Turn)** 都**必須優先載入並嚴格遵循** [.agents/agents.md](.agents/agents.md) 中的技能路由與規範。
- **多輪持續性 (Persistence)**：一旦套用特定技能，後續所有追問、修改與功能擴充皆必須持續遵循該技能之規範，嚴格禁止退化為預訓練通用常識。
- **領域切換重查 (Context Switch)**：若使用者切換至其他專業任務，必須重新調用對應的 \`.agents/skills/\` 規範。
$MARKER_END
EOF
)

if [ ! -f "AGENTS.md" ]; then
    cat << EOF > AGENTS.md
# Project Agent Routing

$AGENTS_BLOCK
EOF
    echo -e "\033[32m [OK] 建立 AGENTS.md 路由入口\033[0m"
else
    if grep -qF "$MARKER_START" "AGENTS.md"; then
        sed -i "/$MARKER_START/,/$MARKER_END/d" "AGENTS.md"
        echo -e "\n\n$AGENTS_BLOCK" >> "AGENTS.md"
        echo -e "\033[32m [OK] 已更新 AGENTS.md 中的個人 Skills 區塊\033[0m"
    else
        echo -e "\n\n$AGENTS_BLOCK" >> "AGENTS.md"
        echo -e "\033[32m [OK] 已將個人 Skills 路由附加至現有 AGENTS.md 底部\033[0m"
    fi
fi

# 3. 建立 .github 目錄與 Copilot 整合
mkdir -p .github

# 3-1. 建立或附加 Copilot Instructions
COPILOT_BLOCK=$(cat << EOF
$MARKER_START
---
## 🚨 核心強制執行規則 (MANDATORY SKILLS PROTOCOL)

本專案已掛載個人專屬技能與標準作業程序庫（位於 \`.agents/skills/\`）。
你身為此專案的 AI 助理，**無論是第一輪請求或是後續多輪追問，每一輪回覆 (Every Single Turn) 之前均必須無條件執行以下協議**：

### 1. 前置檢查清單 (Pre-Flight Gate)
每當使用者請求符合以下領域或情境時，**嚴格禁止憑預訓練常識直接作答**，你必須**立即調用讀檔工具讀取對應的 SKILL.md** 並嚴格執行其規範：

$EXTRACTED_ROUTING

*💡 若遇到未列於上表之特殊任務，請主動調用工具讀取 \`.agents/agents.md\` 查看最新擴充技能。*

### 2. 跨多輪對話持續性規則 (Multi-Turn Continuity Rules)
1. **技能持續生效 (Skill Persistence)**：一旦載入或確認適用某個 Skill（如 STM32G4 驅動、Clean Architecture 等），在後續的所有追問、微調、除錯與功能增加中，該 Skill 的所有規範（如架構分層、暫存器限制、命名與風格）**持續 100% 強制生效**，絕不可因進入多輪對話而退化為一般預訓練回覆。
2. **主題切換立即重查 (Context Switch Gate)**：當在同一個對話中轉移至其他領域任務（例如編寫完代碼後要求「寫 commit message」或「管理 python 環境」），必須**立刻調用讀檔工具讀取新主題的 SKILL.md**，嚴禁略過。
3. **未載入則立即讀檔 (Load Before Answering)**：若當前問題符合技能範圍但尚未讀取對應 \`SKILL.md\`，第一步必須呼叫讀檔工具 (如 \`readFile\`) 載入對應規範文件。

### 3. 每輪強制定錨標頭 (Mandatory Per-Turn Anchor Header)
為確保在多輪對話中保持狀態與約束，**凡回覆任何技術或操作請求時，你在輸出的最開頭第一行必須輸出對應的定錨標籤**：
- **首次載入技能**：> 💡 **[Skill Applied: <技能名稱>]** 已載入並嚴格遵循 \`.agents/skills/.../SKILL.md\` 規範
- **多輪延續技能**：> 🔄 **[Skill Maintained: <技能名稱>]** 持續嚴格遵循 \`.agents/skills/.../SKILL.md\` 規範執行
- **切換新技能**：> 🔀 **[Skill Switched: <技能名稱>]** 已切換並載入 \`.agents/skills/.../SKILL.md\` 規範
- **一般無對應技能**：> ℹ️ **[General Mode]** 無特定技能路由
$MARKER_END
EOF
)

if [ ! -f ".github/copilot-instructions.md" ]; then
    cat << EOF > .github/copilot-instructions.md
# Workspace Instructions & Skills

$COPILOT_BLOCK
EOF
    echo -e "\033[32m [OK] 建立 .github/copilot-instructions.md\033[0m"
else
    if grep -qF "$MARKER_START" ".github/copilot-instructions.md"; then
        sed -i "/$MARKER_START/,/$MARKER_END/d" ".github/copilot-instructions.md"
        echo -e "\n\n$COPILOT_BLOCK" >> ".github/copilot-instructions.md"
        echo -e "\033[32m [OK] 已更新 .github/copilot-instructions.md 中的個人 Skills 區塊\033[0m"
    else
        echo -e "\n\n$COPILOT_BLOCK" >> ".github/copilot-instructions.md"
        echo -e "\033[32m [OK] 已將個人 Skills 提示附加至現有 copilot-instructions.md 底部\033[0m"
    fi
fi

# 3-2. VS Code Copilot Prompts 軟連結
if [ ! -e ".github/prompts" ] && [ -d "$SKILLS_REPO/prompts" ]; then
    ln -s "$SKILLS_REPO/prompts" .github/prompts
    echo -e "\033[32m [OK] 建立 .github/prompts (VS Code Copilot Prompt Files)\033[0m"
fi

# 4. 建立 .ignore 檔案
if [ ! -e ".ignore" ]; then
    cat << 'EOF' > .ignore
# Allow VS Code / Ripgrep search engine to index local agent skills and prompts
!.agents
!.agents/**
!AGENTS.md
!.github/copilot-instructions.md
!.github/prompts
!.github/prompts/**
EOF
    echo -e "\033[32m [OK] 建立 .ignore (允許 VS Code Copilot 搜尋已忽略目錄)\033[0m"
fi

# 5. 偵測 Git Repo 並寫入本地 .git/info/exclude
if [ -d ".git" ] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_INFO_DIR=".git/info"
    EXCLUDE_FILE="$GIT_INFO_DIR/exclude"
    mkdir -p "$GIT_INFO_DIR"
    
    if grep -qF "$EXCLUDE_START" "$EXCLUDE_FILE" 2>/dev/null; then
        echo -e "\033[33m [SKIP] .git/info/exclude 已包含個人 Skills 排除規則\033[0m"
    else
        cat << EOF >> "$EXCLUDE_FILE"

$EXCLUDE_START
.agents
AGENTS.md
.ignore
.github/copilot-instructions.md
.github/prompts
$EXCLUDE_END
EOF
        echo -e "\033[32m [OK] 已將個人 Skill 設定加入 .git/info/exclude (本地 Git 忽略，不改動 .gitignore)\033[0m"
    fi
fi

echo -e "\n\033[36m🎉 完成！各 AI 工具現在可以自由搜尋並自動使用 Skills 與 Prompts！\033[0m"
