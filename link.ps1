# link.ps1 - 自動以動態路徑掛載 Skills 與 Prompts 至當前專案
# 執行方式：在目標專案目錄下執行： & <skills庫路徑>\link.ps1

param (
    [switch]$Clean = $false
)

# 確保 Console 支援 UTF-8 輸出
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$SkillsRepo = $PSScriptRoot
$TargetDir = (Get-Location).Path

# 防止在 skills 庫本身目錄下執行掛載
if ($SkillsRepo -eq $TargetDir) {
    Write-Host "⚠️ 請在「目標專案目錄」下執行此腳本，不要在 skills 庫本身執行！" -ForegroundColor Red
    exit 1
}

if ($Clean) {
    Write-Host "🧹 正在移除當前專案 ($TargetDir) 的 Skills 連結與配置..." -ForegroundColor Yellow
    
    if (Test-Path ".agents") {
        Remove-Item -Path ".agents" -Force -Recurse
        Write-Host " [OK] 已移除 .agents" -ForegroundColor Green
    }
    if (Test-Path "AGENTS.md") {
        Remove-Item -Path "AGENTS.md" -Force
        Write-Host " [OK] 已移除 AGENTS.md" -ForegroundColor Green
    }
    if (Test-Path ".ignore") {
        Remove-Item -Path ".ignore" -Force
        Write-Host " [OK] 已移除 .ignore" -ForegroundColor Green
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
    $agentsContent = @(
        "# Project Agent Routing",
        "本專案已連結通用技能庫。",
        "請優先參閱並遵循 [.agents/agents.md](.agents/agents.md) 中的可用技能路由。"
    ) -join "`r`n"
    Set-Content -Path "AGENTS.md" -Value $agentsContent -Encoding utf8
    Write-Host " [OK] 建立 AGENTS.md 路由入口" -ForegroundColor Green
} else {
    Write-Host " [SKIP] AGENTS.md 已存在" -ForegroundColor Yellow
}

# 3. 建立 .github 資料夾與 Copilot 整合
if (-not (Test-Path ".github")) {
    New-Item -ItemType Directory -Path ".github" | Out-Null
}

# 3-1. Copilot Instructions (明確指示直接讀取或設定 includeIgnoredFiles)
if (-not (Test-Path ".github\copilot-instructions.md")) {
    $copilotContent = @(
        "# Workspace Instructions & Skills",
        "本專案已整合通用 Skills 程式庫（位於 `.agents/skills/`）。",
        "請在每次處理使用者請求時，優先參閱 [.agents/agents.md](../.agents/agents.md) 的「可用技能路由 (Skills Routing)」。",
        "若使用者的任務符合路由表中的情境：",
        "1. 請優先直接以相對路徑讀取對應的 SKILL.md 檔案內容並嚴格遵循。",
        "2. 若使用檔案搜尋工具 (如 findFiles / grepSearch)，請務必將參數 includeIgnoredFiles 設為 true，以確保讀取本地 Skills 資料夾。"
    ) -join "`r`n"
    Set-Content -Path ".github\copilot-instructions.md" -Value $copilotContent -Encoding utf8
    Write-Host " [OK] 建立 .github\copilot-instructions.md" -ForegroundColor Green
} else {
    Write-Host " [SKIP] .github/copilot-instructions.md 已存在" -ForegroundColor Yellow
}

# 3-2. VS Code Copilot 原生 Prompts 連結 (.github/prompts -> .agents/prompts)
$promptsSource = Join-Path $SkillsRepo "prompts"
if ((Test-Path $promptsSource) -and (-not (Test-Path ".github\prompts"))) {
    New-Item -ItemType Junction -Path ".github\prompts" -Target $promptsSource | Out-Null
    Write-Host " [OK] 建立 .github\prompts -> $promptsSource (VS Code Copilot Prompt Files)" -ForegroundColor Green
}

# 4. 建立 .ignore 檔案 (讓 VS Code / Ripgrep 搜尋引擎不忽略 .agents，但 Git 仍保持忽略)
if (-not (Test-Path ".ignore")) {
    $ignoreSearchContent = @(
        "# Allow VS Code / Ripgrep search engine to index local agent skills and prompts",
        "!.agents",
        "!.agents/**",
        "!AGENTS.md",
        "!.github/copilot-instructions.md",
        "!.github/prompts",
        "!.github/prompts/**"
    ) -join "`r`n"
    Set-Content -Path ".ignore" -Value $ignoreSearchContent -Encoding utf8
    Write-Host " [OK] 建立 .ignore (允許 VS Code Copilot 搜尋已忽略目錄)" -ForegroundColor Green
}

# 5. 偵測 Git Repo 並寫入本地 .git/info/exclude (不污染專案 .gitignore 且不被 git 追蹤)
$isGit = (Test-Path ".git") -or ((git rev-parse --is-inside-work-tree 2>$null) -eq "true")
if ($isGit) {
    $gitInfoDir = Join-Path (Get-Location) ".git\info"
    $excludePath = Join-Path $gitInfoDir "exclude"
    
    $entriesToIgnore = @(
        ".agents",
        "AGENTS.md",
        ".ignore",
        ".github/copilot-instructions.md",
        ".github/prompts"
    )

    if (-not (Test-Path $gitInfoDir)) {
        New-Item -ItemType Directory -Path $gitInfoDir -Force | Out-Null
    }

    $currentContent = ""
    if (Test-Path $excludePath) {
        $currentContent = [System.IO.File]::ReadAllText($excludePath, [System.Text.Encoding]::UTF8)
    }

    $missingEntries = @()
    foreach ($entry in $entriesToIgnore) {
        $pattern = "(?m)^[#\s]*" + [regex]::Escape($entry) + "\s*$"
        if ($currentContent -notmatch $pattern) {
            $missingEntries += $entry
        }
    }

    if ($missingEntries.Count -gt 0) {
        $excludeBlock = "`r`n# Personal AI Agent & Skills (local exclude, never committed)`r`n" + ($missingEntries -join "`r`n") + "`r`n"
        [System.IO.File]::AppendAllText($excludePath, $excludeBlock, [System.Text.Encoding]::UTF8)
        Write-Host " [OK] 已將個人 Skill 設定加入 .git/info/exclude (本地 Git 忽略，不改動 .gitignore)" -ForegroundColor Green
    } else {
        Write-Host " [SKIP] .git/info/exclude 已包含相關規則" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 完成！各 AI 工具現在可以自由搜尋並自動使用 Skills 與 Prompts！" -ForegroundColor Cyan
