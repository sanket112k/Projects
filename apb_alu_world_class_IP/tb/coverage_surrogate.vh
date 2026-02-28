`ifndef COVERAGE_SURROGATE_VH
`define COVERAGE_SURROGATE_VH
// -----------------------------------------------------------------------------
// Pure-Verilog coverage: counter-based functional coverage surrogate.
// Per-op hits, flag hits (Z/N/C/V), overflow hits (ADD/SUB), shift corner hits
// (shamt=0, shamt=31), illegal opcode hits. No SystemVerilog covergroups.
//
// Enclosing module MUST declare (before `include):
//   integer cov_op[0:15], cov_z, cov_n, cov_c, cov_v;
//   integer cov_overflow_add, cov_overflow_sub, cov_shift0, cov_shift31, cov_illegal;
// Tasks use these by name (no array ports for Verilog-2001 compatibility).
// -----------------------------------------------------------------------------
task cov_init;
  integer i;
  begin
    for (i=0; i<16; i=i+1) cov_op[i] = 0;
    cov_z = 0; cov_n = 0; cov_c = 0; cov_v = 0;
    cov_overflow_add = 0; cov_overflow_sub = 0;
    cov_shift0 = 0; cov_shift31 = 0;
    cov_illegal = 0;
  end
endtask

task cov_sample;
  input [3:0]  op;
  input [3:0]  flags;
  input        illegal;
  input [4:0]  shamt;
  input        is_add;
  input        is_sub;
  begin
    cov_op[op] = cov_op[op] + 1;
    if (flags[0]) cov_z = cov_z + 1;
    if (flags[1]) cov_n = cov_n + 1;
    if (flags[2]) cov_c = cov_c + 1;
    if (flags[3]) cov_v = cov_v + 1;

    if (is_add && flags[3]) cov_overflow_add = cov_overflow_add + 1;
    if (is_sub && flags[3]) cov_overflow_sub = cov_overflow_sub + 1;

    if (shamt == 0)  cov_shift0  = cov_shift0 + 1;
    if (shamt == 31) cov_shift31 = cov_shift31 + 1;

    if (illegal) cov_illegal = cov_illegal + 1;
  end
endtask

task cov_report;
  integer i;
  begin
    $display("---- Coverage Surrogate Report ----");
    for (i=0; i<16; i=i+1) begin
      if (cov_op[i] != 0) $display("OP %0d : %0d hits", i, cov_op[i]);
    end
    $display("Flags hits: Z=%0d N=%0d C=%0d V=%0d", cov_z, cov_n, cov_c, cov_v);
    $display("Overflow hits: ADD=%0d SUB=%0d", cov_overflow_add, cov_overflow_sub);
    $display("Shift shamt hits: shamt=0 => %0d, shamt=31 => %0d", cov_shift0, cov_shift31);
    $display("Illegal opcode hits: %0d", cov_illegal);
    $display("-----------------------------------");
  end
endtask

`endif
