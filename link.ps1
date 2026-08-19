# link.ps1 - 自動以動態路徑掛載 Skills 與 Prompts 至當前專案
# 執行方式：在目標專案目錄下執行： & <skills庫路徑>\link.ps1

param (
    [switch]$Clean = $false  # 傳入 -Clean 參數可一鍵移除所有掛載與引導檔案
)

$SkillsRepo = $PSScriptRoot
$TargetDir = (Get-Location).Path

# 防止在 skills 庫本身目錄下執行掛載
if ($SkillsRepo -eq $TargetDir) {
    Write-Host "⚠️ 請在「目標專案目錄」下執行此腳本，不要在 skills 庫本身執行！" -ForegroundColor Red
    exit 1
}

if ($Clean) {
    Write-Host "🧹 正在移除當前專案 ($TargetDir) 的 Skills 連結..." -ForegroundColor Yellow
    
    if (Test-Path ".agents") {
        Remove-Item -Path ".agents" -Force -Recurse
        Write-Host " [OK] 已移除 .agents" -ForegroundColor Green
    }
    if (Test-Path "AGENTS.md") {
        Remove-Item -Path "AGENTS.md" -Force
        Write-Host " [OK] 已移除 AGENTS.md" -ForegroundColor Green
    }
    if (Test-Path ".github\prompts") {
        Remove-Item -Path ".github\prompts" -Force -Recurse
        Write-Host " [OK] 已移除 .github\prompts" -ForegroundColor Green
    }
    if (Test-Path ".github\copilot-instructions.md") {
        Remove-Item -Path ".github\copilot-instructions.md" -Force
        Write-Host " [OK] 已移除 .github\copilot-instructions.md" -ForegroundColor Green
    }
    
    # 若 .github 為空目錄則一併清理
    if ((Test-Path ".github") -and ((Get-ChildItem ".github").Count -eq 0)) {
        Remove-Item -Path ".github" -Force
    }
    
    Write-Host "`n🎉 清理完成！" -ForegroundColor Cyan
    exit 0
}

Write-Host "🔗 正在將 Skills 庫 ($SkillsRepo) 連結至當前專案 ($TargetDir)..." -ForegroundColor Cyan

# 1. 建立 .agents Directory Junction (Windows 免管理員權限)
if (-not (Test-Path ".agents")) {
    New-Item -ItemType Junction -Path ".agents" -Target $SkillsRepo | Out-Null
    Write-Host " [OK] 建立 .agents -> $SkillsRepo" -ForegroundColor Green
} else {
    Write-Host " [SKIP] .agents 目錄已存在" -ForegroundColor Yellow
}

# 2. 建立通用 AGENTS.md
if (-not (Test-Path "AGENTS.md")) {
    $agentsContent = @"
# Project Agent Routing
本專案已連結通用技能庫。
請優先參閱並遵循 [.agents/agents.md](.agents/agents.md) 中的可用技能路由。
"@
    Set-Content -Path "AGENTS.md" -Value $agentsContent -Encoding utf8
    Write-Host " [OK] 建立 AGENTS.md 路由入口" -ForegroundColor Green
} else {
    Write-Host " [SKIP] AGENTS.md 已存在" -ForegroundColor Yellow
}

# 3. 建立 .github 資料夾與 Copilot 整合
if (-not (Test-Path ".github")) {
    New-Item -ItemType Directory -Path ".github" | Out-Null
}

# 3-1. Copilot Instructions
if (-not (Test-Path ".github\copilot-instructions.md")) {
    $copilotContent = @"
# Workspace Instructions & Skills
本專案已整合通用 Skills 程式庫。
請在每次處理使用者請求時，優先參閱 [.agents/agents.md](../.agents/agents.md) 的「可用技能路由 (Skills Routing)」。
若使用者的任務符合路由表中的情境，請主動讀取並遵循對應的 SKILL.md 檔案內容後再進行回覆與執行。
"@
    Set-Content -Path ".github\copilot-instructions.md" -Value $copilotContent -Encoding utf8
    Write-Host " [OK] 建立 .github/copilot-instructions.md" -ForegroundColor Green
} else {
    Write-Host " [SKIP] .github/copilot-instructions.md 已存在" -ForegroundColor Yellow
}

# 3-2. VS Code Copilot 原生 Prompts 連結 (.github/prompts -> .agents/prompts)
$promptsSource = Join-Path $SkillsRepo "prompts"
if ((Test-Path $promptsSource) -and (-not (Test-Path ".github\prompts"))) {
    New-Item -ItemType Junction -Path ".github\prompts" -Target $promptsSource | Out-Null
    Write-Host " [OK] 建立 .github/prompts -> $promptsSource (VS Code Copilot Prompt Files)" -ForegroundColor Green
}

# 4. 偵測 Git Repo 並自動加入 .gitignore
$isGit = (Test-Path ".git") -or ((git rev-parse --is-inside-work-tree 2>$null) -eq "true")
if ($isGit) {
    $gitignorePath = ".gitignore"
    $entriesToIgnore = @(
        ".agents",
        "AGENTS.md",
        ".github/copilot-instructions.md",
        ".github/prompts"
    )
    
    $currentContent = ""
    if (Test-Path $gitignorePath) {
        $currentContent = Get-Content -Path $gitignorePath -Raw
    }

    $missingEntries = @()
    foreach ($entry in $entriesToIgnore) {
        $pattern = "(?m)^[#\s]*" + [regex]::Escape($entry) + "\s*$"
        if ($currentContent -notmatch $pattern) {
            $missingEntries += $entry
        }
    }

    if ($missingEntries.Count -gt 0) {
        $ignoreBlock = "`n# Personal AI Agent & Skills (auto-generated)`n" + ($missingEntries -join "`n") + "`n"
        Add-Content -Path $gitignorePath -Value $ignoreBlock -Encoding utf8
        Write-Host " [OK] 已自動將個人 Skill 與 Agent 設定加入 .gitignore" -ForegroundColor Green
    } else {
        Write-Host " [SKIP] .gitignore 已包含相關忽略規則" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 完成！各 AI 工具現在可以自動使用 Skills 與 Prompts！" -ForegroundColor Cyan
