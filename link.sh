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

# 2. 建立或附加 AGENTS.md
AGENTS_BLOCK=$(cat << EOF
$MARKER_START
---
## 🛠️ 個人通用技能庫 (Personal Universal Skills)
本專案已掛載個人通用技能庫。請優先參閱並遵循 [.agents/agents.md](.agents/agents.md) 中的可用技能路由。
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
        echo -e "\033[33m [SKIP] AGENTS.md 已包含個人 Skills 標記區塊\033[0m"
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
## 🛠️ Workspace Universal Skills
本專案已整合通用 Skills 程式庫（位於 \`.agents/skills/\`）。
請在每次處理使用者請求時，優先參閱 [.agents/agents.md](../.agents/agents.md) 的「可用技能路由 (Skills Routing)」。
若使用者的任務符合路由表中的情境：
1. 請優先直接以相對路徑讀取對應的 SKILL.md 檔案內容並嚴格遵循。
2. 若使用檔案搜尋工具 (如 findFiles / grepSearch)，請務必將參數 includeIgnoredFiles 設為 true，以確保讀取本地 Skills 資料夾。
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
        echo -e "\033[33m [SKIP] .github/copilot-instructions.md 已包含個人 Skills 標記區塊\033[0m"
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
