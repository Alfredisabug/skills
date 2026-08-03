---
name: stm32g4-bare-metal-driver
description: 當使用者要求設計、撰寫或審查 STM32G4 (Cortex-M4F) 的底層韌體與驅動時使用。
---

# STM32G4 Bare-Metal Driver SOP

## 1. 執行步驟 (Execution Steps)

### 步驟一：讀取/收集上下文 (Context)
- 主動讀取專案原始碼，確認當前的 Linker Script (記憶體映射) 與 Clock Tree 狀態。
- 釐清目標功能是否為高頻迴圈、Interrupt Service Routine (ISR) 或涉及數學加速器 (CORDIC, FMAC)。

### 步驟二：驗證與規劃 (Plan)
- 依據執行路徑規劃驅動層次：
  - **Hot Path** (ISR、高頻迴圈、CORDIC/FMAC)：必須規劃使用 **LL Driver** 或**直接操作暫存器 (Registers)**。
  - **Cold Path** (RCC 時脈設定、System Bus 初始化)：允許使用 **HAL Driver** 以確保初始化邏輯的可讀性。
- 規劃記憶體配置：評估是否需要將關鍵 ISR 或高時效函數放置於 **CCM-RAM** (`.ccmram`)。
- **決策點**：遇到驅動層選用衝突，或記憶體段 (SRAM1/SRAM2 vs CCM-RAM) 分配有疑慮時，**主動列出選項向使用者請教，勿替使用者下決定**。

### 步驟三：執行與驗證 (Execute & Verify)
- 撰寫程式碼。若使用 LL 巨集或位元操作，必須加上 Inline Comments，精確標示所修改的 Register 與 Bitfield。
- **事實檢驗 (Fact Check)**：
  - 若修改系統時脈 (提升 SYSCLK，最高達 170MHz, Range 1 Boost)，檢查是否已在提升**前**正確設定了 **Flash Wait States (Latency)**。
  - 確認關鍵高時效函數是否正確加上了進入 CCM-RAM 的 attribute (`.ccmram`)。

## 2. 約束與規則 (Constraints & Rules)

- **Scope Boundary**：嚴格限制在 MCU 內部硬體功能 (Core, Flash, RAM, Peripherals)，不處理高階應用演算法。
- **No CubeMX**：嚴禁依賴或生成 CubeMX 相關程式碼。必須以直接手刻的底層韌體 (Direct hand-coded firmware) 來深化對硬體的掌握。
- **Hardware Transparency**：工程師必須理解精確的暫存器機制，所有的硬體抽象操作都必須保持透明。
