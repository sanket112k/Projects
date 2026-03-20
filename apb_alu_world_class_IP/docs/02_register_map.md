# Register Map: APB_ALU

**World-class IP deliverables.** Byte addressing (offsets from base). See [00_deliverables.md](00_deliverables.md).

| Offset | Name    | Access | Reset | Bits | Description |
|------:|---------|--------|------:|------|-------------|
| 0x00  | CTRL    | WO/R0  | 0x0   | [0]  | start (W1P) |
| 0x04  | STATUS  | RO/W1C | 0x0   | [0]  | busy |
|       |         |        |       | [1]  | done (W1C) |
|       |         |        |       | [2]  | err_illegal_op |
| 0x08  | OP_A    | RW     | 0x0   | [31:0] | operand A |
| 0x0C  | OP_B    | RW     | 0x0   | [31:0] | operand B |
| 0x10  | OPCODE  | RW     | 0x0   | [3:0] | opcode |
| 0x14  | RESULT  | RO     | 0x0   | [31:0] | ALU result |
| 0x18  | FLAGS   | RO     | 0x0   | [3:0] | flags Z/N/C/V |

Policies:
- CTRL reads return 0
- Writes to undefined addresses are ignored and PSLVERR is asserted on access
