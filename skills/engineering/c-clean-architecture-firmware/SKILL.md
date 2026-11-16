---
name: c-clean-architecture-firmware
description: Clean Architecture and Clean Code (Robert C. Martin) guide for C firmware (MCU/RTOS). Decouples HAL/RTOS from domain logic via const VTABLEs while minimizing RAM, heap usage, and call/branch overhead.
---

# Core Architecture & Clean Code Principles

Write MCU firmware (bare-metal or RTOS) so the Domain Layer compiles and unit-tests on a host PC while keeping **zero heap usage, minimal RAM, and lean execution paths**.

## 1. Pure Domain Layer (Hardware & RTOS Isolation)
- Domain code (logic, state machines, algorithms) **MUST NOT** include vendor HAL (`stm32g4xx_hal.h`) or RTOS (`FreeRTOS.h`) headers.
- Depend only on standard C headers (`<stdint.h>`, `<stdbool.h>`, `<stddef.h>`).
- **Zero Dynamic Allocation**: Never call `malloc`/`free` in Domain code; the caller/Composition Root statically allocates all structs.

## 2. Dependency Inversion via `const` VTABLE
- Define external dependencies in Domain headers as `struct`s of function pointers (VTABLE).
- **Save RAM**: Store a pointer to a `static const` VTABLE (`const IMotorGpio*`) in the domain struct so the table lives in Flash/RODATA, not copied per instance.
- **Interface Segregation (ISP)**: Split unrelated responsibilities (e.g., `IMotorGpio` for I/O vs. `ITimeSource` for ticks).
- **Multi-Instance Context (`void* ctx`)**: Omit `ctx` for singletons (fewer args, less overhead). When multiple instances share one driver, pass `void* ctx` as the **last parameter** of each VTABLE function.

## 3. Firmware Clean Code Discipline
- **Encapsulation (Static-Friendly)**: Prefix internal struct fields with `priv_` (never mutate directly from outside); expose state via explicit getter/command APIs (`Module_IsRunning()`, `Module_Start()`).
- **Boundary-Only Validation**: Check `NULL` pointers and VTABLE entries at `Init` / public API boundaries (returning an `enum` status code). Keep internal/hot-path helpers lean without redundant defensive checks.
- **Small Functions & Shallow Nesting**: Use early returns, keep functions single-purpose (ideally ≤ 2–3 args), and replace magic numbers with `enum` or named constants.
- **Non-Blocking Logic**: Prefer tick-based state machines (`get_tick_ms()`) over blocking `delay_ms()`.

---

# Verification
Before finishing, verify the Domain Layer compiles cleanly on host without HAL/RTOS headers:
```sh
gcc -std=c11 -Wall -Wextra -Werror -c motor_controller.c -o /dev/null
```

---

# Code Examples

## ❌ Incorrect
Tightly coupled to HAL/RTOS, blocking delay, magic numbers, no encapsulation.

```c
#include "stm32g4xx_hal.h"  // ❌ HAL dependency
#include "FreeRTOS.h"       // ❌ RTOS dependency
#include "task.h"

void Motor_RunLogic(void) {
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
    vTaskDelay(pdMS_TO_TICKS(100)); // ❌ Blocking + magic number
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
}
```

## ✅ Correct
Pure C Domain Layer, ISP-split `const` VTABLEs in Flash, `priv_` fields with getter/command APIs, boundary validation, non-blocking tick logic, `void* ctx` as last arg for multi-instance support.

```c
// --- 1. Domain Layer: motor_controller.h (Pure C) ---
#include <stdbool.h>
#include <stdint.h>

typedef enum {
    MOTOR_OK = 0,
    MOTOR_ERR_INVALID_ARG
} MotorStatus_t;

// ISP: separate hardware I/O from time source
typedef struct {
    void (*set_pin)(bool active, void* ctx);
} IMotorGpio;

typedef struct {
    uint32_t (*get_tick_ms)(void);
} ITimeSource;

typedef struct {
    const IMotorGpio*  priv_gpio;     // Points to Flash/RODATA
    const ITimeSource* priv_time;
    void*              priv_gpio_ctx; // Optional; omit for singletons
    uint32_t           priv_pulse_ms;
    uint32_t           priv_start_tick;
    bool               priv_is_running;
} MotorController_t;

MotorStatus_t MotorController_Init(MotorController_t* self,
                                   const IMotorGpio* gpio,
                                   const ITimeSource* time,
                                   uint32_t pulse_ms,
                                   void* gpio_ctx);
void MotorController_Start(MotorController_t* self);
void MotorController_Update(MotorController_t* self);
bool MotorController_IsRunning(const MotorController_t* self);


// --- 2. Domain Layer: motor_controller.c ---
#include "motor_controller.h"
#include <stddef.h>

MotorStatus_t MotorController_Init(MotorController_t* self,
                                   const IMotorGpio* gpio,
                                   const ITimeSource* time,
                                   uint32_t pulse_ms,
                                   void* gpio_ctx) {
    // Boundary validation only
    if (!self || !gpio || !gpio->set_pin || !time || !time->get_tick_ms || pulse_ms == 0U) {
        return MOTOR_ERR_INVALID_ARG;
    }
    self->priv_gpio       = gpio;
    self->priv_time       = time;
    self->priv_gpio_ctx   = gpio_ctx;
    self->priv_pulse_ms   = pulse_ms;
    self->priv_start_tick = 0U;
    self->priv_is_running = false;
    return MOTOR_OK;
}

void MotorController_Start(MotorController_t* self) {
    if (self->priv_is_running) {
        return; // Early return
    }
    self->priv_is_running = true;
    self->priv_start_tick = self->priv_time->get_tick_ms();
    self->priv_gpio->set_pin(true, self->priv_gpio_ctx);
}

void MotorController_Update(MotorController_t* self) {
    if (!self->priv_is_running) {
        return;
    }
    uint32_t elapsed = self->priv_time->get_tick_ms() - self->priv_start_tick;
    if (elapsed >= self->priv_pulse_ms) {
        self->priv_gpio->set_pin(false, self->priv_gpio_ctx);
        self->priv_is_running = false;
    }
}

bool MotorController_IsRunning(const MotorController_t* self) {
    return self->priv_is_running;
}


// --- 3. Infrastructure / HAL Layer ---
#include "stm32g4xx_hal.h"
#include "FreeRTOS.h"
#include "task.h"
#include "motor_controller.h"

typedef struct {
    GPIO_TypeDef* port;
    uint16_t      pin;
} Stm32GpioCtx_t;

static void hal_set_pin(bool active, void* ctx) {
    const Stm32GpioCtx_t* gpio = (const Stm32GpioCtx_t*)ctx;
    HAL_GPIO_WritePin(gpio->port, gpio->pin, active ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

static uint32_t osal_get_tick_ms(void) {
    return (uint32_t)(xTaskGetTickCount() * portTICK_PERIOD_MS);
}


// --- 4. Composition Root (main.c) ---
enum { MOTOR_PULSE_DURATION_MS = 100U };

static const IMotorGpio  kMotorGpioVtable = { .set_pin = hal_set_pin };
static const ITimeSource kTimeVtable      = { .get_tick_ms = osal_get_tick_ms };
static Stm32GpioCtx_t    motor_a_ctx      = { .port = GPIOA, .pin = GPIO_PIN_5 };
static MotorController_t motor_a;

int main(void) {
    HAL_Init();
    MotorController_Init(&motor_a, &kMotorGpioVtable, &kTimeVtable,
                         MOTOR_PULSE_DURATION_MS, &motor_a_ctx);
    MotorController_Start(&motor_a);
    // RTOS task periodically calls MotorController_Update(&motor_a);
}
```
