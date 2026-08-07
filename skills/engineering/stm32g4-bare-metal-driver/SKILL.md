---
name: stm32g4-bare-metal-driver
description: 當使用者要求設計、撰寫或審查 STM32G4 (Cortex-M4F) 的底層韌體與驅動時使用。
---

# STM32G4 Bare-Metal Driver SOP

## 1. Execution Steps

### Step 1: Context Gathering
- 讀取專案的 Linker Script 與 Clock Tree 狀態。
- 確認目標功能場景：高頻迴圈、ISR、CORDIC/FMAC，或常規初始化。

### Step 2: Architecture Planning & Verification
- **驅動分層**：
  - **Hot Path** (ISR/高頻/硬體加速)：限用 **LL Driver** 或直接操作 **Registers**。
  - **Cold Path** (RCC/Bus Init)：可用 **HAL Driver**。
- **記憶體配置**：評估關鍵 ISR/高時效函式分配至 **CCM-RAM** (`.ccmram`)。
- **事實查證 (Facts)**：
  - **Register 疑慮**：主動檢索專案內的 **SVD 檔案** 核對，依據 SVD 的真實定義回答。
  - **HAL/LL API 疑慮**：向使用者索取官方手冊 (PDF 網址/文字片段) 閱讀後修正。
- **決策點 (Decisions)**：遇到驅動層衝突或記憶體分配疑慮，列出選項向使用者請教，勿擅自決定。

### Step 3: Execution & Fact Check
- 撰寫程式碼。暫存器與位元操作須加上 Inline Comments (精確標示 Register/Bitfield)。
- **Fact Check**：
  - 提升 SYSCLK (如 170MHz Range 1 Boost) **前**，必須先設定 **Flash Wait States (Latency)**。
  - 檢查 `.ccmram` attribute 是否正確套用。

## 2. Constraints & Rules

- **Scope Boundary**：僅限 MCU 內部硬體功能 (Core, Flash, RAM, Peripherals)。
- **No CubeMX**：嚴禁依賴或生成 CubeMX 程式碼，必須手刻底層韌體 (Direct hand-coded firmware)。
- **Hardware Transparency**：嚴守暫存器操作透明化，徹底掌握硬體機制。

