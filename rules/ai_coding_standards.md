# AI Coding Standards for Firmware Platform

This document consolidates the naming rules and abbreviation list for firmware development, designed for AI skill reference.

---

## 1. Naming Rules

### 1.1 Function Naming

#### 1.1.1 Global Functions
- **Format**: `FilePrefix(LowerCamelCase)` + `_` + `FunctionName(UpperCamelCase)`
- **Examples**: 
  - `void mainRail_Init(void);`
  - `#define mainRail_SetFault()`
  - `mainRail_Init();`, `mainRail_SetAndBit();`, `protect_MainOutFastOcChk();`, `protect_GetPsOnEvt();`, `pmbus_IsIspFail();`, `pmbus_SetVoutOvFault();`

#### 1.1.2 Local Functions
- **Format**: `FunctionName(UpperCamelCase)` (no file prefix)
- **Examples**: 
  - `void RtosObjInit(void);`
  - `#define DisablePwok()`
  - `UpdPwrOnCycCnt();`, `TmrCallback();`, `PwokOffDlyDo();`

#### 1.1.3 Local Façade Functions
- **Format**: `FunctionName(UpperCamelCase)` (no file prefix)
- **Examples**:
  - `#define EnablePosBridgeFet()`, `dio_TurnOnSr()`
  - `#define EnableMainOut()`, `bspHrtim_EnableOutput()`
  - `#define DisableMainOut()`, `bspHrtim_DisbleOutput()`
  - `#define EnableRelay()`, `dio_TurnOnRelayPin()`

### 1.2 Variable Naming

#### 1.2.1 Common Variables
- **Format**: `SnakeCase` (all lowercase)
- **Examples**: 
  - `bool_t cc_pwr_on_enable;`
  - `uint32_t assert_cnt;`, `float full_scale_gain;`, `assert_proc_t assert_func;`, `ffd_group_var_t *var_ptr;`

#### 1.2.2 Pointer Variables
- **Format**: `SnakeCase` (all lowercase)
- **Examples**: 
  - `ffd_group_var_t *var_ptr;`
  - `i2c_handle_t *h;`, `gpio_signal_t *sec_io_signal;`

#### 1.2.3 Function Pointer Variables
- **Format**: 
  1. `SnakeCase` (all lowercase)
  2. Must end with `_func_ptr` suffix
- **Examples**: 
  - `typedef void (*edge_trig_func_ptr_t)(bool_t is_active);`
  - `edge_trig_func_ptr_t edge_trig_func_ptr;`
  - `ctrl_proc_func_ptr_t ctrl_proc_func_ptr;`
  - `hrtim_fault_proc_func_ptr_t main_ovp_func_ptr;`

### 1.3 Constants & Configurable Settings

#### 1.3.1 Constants
- **Format**: 
  1. `SnakeCase` (all uppercase)
  2. Floating-point numbers must have `f` suffix to ensure float calculation instead of double
- **Examples**: `#define ADC_AVG_FAST_PERIOD (1.0f / CFG_AVG_FAST_FREQ)`

#### 1.3.2 Constants by Enumeration
- **Format**: `SnakeCase` (all uppercase)
- **Examples**: 
  - `typedef enum on_off_state_e { STATE_ON = 0, STATE_OFF } on_off_state_t;`
  - `typedef enum protect_flag_e { INPUT_OV_FAULT = 0, INPUT_UV_FAULT, ... } protect_flag_t;`

#### 1.3.3 Configurable Setting Constants
- **Format**: 
  1. Only applicable in `.h` files
  2. `SnakeCase` (all uppercase)
  3. Must include `CFG` prefix
  4. Use suffix to indicate data type (e.g., DLY, THRES, FREQ)
  5. Values must include units (e.g., HZ, SEC, MSEC, AMP)
  6. Floating-point numbers must have `f` suffix
- **Examples**: 
  - `#define CFG_HL_MAIN_OUT_SLOW_OC_FAULT_V3200W_THRES (240 AMP)`
  - `#define CFG_AVG_FAST_FREQ (1000.0f HZ)`

#### 1.3.4 Configurable Callback Functions
- **Format**: 
  1. Only applicable in `.h` files
  2. `SnakeCase` (all uppercase)
  3. Must include `CFG` prefix
  4. Must end with `CALLBACK`
- **Examples**: `#define CFG_PRI_INPUT_OV_FAULT_ASSERT_CALLBACK PriInputOvFaultAssertProc`

### 1.4 Typedef Naming

#### 1.4.1 Structure
- **Format**: 
  1. `SnakeCase` (all lowercase)
  2. `struct` name with `_s` suffix
  3. `typedef` name with `_t` suffix
- **Examples**: `typedef struct protect_self_var_s { ... } protect_self_var_t;`

#### 1.4.2 Union
- **Format**: 
  1. `SnakeCase` (all lowercase)
  2. `union` name with `_u` suffix
  3. `typedef` name with `_t` suffix
- **Examples**: `typedef union float_plus_u32_u { ... } float_plus_u32_t;`

#### 1.4.3 Enumeration
- **Format**: 
  1. `SnakeCase` (all lowercase)
  2. `enum` name with `_e` suffix
  3. `typedef` name with `_t` suffix
- **Examples**: `typedef enum img_container_e { ... } img_container_t;`

#### 1.4.4 Function Pointer
- **Format**: 
  1. `SnakeCase` (all lowercase)
  2. `typedef` suffix with `_func_ptr_t`
- **Examples**: `typedef void (*edge_trig_func_ptr_t)(bool_t is_active);`

---

## 2. Abbreviation List

| Abbreviation         | Full Meaning                                    |
|:---------------------|:------------------------------------------------|
| accum                | accumulator                                     |
| ack                  | acknowledge                                     |
| adc                  | analog-to-digital converter                     |
| addr                 | address                                         |
| amb                  | ambient                                         |
| amp                  | ampere                                          |
| api                  | application programming interface               |
| arctan               | artangent                                       |
| avg                  | average                                         |
| be                   | Big-endian                                      |
| bias                 | bias voltage                                    |
| boot                 | bootloader                                      |
| bttm                 | bottom                                          |
| buf                  | buffer                                          |
| calcu                | calculate                                       |
| calib                | calibrate                                       |
| cap                  | capture                                         |
| cbc                  | cycle by cycle                                  |
| cc                   | constant current                                |
| cfg                  | config                                          |
| ch                   | channel                                         |
| chk                  | check                                           |
| chksum               | checksum                                        |
| clk                  | clock                                           |
| clr                  | clear                                           |
| cmd                  | command                                         |
| cmn                  | common                                          |
| cmpt                 | compatibility                                   |
| cnt                  | count                                           |
| coeff                | coefficient                                     |
| comm                 | communication                                   |
| comp                 | comparator                                      |
| compens              | compensator                                     |
| cond                 | condition                                       |
| conv                 | conversion                                      |
| corr                 | correction                                      |
| crc                  | cyclic redundancy check                         |
| cs                   | current share                                   |
| ctrl                 | control                                         |
| curr                 | current (present)                               |
| current              | current (power)                                 |
| cyc                  | cycle                                           |
| dac                  | digital-to-Analog converter                     |
| debunc               | debounce                                        |
| dec                  | decrease                                        |
| def                  | default                                         |
| deg                  | degree                                          |
| des                  | destination                                     |
| dir                  | direction                                       |
| div                  | divide                                          |
| dly                  | delay                                           |
| drv                  | driver                                          |
| duty                 | duty cycle                                      |
| dyn                  | dynamic                                         |
| eff                  | efficiency                                      |
| elem                 | element                                         |
| err                  | error                                           |
| evt                  | event                                           |
| exht                 | exhaust                                         |
| exp                  | exponent                                        |
| ffs                  | full fan speed                                  |
| flg                  | flag                                            |
| flt                  | filter                                          |
| fmt                  | format                                          |
| freq                 | frequency                                       |
| fru                  | Field Replacable Unit                           |
| fw                   | firmware                                        |
| fwl                  | freewheel MOSFET                                |
| h                    | handle, usually use in pointer naming           |
| hl                   | high line                                       |
| hw                   | hardware                                        |
| hyst                 | hysteresis                                      |
| i2c                  | Inter-Integrated Circuit                        |
| iaux                 | auxiliary power output current                  |
| idx                  | index                                           |
| iin                  | input current                                   |
| img                  | image                                           |
| inc                  | increase                                        |
| info                 | information                                     |
| init                 | Initialize/initial                              |
| inlet                | inlet connector                                 |
| io                   | digital input/output                            |
| iout                 | output current                                  |
| isense               | current sense                                   |
| ishare               | current of current share                        |
| ishunt               | shunt current                                   |
| isr                  | Interrupt Service Routine                       |
| ittf                 | interleaved two transistor forward converter    |
| Le                   | Little-endian                                   |
| len                  | length                                          |
| ll                   | low line                                        |
| lvl                  | level                                           |
| mcu                  | micro controller unit                           |
| mfr                  | Manufacturer                                    |
| mon                  | Monitor                                         |
| nack                 | Not Acknowledge                                 |
| norm                 | normalize                                       |
| num                  | number                                          |
| nvm                  | Non-Volatile Memory                             |
| oc_fault             | over current fault                              |
| oc_warn              | over current warning                            |
| opok                 | output OK                                       |
| oring                | ORING MOSFET                                    |
| ot                   | over temperature                                |
| ot_fault             | over temperature fault                          |
| ot_warn              | over temperature warning                        |
| out                  | output                                          |
| ov_fault             | over voltage fault                              |
| ov_fault_recov_thres | over voltage fault recovery threshold           |
| ov_warn              | over voltage warning                            |
| ovr                  | override                                        |
| param                | parameter                                       |
| paux                 | auxiliary power output power                    |
| pct                  | percent                                         |
| pec                  | Packet Error Check                              |
| ph                   | phase                                           |
| pin                  | input power                                     |
| pkg                  | package                                         |
| pout                 | output power                                    |
| prev                 | previous                                        |
| pri                  | primary side                                    |
| proc                 | process                                         |
| ptr                  | pointer                                         |
| pwm                  | Pulse Width Modulation                          |
| pwr                  | power                                           |
| rampup               | ramp up                                         |
| recov                | recovery                                        |
| redun                | redundancy                                      |
| ref                  | reference                                       |
| reg                  | register                                        |
| resis                | resistance                                      |
| rev                  | revision                                        |
| rx                   | receive                                         |
| sm                   | state machine                                   |
| spfc                 | specific                                        |
| spi                  | Serial Peripheral Interface                     |
| src                  | source                                          |
| stby                 | standby                                         |
| supt                 | support                                         |
| sw                   | software                                        |
| sync                 | synchronous                                     |
| sys                  | system                                          |
| temp                 | temperature                                     |
| therm                | thermal                                         |
| thres                | threshold                                       |
| throt                | throttle                                        |
| tim                  | timer(from ST MCU register)                     |
| time                 | time                                            |
| tmp                  | temporary                                       |
| tmr                  | timer                                           |
| trig                 | trigger                                         |
| tx                   | transmit                                        |
| uart                 | Universal Asynchronous Receiver and Transmitter |
| upd                  | update                                          |
| uv_fault             | under voltage fault                             |
| uv_warn              | under voltage warning                           |
| vanode               | anode voltage                                   |
| vaux                 | auxiliary power output voltage                  |
| vbias                | bias voltage                                    |
| vbulk                | PFC bulk voltage                                |
| vcathode             | cathode voltage                                 |
| ver                  | version                                         |
| vin                  | input voltage                                   |
| volt                 | voltage                                         |
| vout                 | output voltage                                  |
| vpd                  | Vital Product Data                              |
| vref                 | output voltage reference                        |
| warn                 | warning                                         |
| wdt                  | watch dog                                       |

---

## 3. Usage Guidelines for AI

When generating firmware code:

1. **Always use the correct naming convention** based on the element type (function, variable, constant, typedef).
2. **Use abbreviations from the list** consistently. Do not invent new abbreviations.
3. **For constants**:
   - Use `CFG_` prefix for configurable settings
   - Include units (HZ, SEC, MSEC, AMP, etc.)
   - Add `f` suffix for floating-point values
4. **For function pointers**:
   - End with `_func_ptr` or `_func_ptr_t`
5. **For typedefs**:
   - Structures: `_s` for struct, a`_t` for typedef
   - Unions: `_u` for union, `_t` for typedef
   - Enums: `_e` for enum, `_t` for typedef
6. **Maintain consistency** in casing:
   - Functions: UpperCamelCase (with file prefix for global functions)
   - Variables: SnakeCase (lowercase)
   - Constants: SnakeCase (uppercase)

This document serves as the authoritative reference for code generation and review in the firmware platform.

---

## 4. Other Rules

In DCSBU-I projects, we use the `.clang-format` file to help us automatically align most coding rules through the VS code editor. Below are the exception rules that we need to follow manually.

### 4.1 Use a suitable naming instead of comments

**OK example:**
```c
bool_t is_phase_2_enable;
ChkMainOutOv();
```

NOK example:

```c
bool_t phase_2_status; // 0: phase 2 off, 1: phase 2 on
ChkOutOv();            // For main output
```

### 4.2 Add an underline for numbers
OK example:

```c
bool_t is_phase_2_enable;
typedef enum calib_pwr_train_select_e
{
    PWR_TRAIN_MASTER = 0,
    PWR_TRAIN_1 = 0,
    PWR_TRAIN_2 = 1,
    WHOLE_PSU = 2,
} calib_pwr_train_select_t;
```

NOK example:

```c
bool_t is_phase2_enable;
typedef enum calib_pwr_train_select_e
{
    PWR_TRAIN_MASTER = 0,
    PWR_TRAIN1 = 0,
    PWR_TRAIN2 = 1,
    WHOLE_PSU = 2,
} calib_pwr_train_select_t;
```

### 4.3 Put verb in the beginning for functions
OK example:
```c
protect_IsIinOcp();
protect_ClrFaultAcok();
protect_GetPsOnEvt();
ChkMainOutSlowOc();
```

NOK example:

```c
protect_IinIsOcp();
protect_FaultAcokClr();
protect_PsOnEvtGet();
MainOutSlowOcChk();
```

### 4.4 Rules for "if" statement
#### 4.4.1 Add one blank line between if and other statements
OK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    if (evt)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
    tmp_2 = tmp_1;
}
```

NOK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    if (evt)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
    tmp_2 = tmp_1;
}
```

#### 4.4.2 It doesn't need a blank line when outer brace is nearby
OK example:

```c
bool_t Func(void)
{
    if (evt)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    if (evt)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
}
```

### 4.5 Rules for "switch case" statement
#### 4.5.1 Add one blank line between each sub condition
OK example:

```c
bool_t Func(void)
{
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        default:
            break;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        default:
            break;
    }
}
```

#### 4.5.2 It doesn't need a blank line before break
OK example:

```c
bool_t Func(void)
{
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        default:
            break;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        default:
            break;
    }
}
```

#### 4.5.3 Add one blank line between switch case and other statements
OK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        case evt_2:
            tmp_1--;
            break;
        default:
            break;
    }
    tmp_2 = tmp_1;
}
```

NOK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        case evt_2:
            tmp_1--;
            break;
        default:
            break;
    }
    tmp_2 = tmp_1;
}
```

#### 4.5.4 It doesn't need a blank line when outer brace is nearby
OK example:

```c
bool_t Func(void)
{
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        case evt_2:
            tmp_1--;
            break;
        default:
            break;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    switch (evt)
    {
        case evt_1:
            tmp_1++;
            break;
        case evt_2:
            tmp_1--;
            break;
        default:
            break;
    }
}
```

### 4.6 Rules for "for loop" statement
#### 4.6.1 Add a blank line between for loop and other statements
OK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    for (uint32_t num = 0; num < NUM_MAX; num++)
    {
        tmp_1++;
    }
    tmp_2 = tmp_1;
}
```

NOK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    for (uint32_t num = 0; num < NUM_MAX; num++)
    {
        tmp_1++;
    }
    tmp_2 = tmp_1;
}
```

#### 4.6.2 It doesn't need a blank line when outer brace is nearby
OK example:

```c
bool_t Func(void)
{
    for (uint32_t num = 0; num < NUM_MAX; num++)
    {
        tmp_1++;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    for (uint32_t num = 0; num < NUM_MAX; num++)
    {
        tmp_1++;
    }
}
```

### 4.7 Rules for "while loop" statement
#### 4.7.1 Add a blank line between while loop and other statements
OK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    while (tmp_1 <= MAX_NUM)
    {
        tmp_1++;
    }
    tmp_2 = tmp_1;
}
```

NOK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    float tmp_2 = 0;
    while (tmp_1 <= MAX_NUM)
    {
        tmp_1++;
    }
    tmp_2 = tmp_1;
}
```

#### 4.7.2 It doesn't need a blank line when outer brace is nearby
OK example:

```c
bool_t Func(void)
{
    while (tmp_1 <= MAX_NUM)
    {
        tmp_1++;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    while (tmp_1 <= MAX_NUM)
    {
        tmp_1++;
    }
}
```

### 4.8 Magic number is not allowed
OK example:

```c
#define EVT_TRIGGER_LVL   (uint8_t)(15U)
uint32_t tmp = EVT_TRIGGER_LVL;
```

NOK example:

```c
uint32_t tmp = 15;
```

### 4.9 Extern is not allowed
OK / NOK example:

```c
extern uint32_t tmp;
```

(Note: As per the rule description, declaring externs globally should be avoided.)

### 4.10 The root of #define need to add parens
OK example:

```c
#define CFG_PROTECT_THREAD_FREQ      (1.0f KHZ)
#define CFG_PROTECT_THREAD_PRIORITY  CFG_RTOS_PRIORITY_3
#define CFG_RTOS_PRIORITY_3          (TX_MAX_PRIORITIES - 28)
```

NOK example:

```c
#define CFG_PROTECT_THREAD_FREQ      1.0f KHZ
#define CFG_PROTECT_THREAD_PRIORITY  CFG_RTOS_PRIORITY_3
#define CFG_RTOS_PRIORITY_3          TX_MAX_PRIORITIES - 28
```

### 4.11 The ## preprocessor is not allowed except from framework
Framework example:

```c
#define PMBUS_CMD(x)                 CFG_CMD_##x##_CALLBACK
#define GetInjectedData(no, ch)      (ADC##no->JDR##ch)
```

### 4.12 Local functions need to use static inline or SKIP_STATIC_INLINE two cases  
#### 4.12.1 Support static inline (Speed orientation)
OK example:

```c
static inline void Func(void)
```

NOK example:

```c
void Func(void)
```

#### 4.12.2 Not support static inline (Size orientation)
OK example:

```c
#define SKIP_STATIC_INLINE
SKIP_STATIC_INLINE void Func(void)
```

NOK example:

```c
void Func(void)
```

### 4.13 The defined value need to add the suffix "f" if it is a float format
OK example:

```c
#define CFG_PROTECT_THREAD_FREQ   (1.0f KHZ)
```

NOK example:

```c
#define CFG_PROTECT_THREAD_FREQ   (1.0 KHZ)
```

### 4.14 Plural and past participle are not allowed to use in naming
OK example:

```c
#define stbyRail_IsAutoRecovFault()
float iout_oc_fault;
```

NOK example:

```c
#define stbyRail_IsAutoRecovFaulted()
float iout_oc_faults;
```

### 4.15 Don't put a true judgement for in if judgment
OK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    if (is_evt)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    if (is_evt == B_TRUE)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
}
```

### 4.16 The symbol "!" is not allowed to use in if judgment
OK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    if (IsFlg() == B_FALSE)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
}
```

NOK example:

```c
bool_t Func(void)
{
    float tmp_1 = 0;
    if (!IsFlg())
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
}
```

### 4.17 The ternary operator can only be used in macro function
OK example:

```c
bool_t Func(bool_t evt)
{
    float tmp_1 = 0;
    if (evt)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    }
}
#define ChkCmpMin(val) ((val < MIN_VAL) ? MIN_VAL : val)
```

NOK example:

```c
bool_t Func(bool_t evt)
{
    float tmp_1 = 0;
    evt == B_TRUE ? tmp_1++ : tmp_1--;
}
```

### 4.18 Use block comment instead of single comment
OK example:

```c
bool_t Func(bool_t evt)
{
    /* float tmp_1 = 0; */
    /* if (evt)
    {
        tmp_1++;
    }
    else
    {
        tmp_1--;
    } */
}
```

NOK example:

```c
bool_t Func(bool_t evt)
{
    // float tmp_1 = 0;
    // if (evt)
    // {
    //     tmp_1++;
    // }
    // else
    // {
    //     tmp_1--;
    // }
}
```

