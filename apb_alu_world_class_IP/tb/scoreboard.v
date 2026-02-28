`timescale 1ns/1ps
`include "../rtl/alu_pkg.vh"

module scoreboard;
  // Returns packed {illegal, flags[3:0], y[31:0]} for DW=32
  function [36:0] ref_alu;      // [36]=illegal, [35:32]=flags, [31:0]=y
    input [31:0] a;
    input [31:0] b;
    input [3:0]  op;

    reg [31:0] y;
    reg [3:0]  f;
    reg illegal;
    reg cflag, vflag;
    reg [32:0] sum_ext;
    reg [32:0] sub_ext;
    reg [4:0]  shamt;

    begin
      y = 32'h0;
      f = 4'h0;
      illegal = 1'b0;
      cflag = 1'b0;
      vflag = 1'b0;

      sum_ext = {1'b0,a} + {1'b0,b};
      sub_ext = {1'b0,a} - {1'b0,b};
      shamt = b[4:0];

      case (op)
        `ALU_OP_ADD: begin
          y = sum_ext[31:0];
          cflag = sum_ext[32];
          vflag = (~(a[31]^b[31])) & (y[31]^a[31]);
        end
        `ALU_OP_SUB: begin
          y = sub_ext[31:0];
          cflag = (a >= b); // no-borrow
          vflag = ((a[31]^b[31])) & (y[31]^a[31]);
        end
        `ALU_OP_AND: y = a & b;
        `ALU_OP_OR : y = a | b;
        `ALU_OP_XOR: y = a ^ b;
        `ALU_OP_SLL: y = a << shamt;
        `ALU_OP_SRL: y = a >> shamt;
        `ALU_OP_SRA: y = $signed(a) >>> shamt;
        `ALU_OP_SLT:  y = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;
        `ALU_OP_SLTU: y = (a < b) ? 32'h1 : 32'h0;
        default: begin
          y = 32'h0;
          illegal = 1'b1;
        end
      endcase

      f[`ALU_FLAG_Z] = (y == 32'h0);
      f[`ALU_FLAG_N] = y[31];
      f[`ALU_FLAG_C] = cflag;
      f[`ALU_FLAG_V] = vflag;

      ref_alu = {illegal, f, y};
    end
  endfunction
endmodule
