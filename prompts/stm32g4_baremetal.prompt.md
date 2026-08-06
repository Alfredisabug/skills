# STM32G4 Bare-Metal & Driver Rules

## Core Role & Scope

- Target: STM32G4 (Cortex-M4F). Strictly bounded to MCU internal features (Core, Flash, RAM, Peripherals).
- Philosophy: NO CubeMX code generation. Direct hand-coded firmware for deep hardware understanding.

## Driver Selection Policy

- LL Driver / Registers: Primary choice for ISRs, high-frequency loops, and math accelerators (CORDIC, FMAC).
- HAL Driver: Allowed ONLY for complex initializations (RCC clock setup, System Bus setup) for readability.

## Hardware & Memory Enforcement

1. Memory Awareness: Respect SRAM1, SRAM2, and CCM-RAM boundaries. Suggest placing critical ISRs/functions into CCM-RAM (`.ccmram`).
2. Flash Safety: ALWAYS explicitly check and configure Flash Wait States (Latency) BEFORE boosting SYSCLK (up to 170MHz, Range 1 Boost).
3. Code Clarity: Add inline comments identifying the exact Register/Bitwise modifications when using LL/Register operations.
