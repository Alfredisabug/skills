---
name: c-clean-architecture-firmware
description: 針對 C 語言韌體開發 (MCU / RTOS) 的 Clean Architecture 實作指引，透過 VTABLE (函式指標) 實現依賴反轉，徹底分離硬體驅動 (HAL) 與核心業務邏輯。
---

# 核心架構原則 (Core Architecture Principles)

當開發 MCU 韌體 (不管是 Bare-metal 或 RTOS) 時，必須嚴格遵守以下架構規範。目的是確保核心商業邏輯（Domain Layer）可以在不需要實際硬體的情況下，直接在 PC 端編譯並執行單元測試。

## 1. 嚴格的硬體隔離 (Pure Domain Layer)
- Domain 層（核心邏輯、狀態機、演算法）**絕對禁止**包含特定硬體廠商的標頭檔 (例如 `#include "stm32g4xx_hal.h"`)。
- Domain 層只能依賴 C 標準函式庫 (如 `<stdint.h>`, `<stdbool.h>`, `<stddef.h>`)。
- 絕不在 Domain 邏輯中直接呼叫 `HAL_GPIO_WritePin`、`HAL_Delay` 或直接操作硬體暫存器。

## 2. 利用 VTABLE 實作依賴反轉 (Dependency Inversion via Function Pointers)
- 由於 C 語言沒有物件導向的 Interface 語法，所有的外部依賴必須在 Domain 層定義成包含「函式指標 (Function Pointers)」的 `struct`（即 VTABLE）。
- 外部的 Infrastructure / HAL 層必須實作這些函式，並在初始化時（通常在 `main.c` 中）將實體化的 VTABLE 注入 (Inject) 給 Domain 層。

## 3. 作業系統抽象層 (OS Abstraction Layer, OSAL)
- 若專案使用 RTOS（如 FreeRTOS），Domain 層**絕對禁止**直接 `#include "FreeRTOS.h"` 或呼叫特定的 OS API（如 `xQueueSend` 或 `vTaskDelay`）。
- 所有的 OS 資源調度（Delay, Mutex, Queue, EventGroup），也必須透過 VTABLE 或另外封裝好的 OSAL 介面提供給 Domain 使用。

---

# 程式碼範例 (Code Examples)

## ❌ 不正確的寫法 (Incorrect)
Domain 層與硬體驅動（HAL）及 RTOS 緊密耦合，無法在不接硬體的情況下進行單元測試。

```c
// motor_controller.c (核心邏輯)
#include "stm32g4xx_hal.h"  // ❌ 嚴重違反：引入硬體相關標頭檔
#include "FreeRTOS.h"       // ❌ 嚴重違反：引入特定 OS 標頭檔
#include "task.h"

void Motor_RunLogic(void) {
    // ❌ 直接呼叫 HAL API 與 OS API
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET); 
    vTaskDelay(pdMS_TO_TICKS(100)); 
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
}
```

## ✅ 正確的寫法 (Correct)
Domain 層定義介面 (VTABLE)，由外部在啟動時進行依賴注入 (Dependency Injection)。

```c
// --- 1. Domain Layer: motor_controller.h (純 C，無硬體相依) ---
#include <stdint.h>
#include <stdbool.h>

// 定義依賴介面 (VTABLE)
typedef struct {
    void (*set_pin)(bool state);
    void (*delay_ms)(uint32_t ms);
} IMotorHardware;

// 定義 Domain 的狀態結構
typedef struct {
    IMotorHardware hw; // 保存硬體介面
    bool is_running;
} MotorController_t;

// 建構子 (依賴注入)
void MotorController_Init(MotorController_t* self, IMotorHardware hw_interface);
void MotorController_RunLogic(MotorController_t* self);


// --- 2. Domain Layer: motor_controller.c ---
#include "motor_controller.h"

void MotorController_Init(MotorController_t* self, IMotorHardware hw_interface) {
    self->hw = hw_interface; // 儲存 VTABLE
    self->is_running = false;
}

void MotorController_RunLogic(MotorController_t* self) {
    // ✅ 透過函式指標呼叫硬體與系統資源，完全解耦
    self->hw.set_pin(true);
    self->hw.delay_ms(100);
    self->hw.set_pin(false);
}


// --- 3. Infrastructure / HAL Layer (硬體實作) ---
#include "stm32g4xx_hal.h"
#include "FreeRTOS.h"
#include "task.h"
#include "motor_controller.h"

// 實作 VTABLE 需要的函式
static void hw_set_pin(bool state) {
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, state ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

static void hw_delay_ms(uint32_t ms) {
    vTaskDelay(pdMS_TO_TICKS(ms));
}


// --- 4. Composition Root (main.c) ---
int main(void) {
    HAL_Init();
    // ... 設定時鐘等基礎設施 ...

    // 建立實體的 VTABLE
    IMotorHardware stm32_hw = {
        .set_pin = hw_set_pin,
        .delay_ms = hw_delay_ms
    };

    // ✅ 將硬體實作注入到 Domain 層
    MotorController_t my_motor;
    MotorController_Init(&my_motor, stm32_hw);

    // 啟動 RTOS Task，並在 Task 中呼叫 MotorController_RunLogic(&my_motor);
    // ...
}
```
