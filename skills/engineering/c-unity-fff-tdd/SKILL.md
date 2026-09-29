---
name: c-unity-fff-tdd
description: 當使用者要在 C 語言或嵌入式韌體專案中進行 TDD (Test-Driven Development)、使用 Unity 與 FFF (Fake Function Framework) 撰寫單元測試或設計 Mock/Fake 邊界時使用。
disable-model-invocation: false
---

# C 語言 Unity + FFF 測試驅動開發 (TDD) 指南

本技能將標準 TDD 方法論（Red-Green 循環、Seam 接縫界定、垂直切片）實踐於 C 語言與嵌入式韌體環境，搭配 **Unity** 測試框架與 **FFF (Fake Function Framework)**。

核心價值：以接縫驅動架構解耦，在 Host 端虛擬沙盒中高頻驗證硬體無關的領域邏輯與模組內部演算法。

---

## 🎯 核心心法

1. **接縫分層 (Stratified Seams)**：
    - **Public Seam（外部合約）**：針對 `.h` 公開 API 進行黑箱/整合測試，驗證模組對外行為。
    - **Internal Seam（內部模組流程）**：針對模組內部複雜狀態機、核心演算法或內部流程進行白箱測試。**允許且推薦在測試檔案中直接 `#include "module.c"`**，直接測試內部函式，既保留生產環境的 `static` 封裝，又能深入驗證內部流程。
2. **垂直切片 (Vertical Slices)**：一個 Seam、一個失敗測試、一行最小實作。反對一口氣寫完所有測試的水平切片 (Horizontal Slicing)。
3. **系統邊界 Mock (System Boundaries Only)**：FFF 僅用於替換硬體周邊 (HAL/Registers)、OS 系統呼叫 (RTOS API) 與時間/外部依賴；內部模組一律使用真實實作。
4. **獨立真值 (Independent Truth)**：測試斷言的期望值必須來自規格常數或獨立真值，嚴禁在測試中重寫待測程式的算式（拒絕 Tautological 測試）。

---

## 🚦 執行三步驟 (Execution Steps)

### 步驟一：確認接縫層級與邊界依賴 (Confirm Seam Level & Dependencies)

在撰寫任何測試前，**必須先向使用者列出並確認**：

1. **測試維度與 Seam**：
    - **外部介面測試**：目標為 `.h` 的 Public API（例如 `status_t sensor_service_init(...)`）。
    - **內部流程測試**：目標為 `.c` 內部的 static 函式或狀態機（例如 `static bool parse_packet_header(...)`）。
2. **System Boundary**：該流程會呼叫哪些外部硬體/OS 介面（需要用 FFF Fake 的對象，例如 `HAL_I2C_Master_Transmit`）。
3. **隔離策略決策**：
    - 若為內部測試，確認測試檔命名為 `test_<module>_internal.c` 並透過 `#include "<module>.c"` 導入被測單元。

---

### 步驟二：Red 階段 —— 撰寫單一 Unity 失敗測試 (Failing Test)

1. **模組內部流程測試寫法（白箱測試內部函數）**：

    ```c
    #include "unity.h"
    #include "fff.h"
    #include "fake_hal_i2c.h" // 包含硬體依賴的 FFF Fake

    DEFINE_FFF_GLOBALS;
    FAKE_VALUE_FUNC(hal_status_t, HAL_I2C_Master_Receive, i2c_port_t, uint8_t*, uint16_t, uint32_t);

    // 📌 核心關鍵：直接引入 .c 檔案，取得內部 static 函式與狀態變數的測試存取權
    #include "sensor_driver.c"

    void setUp(void) {
        RESET_FAKE(HAL_I2C_Master_Receive);
        FFF_RESET_HISTORY();
        // 可重置 sensor_driver.c 內部的 static 狀態變數
        s_current_state = SENSOR_STATE_IDLE;
    }

    void tearDown(void) {
    }

    // 針對內部流程/演算法函式撰寫語意化測試
    void test_internal_calculate_crc_should_match_known_vector(void) {
        uint8_t payload[] = { 0x01, 0x02, 0x03 };

        // 直接呼叫 sensor_driver.c 內部的 static 函式
        uint16_t crc = calculate_internal_crc(payload, sizeof(payload));

        // 使用獨立已知真值斷言
        TEST_ASSERT_EQUAL_HEX16(0xBA83, crc);
    }
    ```

2. **外部公開合約測試寫法（黑箱測試公開 API）**：

    ```c
    #include "unity.h"
    #include "fff.h"
    #include "fake_hal_i2c.h"
    #include "sensor_driver.h" // 僅引入 .h，不碰 .c 內部

    DEFINE_FFF_GLOBALS;
    FAKE_VALUE_FUNC(hal_status_t, HAL_I2C_Master_Receive, i2c_port_t, uint8_t*, uint16_t, uint32_t);

    void setUp(void) {
        RESET_FAKE(HAL_I2C_Master_Receive);
        FFF_RESET_HISTORY();
    }

    void tearDown(void) {}

    void test_sensor_init_should_fail_when_hardware_busy(void) {
        HAL_I2C_Master_Receive_fake.return_val = HAL_BUSY;

        status_t status = sensor_init();

        TEST_ASSERT_EQUAL(STATUS_ERR_BUSY, status);
    }
    ```

3. **執行測試並確認失敗**：確認測試因「斷言不符」或「函式尚未實作/流程未完成」而呈現紅燈。

---

### 步驟三：Green 階段 —— 撰寫最小足夠程式碼 (Minimal Implementation)

1. 只撰寫**剛好能通過該測試**的 C 語言程式碼。
2. 保持內部函式與流程的最小實作，不預先撰寫尚未被測試涵蓋的投機分支。
3. 編譯並執行測試，確保 Unity 綠燈（`OK: 1 Tests 0 Failures`）。
4. 進入下一個垂直切片，重複步驟一至三。

---

## ⚠️ 嵌入式 C 測試反模式 (Anti-patterns)

| 反模式 (Anti-pattern)             | 症狀與壞處                                                                         | 正確做法                                                                              |
| :-------------------------------- | :--------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------ |
| **破壞性暴露內部函式**            | 為了測試內部流程，隨意將 `static` 函式暴露在生產環境的 `.h` 標頭檔中，破壞封裝性。 | 保留生產碼的 `static` 封裝，在專門的內部測試檔中透過 `#include "module.c"` 直接測試。 |
| **過度斷言呼叫細節**              | 充斥 `fake.call_count == 1` 與呼叫順序檢查，綁定具體實作。                         | 優先斷言**狀態變化**與**回傳值**；僅在硬體時序/協議副作用為核心需求時斷言 Fake 參數。 |
| **在 `setUp` 漏掉 `RESET_FAKE`**  | 單一測試單獨跑通過，整批跑時因 Fake 歷史未清空而隨機失敗。                         | 在 `setUp()` 中將所有使用到的 FAKE 函式執行 `RESET_FAKE()`。                          |
| **同義反覆 (Tautological Test)**  | 斷言中用與實作相同的算式計算期望值，永遠測不出邏輯 Bug。                           | 期望值一律使用獨立真值、規格硬編碼常數或計算已知的手算範例。                          |
| **水平切片 (Horizontal Slicing)** | 一次寫出多個測試再開始寫 C 碼，測試全部失真。                                      | 堅持**單一垂直切片**：一次只寫一個測試 $\rightarrow$ 一次通過 $\rightarrow$ 下一個。  |

---

## 🛠️ FFF 常用技法速查

- **設定多輪連續回傳值**：
    ```c
    hal_status_t return_sequence[] = { HAL_BUSY, HAL_BUSY, HAL_OK };
    SET_RETURN_SEQ(HAL_I2C_Master_Transmit, return_sequence, 3);
    ```
- **檢查傳入參數歷史**：
    ```c
    // 檢查第 0 次被呼叫時的第一個參數
    TEST_ASSERT_EQUAL_HEX8(0x5A, HAL_I2C_Master_Transmit_fake.arg1_history[0]);
    ```
- **自訂複雜 Fake 行為**：
    ```c
    hal_status_t custom_i2c_read(i2c_port_t p, uint8_t *buf, uint16_t len, uint32_t to) {
        buf[0] = 0xDE;
        buf[1] = 0xAD;
        return HAL_OK;
    }
    HAL_I2C_Master_Receive_fake.custom_fake = custom_i2c_read;
    ```
