# TI C2000 F28P Bare-Metal & Driver Rules

## Core Role & Scope

- Target: TI C2000 F28P Series (TMS320F28P550x, TMS320F28P650x). Strictly bounded to MCU internal features (C28x DSP Core, Flash, RAM, CLA, TMU, Peripherals).
- Philosophy: NO SysConfig code generation. Direct hand-coded firmware for deep hardware understanding and deterministic execution.

## Driver Selection Policy

- C2000Ware DriverLib: Default choice for initialization, peripheral configuration, and general logic for safety and readability.
- Bit-field / Registers: Allowed ONLY for performance-critical Hot Paths (ePWM ISR, high-frequency control loops) after user review and explicit approval.

## Hardware & Memory Enforcement (Proactive Checks)

1. Flash Safety: ALWAYS configure Flash Wait States (Latency) and Prefetch Buffer BEFORE increasing PLL / SYSCLK frequency.
2. RAM Execution: Ensure time-critical functions and ISRs are assigned to `.TI.ramfunc` and copied from Flash to RAM via `memcpy` at startup.
3. EALLOW / EDIS: Ensure protected registers written via Bit-fields are strictly bounded with `EALLOW` and `EDIS`.
4. 16-bit Byte Awareness: Proactively alert and handle 16-bit `char` (`sizeof(char) == 1`) alignment in communication buffers (CAN-FD, SPI, SCI).
5. Code Clarity: Add inline comments identifying the exact Register/Bitfield operations.
