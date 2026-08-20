#!/usr/bin/env bash
# link.sh - 自動以動態路徑掛載 Skills 與 Prompts 至當前專案
# 執行方式：在目標專案目錄下執行： bash <skills庫路徑>/link.sh [--clean]

SKILLS_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

if [ "$SKILLS_REPO" = "$TARGET_DIR" ]; then
    echo -e "\033[31m⚠️ 請在「目標專案目錄」下執行此腳本，不要在 skills 庫本身執行！\033[0m"
    exit 1
fi

if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
    echo -e "\033[33m🧹 正在移除當前專案 ($TARGET_DIR) 的 Skills 連結與配置...\033[0m"
    rm -f .agents AGENTS.md .ignore .github/copilot-instructions.md .github/prompts
    if [ -d ".github" ] && [ -z "$(ls -A .github 2>/dev/null)" ]; then
        rmdir .github
    fi
    echo -e "\033[36m🎉 清理完成！\033[0m"
    exit 0
fi

echo -e "\033[36m🔗 正在將 Skills 庫 ($SKILLS_REPO) 連結至當前專案 ($TARGET_DIR)...\033[0m"

# 1. 建立 .agents 軟連結
if [ ! -e ".agents" ]; then
    ln -s "$SKILLS_REPO" .agents
    echo -e "\033[32m [OK] 建立 .agents 軟連結\033[0m"
else
    echo -e "\033[33m [SKIP] .agents 已存在\033[0m"
fi

# 2. 建立 AGENTS.md
if [ ! -e "AGENTS.md" ]; then
    cat << 'EOF' > AGENTS.md
# Project Agent Routing
本專案已連結通用技能庫。
請優先參閱並遵循 [.agents/agents.md](.agents/agents.md) 中的可用技能路由。
EOF
    echo -e "\033[32m [OK] 建立 AGENTS.md 路由入口\033[0m"
else
    echo -e "\033[33m [SKIP] AGENTS.md 已存在\033[0m"
fi

# 3. 建立 .github 目錄與 Copilot 整合
mkdir -p .github

# 3-1. Copilot Instructions (明確指示直接讀取或設定 includeIgnoredFiles)
if [ ! -e ".github/copilot-instructions.md" ]; then
    cat << 'EOF' > .github/copilot-instructions.md
# Workspace Instructions & Skills
本專案已整合通用 Skills 程式庫（位於 `.agents/skills/`）。
請在每次處理使用者請求時，優先參閱 [.agents/agents.md](../.agents/agents.md) 的「可用技能路由 (Skills Routing)」。
若使用者的任務符合路由表中的情境：
1. 請優先直接以相對路徑讀取對應的 SKILL.md 檔案內容並嚴格遵循。
2. 若使用檔案搜尋工具 (如 findFiles / grepSearch)，請務必將參數 includeIgnoredFiles 設為 true，以確保讀取本地 Skills 資料夾。
EOF
    echo -e "\033[32m [OK] 建立 .github/copilot-instructions.md\033[0m"
else
    echo -e "\033[33m [SKIP] .github/copilot-instructions.md 已存在\033[0m"
fi

# 3-2. VS Code Copilot Prompts 軟連結
if [ ! -e ".github/prompts" ] && [ -d "$SKILLS_REPO/prompts" ]; then
    ln -s "$SKILLS_REPO/prompts" .github/prompts
    echo -e "\033[32m [OK] 建立 .github/prompts (VS Code Copilot Prompt Files)\033[0m"
fi

# 4. 建立 .ignore 檔案 (讓 VS Code / Ripgrep 搜尋引擎不忽略 .agents，但 Git 仍保持忽略)
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

# 5. 偵測 Git Repo 並寫入本地 .git/info/exclude (不污染專案 .gitignore 且不被 git 追蹤)
if [ -d ".git" ] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_INFO_DIR=".git/info"
    EXCLUDE_FILE="$GIT_INFO_DIR/exclude"
    mkdir -p "$GIT_INFO_DIR"
    
    ENTRIES=(".agents" "AGENTS.md" ".ignore" ".github/copilot-instructions.md" ".github/prompts")
    
    MISSING=()
    for entry in "${ENTRIES[@]}"; do
        if [ ! -f "$EXCLUDE_FILE" ] || ! grep -qxF "$entry" "$EXCLUDE_FILE"; then
            MISSING+=("$entry")
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo -e "\n# Personal AI Agent & Skills (local exclude, never committed)" >> "$EXCLUDE_FILE"
        for entry in "${MISSING[@]}"; do
            echo "$entry" >> "$EXCLUDE_FILE"
        done
        echo -e "\033[32m [OK] 已將個人 Skill 設定加入 .git/info/exclude (本地 Git 忽略，不改動 .gitignore)\033[0m"
    else
        echo -e "\033[33m [SKIP] .git/info/exclude 已包含相關規則\033[0m"
    fi
fi

echo -e "\n\033[36m🎉 完成！各 AI 工具現在可以自由搜尋並自動使用 Skills 與 Prompts！\033[0m"
