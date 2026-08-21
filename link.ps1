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

# 定義標記常數與 UTF8 (無 BOM) 編碼物件
$MarkerStart = "<!-- BEGIN PERSONAL AI SKILLS -->"
$MarkerEnd   = "<!-- END PERSONAL AI SKILLS -->"
$ExcludeStart = "# BEGIN PERSONAL AI SKILLS EXCLUDE"
$ExcludeEnd   = "# END PERSONAL AI SKILLS EXCLUDE"
$Utf8NoBom   = New-Object System.Text.UTF8Encoding($false)

# ----------------- 清理流程 (-Clean) -----------------
if ($Clean) {
    Write-Host "🧹 正在移除當前專案 ($TargetDir) 的 Skills 連結與配置..." -ForegroundColor Yellow
    
    # 1. 移除軟連結 / Junction / 獨立生成檔案
    if (Test-Path ".agents") {
        Remove-Item -Path ".agents" -Force -Recurse
        Write-Host " [OK] 已移除 .agents" -ForegroundColor Green
    }
    if (Test-Path ".ignore") {
        Remove-Item -Path ".ignore" -Force
        Write-Host " [OK] 已移除 .ignore" -ForegroundColor Green
    }
    if (Test-Path ".github\prompts") {
        Remove-Item -Path ".github\prompts" -Force -Recurse
        Write-Host " [OK] 已移除 .github\prompts" -ForegroundColor Green
    }

    # 2. 安全清理 AGENTS.md 內的附加區塊
    if (Test-Path "AGENTS.md") {
        $agentsPath = Join-Path $TargetDir "AGENTS.md"
        $current = [System.IO.File]::ReadAllText($agentsPath, [System.Text.Encoding]::UTF8)
        $pattern = "(?s)\r?\n?" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd) + "\r?\n?"
        if ($current -match $pattern) {
            $remaining = ($current -replace $pattern, "").Trim()
            if ([string]::IsNullOrWhiteSpace($remaining)) {
                Remove-Item -Path "AGENTS.md" -Force
                Write-Host " [OK] 已移除 AGENTS.md (由腳本建立之檔案)" -ForegroundColor Green
            } else {
                [System.IO.File]::WriteAllText($agentsPath, ($remaining + "`r`n"), $Utf8NoBom)
                Write-Host " [OK] 已自現有 AGENTS.md 移除 Skills 區塊 (保留專案原內容)" -ForegroundColor Green
            }
        }
    }

    # 3. 安全清理 .github/copilot-instructions.md 內的附加區塊
    $copilotPath = Join-Path $TargetDir ".github\copilot-instructions.md"
    if (Test-Path $copilotPath) {
        $current = [System.IO.File]::ReadAllText($copilotPath, [System.Text.Encoding]::UTF8)
        $pattern = "(?s)\r?\n?" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd) + "\r?\n?"
        if ($current -match $pattern) {
            $remaining = ($current -replace $pattern, "").Trim()
            if ([string]::IsNullOrWhiteSpace($remaining)) {
                Remove-Item -Path $copilotPath -Force
                Write-Host " [OK] 已移除 .github/copilot-instructions.md (由腳本建立之檔案)" -ForegroundColor Green
            } else {
                [System.IO.File]::WriteAllText($copilotPath, ($remaining + "`r`n"), $Utf8NoBom)
                Write-Host " [OK] 已自現有 copilot-instructions.md 移除 Skills 區塊 (保留專案原內容)" -ForegroundColor Green
            }
        }
    }

    # 若 .github 為空目錄則一併清理
    if ((Test-Path ".github") -and ((Get-ChildItem ".github").Count -eq 0)) {
        Remove-Item -Path ".github" -Force
    }

    # 4. 清理 .git/info/exclude 中的規則
    $excludePath = Join-Path $TargetDir ".git\info\exclude"
    if (Test-Path $excludePath) {
        $current = [System.IO.File]::ReadAllText($excludePath, [System.Text.Encoding]::UTF8)
        $pattern = "(?s)\r?\n?" + [regex]::Escape($ExcludeStart) + ".*?" + [regex]::Escape($ExcludeEnd) + "\r?\n?"
        if ($current -match $pattern) {
            $remaining = ($current -replace $pattern, "").Trim()
            [System.IO.File]::WriteAllText($excludePath, ($remaining + "`r`n"), $Utf8NoBom)
            Write-Host " [OK] 已從 .git/info/exclude 清除個人 Skills 規則" -ForegroundColor Green
        }
    }
    
    Write-Host "`n🎉 清理完成！" -ForegroundColor Cyan
    exit 0
}

# ----------------- 掛載流程 (Link) -----------------
Write-Host "🔗 正在將 Skills 庫 ($SkillsRepo) 連結至當前專案 ($TargetDir)..." -ForegroundColor Cyan

# 1. 建立 .agents Directory Junction (Windows 免管理員權限)
if (-not (Test-Path ".agents")) {
    New-Item -ItemType Junction -Path ".agents" -Target $SkillsRepo | Out-Null
    Write-Host " [OK] 建立 .agents -> $SkillsRepo" -ForegroundColor Green
} else {
    Write-Host " [SKIP] .agents 目錄已存在" -ForegroundColor Yellow
}

# 動態從 agents.md 提取技能路由清單
$agentsMdPath = Join-Path $SkillsRepo "agents.md"
$extractedRouting = ""
if (Test-Path $agentsMdPath) {
    $agentsContent = [System.IO.File]::ReadAllText($agentsMdPath, [System.Text.Encoding]::UTF8)
    if ($agentsContent -match "(?s)## 🛠️ 可用技能路由[^\r\n]*\r?\n(?<routes>.*?)(\r?\n## |\Z)") {
        $rawRoutes = $Matches['routes'].Trim()
        $routeLines = ($rawRoutes -split "\r?\n") | Where-Object { $_ -match "^\s*-\s+\*\*" }
        # 將 skills/ 相對路徑轉換為專案掛載後的 .agents/skills/
        $routeLines = $routeLines -replace "(?<=\(|`|\[)skills/", ".agents/skills/"
        $extractedRouting = ($routeLines -join "`r`n")
    }
}
if ([string]::IsNullOrWhiteSpace($extractedRouting)) {
    $extractedRouting = "- 請調用讀檔工具查閱 `.agents/agents.md` 以取得完整可用技能列表與對應路徑。"
}

# 2. 建立或附加 AGENTS.md
$agentsBlockBody = @(
    "---",
    "## 🚨 個人通用技能庫強制路由 (Universal Skills Routing Protocol)",
    "本專案已掛載個人專屬技能與標準作業程序庫。",
    "**【強制執行規則】**：在處理專案任務前，AI 助理**必須優先載入並嚴格遵循** [.agents/agents.md](.agents/agents.md) 中的技能路由與規範。嚴格禁止在未查閱對應 `.agents/skills/` 規範前直接依通用常理回覆特定領域任務（如 Git 操作、韌體驅動、Python 環境、架構設計等）。"
) -join "`r`n"

$agentsBlock = @(
    $MarkerStart,
    $agentsBlockBody,
    $MarkerEnd
) -join "`r`n"

$agentsFilePath = Join-Path $TargetDir "AGENTS.md"
if (-not (Test-Path $agentsFilePath)) {
    $initialAgentsContent = "# Project Agent Routing`r`n`r`n" + $agentsBlock + "`r`n"
    [System.IO.File]::WriteAllText($agentsFilePath, $initialAgentsContent, $Utf8NoBom)
    Write-Host " [OK] 建立 AGENTS.md 路由入口" -ForegroundColor Green
} else {
    $currentAgents = [System.IO.File]::ReadAllText($agentsFilePath, [System.Text.Encoding]::UTF8)
    $pattern = "(?s)\r?\n?" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd)
    if ($currentAgents -match $pattern) {
        $cleanAgents = ($currentAgents -replace $pattern, "").TrimEnd()
        $updatedAgents = $cleanAgents + "`r`n`r`n" + $agentsBlock + "`r`n"
        [System.IO.File]::WriteAllText($agentsFilePath, $updatedAgents, $Utf8NoBom)
        Write-Host " [OK] 已更新 AGENTS.md 中的個人 Skills 區塊" -ForegroundColor Green
    } else {
        $updatedAgents = $currentAgents.TrimEnd() + "`r`n`r`n" + $agentsBlock + "`r`n"
        [System.IO.File]::WriteAllText($agentsFilePath, $updatedAgents, $Utf8NoBom)
        Write-Host " [OK] 已將個人 Skills 路由附加至現有 AGENTS.md 底部" -ForegroundColor Green
    }
}

# 3. 建立 .github 資料夾與 Copilot 整合
if (-not (Test-Path ".github")) {
    New-Item -ItemType Directory -Path ".github" | Out-Null
}

# 3-1. 建立或附加 Copilot Instructions
$copilotBlockBody = @(
    "---",
    "## 🚨 核心強制執行規則 (MANDATORY SKILLS PROTOCOL)",
    "",
    "本專案已掛載個人專屬技能與標準作業程序庫（位於 `.agents/skills/`）。",
    "你身為此專案的 AI 助理，**在回答任何問題或編寫程式碼之前，必須無條件執行以下「前置檢查清單 (Pre-Flight Checklist)」**：",
    "",
    "### 1. 前置檢查清單 (Pre-Flight Gate)",
    "每當使用者請求符合以下領域或情境時，**嚴格禁止憑預訓練常識直接作答**，你必須**立即調用讀檔工具讀取對應的 SKILL.md** 並嚴格執行其規範：",
    "",
    $extractedRouting,
    "",
    "*💡 若遇到未列於上表之特殊任務，請主動調用工具讀取 `.agents/agents.md` 查看最新擴充技能。*",
    "",
    "### 2. 執行順序與工具要求 (Execution Sequence)",
    "1. **第一步（強制）**：依據任務主題，直接使用讀檔工具 (如 `readFile`) 載入對應路徑下的 `SKILL.md`（例如 `.agents/skills/productivity/git-commit-message/SKILL.md`）。",
    "2. **第二步**：嚴格遵循該 `SKILL.md` 內定義的工作流程、命名規範、防呆機制與輸出模板。",
    "3. **第三步**：若使用搜尋工具（如 `findFiles` / `grepSearch`），必須確保搜尋範圍涵蓋 `.agents/` 目錄（若有 `includeIgnoredFiles` 參數請設為 `true`）。",
    "",
    "### 3. 輸出合規宣告 (Mandatory Header)",
    "凡命中上述技能主題之回覆，**必須在輸出的最開頭第一行加入**：",
    "> 💡 **[Skill Applied]** 已載入並嚴格遵循 \`.agents/skills/.../SKILL.md\` 規範"
) -join "`r`n"

$copilotBlock = @(
    $MarkerStart,
    $copilotBlockBody,
    $MarkerEnd
) -join "`r`n"

$copilotFilePath = Join-Path $TargetDir ".github\copilot-instructions.md"
if (-not (Test-Path $copilotFilePath)) {
    $initialCopilotContent = "# Workspace Instructions & Skills`r`n`r`n" + $copilotBlock + "`r`n"
    [System.IO.File]::WriteAllText($copilotFilePath, $initialCopilotContent, $Utf8NoBom)
    Write-Host " [OK] 建立 .github\copilot-instructions.md" -ForegroundColor Green
} else {
    $currentCopilot = [System.IO.File]::ReadAllText($copilotFilePath, [System.Text.Encoding]::UTF8)
    $pattern = "(?s)\r?\n?" + [regex]::Escape($MarkerStart) + ".*?" + [regex]::Escape($MarkerEnd)
    if ($currentCopilot -match $pattern) {
        $cleanCopilot = ($currentCopilot -replace $pattern, "").TrimEnd()
        $updatedCopilot = $cleanCopilot + "`r`n`r`n" + $copilotBlock + "`r`n"
        [System.IO.File]::WriteAllText($copilotFilePath, $updatedCopilot, $Utf8NoBom)
        Write-Host " [OK] 已更新 .github\copilot-instructions.md 中的個人 Skills 區塊" -ForegroundColor Green
    } else {
        $updatedCopilot = $currentCopilot.TrimEnd() + "`r`n`r`n" + $copilotBlock + "`r`n"
        [System.IO.File]::WriteAllText($copilotFilePath, $updatedCopilot, $Utf8NoBom)
        Write-Host " [OK] 已將個人 Skills 提示附加至現有 copilot-instructions.md 底部" -ForegroundColor Green
    }
}

# 3-2. VS Code Copilot 原生 Prompts 連結 (.github/prompts -> .agents/prompts)
$promptsSource = Join-Path $SkillsRepo "prompts"
if ((Test-Path $promptsSource) -and (-not (Test-Path ".github\prompts"))) {
    New-Item -ItemType Junction -Path ".github\prompts" -Target $promptsSource | Out-Null
    Write-Host " [OK] 建立 .github\prompts -> $promptsSource (VS Code Copilot Prompt Files)" -ForegroundColor Green
}

# 4. 建立 .ignore 檔案 (讓 VS Code / Ripgrep 搜尋引擎不忽略 .agents)
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
    $gitInfoDir = Join-Path $TargetDir ".git\info"
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

    if ($currentContent -match [regex]::Escape($ExcludeStart)) {
        Write-Host " [SKIP] .git/info/exclude 已包含個人 Skills 排除規則" -ForegroundColor Yellow
    } else {
        $excludeBlock = @(
            "",
            $ExcludeStart,
            ($entriesToIgnore -join "`r`n"),
            $ExcludeEnd,
            ""
        ) -join "`r`n"
        [System.IO.File]::AppendAllText($excludePath, $excludeBlock, $Utf8NoBom)
        Write-Host " [OK] 已將個人 Skill 設定加入 .git/info/exclude (本地 Git 忽略，不改動 .gitignore)" -ForegroundColor Green
    }
}

Write-Host "`n🎉 完成！各 AI 工具現在可以自由搜尋並自動使用 Skills 與 Prompts！" -ForegroundColor Cyan
