# IP Specification: APB_ALU

**World-class IP deliverables.** Version: see root [VERSION](../VERSION). Deliverables index: [00_deliverables.md](00_deliverables.md).

## 1. Purpose
Provide a small, deterministic ALU accessible over APB to demonstrate industry-standard IP creation:
- RTL quality + testability
- self-checking verification
- reproducible regression
- packaging and documentation

## 2. Features
### 2.1 Operations (ALU core)
- ADD, SUB
- AND, OR, XOR
- SLL, SRL, SRA
- SLT (signed), SLTU (unsigned)
- Illegal opcode detection

### 2.2 Flags (Z/N/C/V)
- Z: result == 0
- N: result[MSB]
- C:
  - ADD: carry-out
  - SUB: no-borrow, defined as (a >= b)
- V:
  - ADD overflow: same sign inputs, result sign differs
  - SUB overflow: different sign inputs, result sign differs from a

### 2.3 APB Control/Status
- Start pulse (W1P)
- Busy (1 cycle)
- Done sticky (W1C)
- Error bit for illegal opcode
- Illegal address response via PSLVERR

## 3. Block Diagram (ASCII)

```
                    +------------------+
     APB            |     apb_alu_top  |
  PCLK, PRESETn     |                  |
  PSEL, PENABLE     |  +-------------+ |
  PWRITE, PADDR     |  |  apb_regs   | |
  PWDATA ---------->|  |  (regfile)  | |
  PRDATA <----------|  +------+------+ |
  PREADY <----------|         |       |
  PSLVERR <---------|  +------ v ------+ |
                    |  |  a_lat,b_lat,op_lat (latched on start)
                    |  |  +-------------+ |
                    |  |  |  alu_core   | |
                    |  |  | (combo ALU) | |
                    |  |  +------+------+ |
                    |  |  res_r,flags_r,err_r (1-cycle FSM)
                    |  +------------------+
                    +------------------+
```

## 4. Interfaces
### 4.1 Clocks/Reset
- pclk: APB clock
- presetn: active-low asynchronous reset

### 4.2 APB (APB3 style)
- Inputs: PSEL, PENABLE, PWRITE, PADDR[7:0], PWDATA[31:0]
- Outputs: PRDATA[31:0], PREADY (always 1), PSLVERR (illegal address)

## 5. Execution Model (Deterministic)
1. Program OP_A, OP_B, OPCODE
2. Write CTRL.start=1 (W1P)
3. IP sets busy for exactly 1 cycle
4. IP latches RESULT/FLAGS, sets done=1 sticky
5. Software clears done by writing STATUS.done=1 (W1C)

## 6. Illegal Cases
- Illegal opcode: err_illegal_op=1, RESULT=0, FLAGS computed for RESULT (Z=1, N=0)
- Illegal APB address: PSLVERR asserted during access phase

## 7. Parameterization
- DW (default 32). This package validates DW=32 primarily.

## 8. Design-for-Verification Hooks (Lightweight)
- Deterministic start/done semantics
- Latched operands/opcode at start to prevent write-while-busy corruption
