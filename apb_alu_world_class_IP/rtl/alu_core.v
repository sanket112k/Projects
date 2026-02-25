// -----------------------------------------------------------------------------
// APB_ALU IP — alu_core: combinational ALU (Verilog-2001).
// Parameter: DW (default 32). Outputs: result y, flags Z/N/C/V, illegal.
// Flag semantics: Z = (y==0), N = y[MSB], C = carry/no-borrow, V = overflow.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
`include "alu_pkg.vh"
module alu_core #(
  parameter integer DW = 32
)(
  input  wire [DW-1:0] a,
  input  wire [DW-1:0] b,
  input  wire [3:0]    op,      // opcode
  output reg  [DW-1:0] y,
  output reg  [3:0]    flags,
  output reg           illegal
);

  localparam integer MSB = DW-1;    //MSB bit

  // Shift amount: for DW=32, use b[4:0]. For other DW, still safe to use 5 bits,
  // but behavior for DW < 32 should be considered by integrator (documented).
  wire [4:0] shamt = b[4:0];

  reg        cflag, vflag;
  reg [DW:0] sum_ext;       // Extended add (DW-bits)
  reg [DW:0] sub_ext;       // Extended sub (DW-bits)

  always @(*) begin
    // default values
    y       = {DW{1'b0}};   // Output register
    flags   = 4'b0000;      // flags = {Zero, Negative, Carry, Overflow}
    illegal = 1'b0;         // illegal operation selected
    cflag   = 1'b0;         // Carry flag
    vflag   = 1'b0;         // Overflow flag

    sum_ext = {1'b0,a} + {1'b0,b};
    sub_ext = {1'b0,a} - {1'b0,b};

    case (op)
      `ALU_OP_ADD: begin
        y     = sum_ext[DW-1:0];
        cflag = sum_ext[DW];
        vflag = (~(a[MSB]^b[MSB])) & (y[MSB]^a[MSB]);       // Overflow (signed): Same sign inputs & Result sign differs
      end

      `ALU_OP_SUB: begin
        y     = sub_ext[DW-1:0];
        cflag = (a >= b);       // Carry = 1 means "borrow = 0"; Carry = 0 means "borrow = 1" (ARM-style semantics)
        vflag = ((a[MSB]^b[MSB])) & (y[MSB]^a[MSB]);        // Overflow occurs when: Inputs have different signs & Result sign differs from a
      end

      `ALU_OP_AND: y = a & b;
      `ALU_OP_OR : y = a | b;
      `ALU_OP_XOR: y = a ^ b;

      `ALU_OP_SLL: y = a << shamt;              //Shift Left Logical
      `ALU_OP_SRL: y = a >> shamt;              //Shift Right Logical
      `ALU_OP_SRA: y = $signed(a) >>> shamt;    //Shift Rigth Arithmatic

      `ALU_OP_SLT : y = ($signed(a) < $signed(b)) ? {{(DW-1){1'b0}},1'b1} : {DW{1'b0}};     //Set Less than (signed)
      `ALU_OP_SLTU: y = (a < b) ? {{(DW-1){1'b0}},1'b1} : {DW{1'b0}};                       //Set Less than Unsigned

      default: begin
        y       = {DW{1'b0}};
        illegal = 1'b1;
      end
    endcase

    // Common flags
    flags[`ALU_FLAG_Z] = (y == {DW{1'b0}});     //Zero flag
    flags[`ALU_FLAG_N] = y[MSB];                //Negative flag
    flags[`ALU_FLAG_C] = cflag;                 //Carry flag
    flags[`ALU_FLAG_V] = vflag;                 //Overflow flag
  end

endmodule
