`timescale 1ns/1ps
`include "../rtl/alu_pkg.vh"
// -----------------------------------------------------------------------------
// ALU smoke — Self-checking pure-Verilog TB: directed tests.
// Per-op sanity + overflow/borrow/shift/SLT/SLTU/illegal; compare vs scoreboard.
// -----------------------------------------------------------------------------
module tb_alu_smoke;
  localparam integer DW = 32;

  reg  [DW-1:0] a, b;
  reg  [3:0]    op;

  wire [DW-1:0] y;
  wire [3:0]    flags;
  wire          illegal;

  alu_core #(.DW(DW)) dut (.a(a), .b(b), .op(op), .y(y), .flags(flags), .illegal(illegal));
  scoreboard sb();
/////////////////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////////////////
  task check;
    input [31:0] ta;
    input [31:0] tb;
    input [3:0]  top;
    
    reg [36:0] r;
    reg il;
    reg [3:0] f;
    reg [31:0] yy;

    begin
      a = ta; b = tb; op = top;     // Assign inputs for DUT
      #1;
      r  = sb.ref_alu(ta,tb,top);   // Calling the function in sb
      il = r[36];                   // expected illegal_opcode_error
      f  = r[35:32];                // expected flags
      yy = r[31:0];                 // expected result

      if (y !== yy || flags !== f || illegal !== il) begin      // Check if the output is correct
        $display("FAIL(ALU_SMOKE): a=%h b=%h op=%h | exp_y=%h exp_f=%b exp_il=%b | dut_y=%h dut_f=%b dut_il=%b",
                 ta,tb,top, yy,f,il, y,flags,illegal);
        $stop;  // stop if output is incorrect
      end
    end
  endtask
/////////////////////////////////////////////////////////////////////////////////////////
//
  initial begin
    $dumpfile("waves_alu_smoke.vcd");
    $dumpvars(0,tb_alu_smoke);

    // Per-op sanity
    check(32'h1,         32'h2,         `ALU_OP_ADD);
    check(32'h2,         32'h1,         `ALU_OP_SUB);
    check(32'hFFFF_0000, 32'h0F0F_F0F0, `ALU_OP_AND);
    check(32'h8000_0000, 32'h1,         `ALU_OP_SRA);
    check(32'h7FFF_FFFF, 32'h1,         `ALU_OP_ADD);   // overflow
    check(32'h0,         32'h1,         `ALU_OP_SUB);   // borrow
    check(32'hFFFF_FFFF, 32'h1,         `ALU_OP_SLT);   // signed
    check(32'hFFFF_FFFF, 32'h1,         `ALU_OP_SLTU);  // unsigned
    check(32'h1234,      32'h5678,      4'hF);          // illegal

    $display("TB_ALU_SMOKE: PASS");
    $finish;
  end
endmodule
