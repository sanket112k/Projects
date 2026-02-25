`ifndef ALU_PKG_VH
`define ALU_PKG_VH
// -----------------------------------------------------------------------------
// APB_ALU IP — Opcode and flag definitions (shared RTL and TBs).
// Opcodes: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU (4-bit).
// Flags: Z/N/C/V bit positions. Include path: -Irtl or -Itb as needed.
// -----------------------------------------------------------------------------

// ----------------------
// ALU Opcodes (4-bit)
// ----------------------
`define ALU_OP_ADD    4'h0
`define ALU_OP_SUB    4'h1
`define ALU_OP_AND    4'h2
`define ALU_OP_OR     4'h3
`define ALU_OP_XOR    4'h4
`define ALU_OP_SLL    4'h5      //Shift Left Logical
`define ALU_OP_SRL    4'h6      //Shift Right Logical
`define ALU_OP_SRA    4'h7      //Shift Rigth Arithmatic
`define ALU_OP_SLT    4'h8      //Set Less than (signed)
`define ALU_OP_SLTU   4'h9      //Set Less than Unsigned

// ----------------------
// Flags bit positions
// flags[0]=Z, [1]=N, [2]=C, [3]=V
// ----------------------
`define ALU_FLAG_Z    0         //Zero flag
`define ALU_FLAG_N    1         //Negative flag
`define ALU_FLAG_C    2         //Carry flag
`define ALU_FLAG_V    3         //Overflow flag

`endif
