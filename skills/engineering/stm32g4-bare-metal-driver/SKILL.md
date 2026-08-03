---
name: stm32g4-bare-metal-driver
description: Critical engineering guidelines for STM32G4 bare-metal driver development without CubeMX dependency.
globs: "**/*.{c,h,s,ld}"
alwaysApply: false
---

# STM32G4 Bare-Metal & Driver Engineering Standard

## 🎯 Trigger Context

Invoke this skill whenever designing, reviewing, or writing firmware code for **STM32G4 series microcontrollers (Cortex-M4F)**, particularly for low-level peripheral configuration, clock/memory setup, and hardware acceleration.

---

## 🧠 Mental Model & Boundary Constraints

- **Scope Boundary:** Strictly confined to the **MCU boundary** (Cortex-M4 core, FLASH/RAM architecture, internal peripherals). NO high-level application/domain logic (e.g., motor control algorithms or power topologies).
- **No GUI Generation:** Do NOT suggest or write code relying on STM32CubeMX `.ioc` generated projects or HAL complex wrappers where performance matters.
- **Hardware First:** Engineers must understand exact register mechanics. Every abstraction must remain transparent.

---

## 📜 Core Rules

### 1. Driver Layer Selection Policy

- **LL Drivers / Registers (Default for Hot Paths):** Mandatory for Interrupt Service Routines (ISRs), high-frequency loops, ADC/DAC triggers, TIM CCR updates, and hardware accelerators (**CORDIC**, **FMAC**).
- **HAL Drivers (Allowed for Cold Paths):** Permitted strictly for complex static setup logic (e.g., RCC system clock initialization, Option Bytes configuration, standard bus init).

### 2. Memory & Clock Architecture Rules

- **Flash Wait State Enforcement:** Always check and configure FLASH Latency (WS) BEFORE boosting SYSCLK (up to 170 MHz, VCORE Range 1 Boost).
- **RAM Layout Awareness:** Explicitly consider SRAM1, SRAM2, and **CCM-RAM** (`0x10000000`). Suggest placing time-critical ISRs or look-up routines into CCM-RAM via link section attributes.
- **Register Transparency:** When using bitwise operations or LL macros, add inline comments explicitly identifying the modified register and bitfields (e.g., `RCC->CR |= RCC_CR_HSION; // Turn on HSI`).

---
