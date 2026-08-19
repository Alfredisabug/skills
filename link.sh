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
    echo -e "\033[33m🧹 正在移除當前專案 ($TARGET_DIR) 的 Skills 連結...\033[0m"
    rm -f .agents AGENTS.md .github/copilot-instructions.md .github/prompts
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

# 3-1. Copilot Instructions
if [ ! -e ".github/copilot-instructions.md" ]; then
    cat << 'EOF' > .github/copilot-instructions.md
# Workspace Instructions & Skills
本專案已整合通用 Skills 程式庫。
請在每次處理使用者請求時，優先參閱 [.agents/agents.md](../.agents/agents.md) 的「可用技能路由 (Skills Routing)」。
若使用者的任務符合路由表中的情境，請主動讀取並遵循對應的 SKILL.md 檔案內容後再進行回覆與執行。
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

# 4. 偵測 Git Repo 並自動加入 .gitignore
if [ -d ".git" ] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GITIGNORE=".gitignore"
    ENTRIES=(".agents" "AGENTS.md" ".github/copilot-instructions.md" ".github/prompts")
    
    MISSING=()
    for entry in "${ENTRIES[@]}"; do
        if [ ! -f "$GITIGNORE" ] || ! grep -qxF "$entry" "$GITIGNORE"; then
            MISSING+=("$entry")
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo -e "\n# Personal AI Agent & Skills (auto-generated)" >> "$GITIGNORE"
        for entry in "${MISSING[@]}"; do
            echo "$entry" >> "$GITIGNORE"
        done
        echo -e "\033[32m [OK] 已自動將個人 Skill 與 Agent 設定加入 .gitignore\033[0m"
    else
        echo -e "\033[33m [SKIP] .gitignore 已包含相關忽略規則\033[0m"
    fi
fi

echo -e "\n\033[36m🎉 完成！各 AI 工具現在可以自動使用 Skills 與 Prompts！\033[0m"
