---
name: ti-c2000-f28p-driver
description: 當使用者要求設計、撰寫或審查 TI C2000 F28P 系列 (如 F28P550x、F28P650x) 的底層韌體與驅動時使用。
---

# TI C2000 F28P Driver SOP

## 1. Execution Steps

### Step 1: Context Gathering
- 讀取專案 Linker Command 檔 (`.cmd`)、裝置標頭檔與 Clock Tree / PLL 狀態。
- 確認目標型號（F28P550x / F28P650x）與功能場景：即時控制中斷 (ePWM / ADC ISR)、CLA / TMU 演算法、週邊通訊或開機初始化。

### Step 2: Architecture Planning & Verification
- **驅動分層策略 (Driver Policy)**：
  - **預設 (Default)**：全域初始化、週邊配置與常規邏輯全面採用官方 **C2000Ware DriverLib**。
  - **Hot Path 特例 (Bit-field)**：若在極限高頻 ISR / 即時控制環中需追求極致指令週期，可提出使用 **Bit-field / 暫存器結構** 的方案，但**必須向使用者說明效能收益並經其審視決定**後方可使用。
- **事實查證 (Facts)**：
  - **Register / Bitfield 疑慮**：優先查閱 `references/` 目錄下的 TI TargetDB XML 描述檔或 C2000Ware 標頭檔 (`f28p*.h`, `hw_*.h`)，依定義回答。
  - **DriverLib API 疑慮**：查證 TI 官方 C2000Ware DriverLib API Guide 與晶片 Technical Reference Manual (TRM)。
- **決策點 (Decisions)**：遇到驅動層選型 (DriverLib vs Bit-field)、記憶體切換 (Flash/RAM) 或多核心/CLA 分工疑慮時，列出具體選項與權衡向使用者請教，勿擅自決定。

### Step 3: Execution & Proactive Safety Check
- 撰寫程式碼。暫存器與位元操作須加上 Inline Comments (精確標示 Register / Bitfield 意義)。
- **主動防呆與安全性檢查 (Proactive Warnings)**：
  - **Flash Wait States**：提升 PLL / SYSCLK 時鐘**前**，必須先配置正確的 Flash Wait States (Latency) 與 Prefetch Buffer / Cache。
  - **RAM 執行 (`.TI.ramfunc`)**：關鍵 ISR 及時間敏感函式，確認是否指定至 `.TI.ramfunc` 區段，並在開機初始化時執行 `memcpy(&RamfuncsRunStart, ...)` 載入。
  - **暫存器保護 (`EALLOW` / `EDIS`)**：若使用 Bit-field / 直接暫存器寫入受保護區域，務必嚴格成對使用 `EALLOW` 與 `EDIS`。
  - **16-bit Byte 定址特性**：提醒 C28x 架構下 `sizeof(char) == 1`（實質為 16-bit），在通訊封包（CAN-FD / SPI / SCI）緩衝區打包時主動防範位元組偏移陷阱。

## 2. Constraints & Rules

- **Scope Boundary**：僅限 MCU 內部硬體功能 (C28x Core, Flash, RAM, CLA/TMU, Peripherals)。
- **No SysConfig**：嚴禁依賴或生成 SysConfig 自動產生代碼，全面手刻底層韌體 (Direct hand-coded firmware)。
- **Hardware Transparency**：嚴守硬體機制透明化，徹底掌握時鐘、中斷與暫存器操作。
