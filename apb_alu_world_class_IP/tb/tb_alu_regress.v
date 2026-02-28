`timescale 1ns/1ps
`include "../rtl/alu_pkg.vh"
// -----------------------------------------------------------------------------
// ALU regression — Self-checking pure-Verilog TB: structured random.
// Deterministic LFSR, operand-class bias, opcode weighting, quota enforcement;
// counter-based coverage surrogate (per-op, flags, overflow, shift corners, illegal).
// -----------------------------------------------------------------------------
module tb_alu_regress;
  localparam integer DW = 32;

  reg  [DW-1:0] a, b;
  reg  [3:0]    op;
  wire [DW-1:0] y;
  wire [3:0]    flags;
  wire          illegal;

  alu_core #(.DW(DW)) dut (.a(a), .b(b), .op(op), .y(y), .flags(flags), .illegal(illegal));
  scoreboard sb();

  integer i;
  integer NVECS;
  integer QUOTA;
  integer SEED;

  reg [31:0] lfsr;

  // coverage surrogate counters (must be declared before `include coverage_surrogate.vh)
  integer cov_op[0:15];
  integer cov_z, cov_n, cov_c, cov_v;
  integer cov_overflow_add, cov_overflow_sub;
  integer cov_shift0, cov_shift31;
  integer cov_illegal;

  `include "rand_lfsr.vh"
  `include "coverage_surrogate.vh"

  // Quota counters for legal ops
  integer q_add, q_sub, q_and, q_or, q_xor, q_sll, q_srl, q_sra, q_slt, q_sltu;

///////////////////////////////////////////////////////////////////////////////////

  task quota_init;
    begin
      q_add=0; q_sub=0; q_and=0; q_or=0; q_xor=0;
      q_sll=0; q_srl=0; q_sra=0; q_slt=0; q_sltu=0;
    end
  endtask

//////////////////////////////////////////////////////////////////////////////////////

  function [3:0] pick_opcode_weighted;
    input [31:0] r;
    reg [31:0] m;
    begin
      // 0..99 bucket
      m = r % 100;
      if (m < 25)      pick_opcode_weighted = `ALU_OP_ADD;
      else if (m < 50) pick_opcode_weighted = `ALU_OP_SUB;
      else if (m < 65) pick_opcode_weighted = (r[2:0] == 3'b000) ? `ALU_OP_SLL :
                                              (r[2:0] == 3'b001) ? `ALU_OP_SRL :
                                              (r[2:0] == 3'b010) ? `ALU_OP_SRA : `ALU_OP_SLL;
      else if (m < 80) pick_opcode_weighted = (r[2:0] == 3'b000) ? `ALU_OP_AND :
                                              (r[2:0] == 3'b001) ? `ALU_OP_OR  :
                                              (r[2:0] == 3'b010) ? `ALU_OP_XOR : `ALU_OP_AND;
      else if (m < 90) pick_opcode_weighted = (r[0]) ? `ALU_OP_SLT : `ALU_OP_SLTU;
      else pick_opcode_weighted = 4'hA + (r[3:0] % 6); // illegal in [A..F] (A..F)
    end
  endfunction

///////////////////////////////////////////////////////////////////////////////////////

  function [31:0] pick_operand;
    input [31:0] r;
    reg [31:0] cls;
    begin
      // Operand classes: 0=uniform, 1=edge/pattern, 2=bitwalk/sign-stress
      cls = r % 100;
      if (cls < 50) begin
        pick_operand = r; // uniform-ish
      end else if (cls < 75) begin
        case (r[3:0])
          4'h0: pick_operand = 32'h0000_0000;
          4'h1: pick_operand = 32'h0000_0001;
          4'h2: pick_operand = 32'h7FFF_FFFF;
          4'h3: pick_operand = 32'h8000_0000;
          4'h4: pick_operand = 32'hFFFF_FFFF;
          4'h5: pick_operand = 32'hAAAA_AAAA;
          4'h6: pick_operand = 32'h5555_5555;
          4'h7: pick_operand = 32'hFFFF_0000;
          4'h8: pick_operand = 32'h0000_FFFF;
          default: pick_operand = r;
        endcase
      end else begin
        // bit-walk / sign stress
        if (r[0]) pick_operand = (32'h1 << (r[4:0]));     // 1-hot
        else      pick_operand = ~(32'h1 << (r[4:0]));    // 0-hot-ish
      end
    end
  endfunction

/////////////////////////////////////////////////////////////////////////////////////////

  task check_one;
    input [31:0] ta;
    input [31:0] tb;
    input [3:0]  top;
    reg [36:0] r;
    reg il;
    reg [3:0] f;
    reg [31:0] yy;
    begin
      a = ta; b = tb; op = top;
      #1;
      r  = sb.ref_alu(ta,tb,top);
      il = r[36];
      f  = r[35:32];
      yy = r[31:0];

      if (y !== yy || flags !== f || illegal !== il) begin
        $display("FAIL(ALU_REGRESS): SEED=%0d IDX=%0d a=%h b=%h op=%h | exp_y=%h exp_f=%b exp_il=%b | dut_y=%h dut_f=%b dut_il=%b",
                 SEED, i, ta, tb, top, yy, f, il, y, flags, illegal);
        $stop;
      end

      // coverage surrogate sample (uses module-level cov_*)
      cov_sample(top, f, il, tb[4:0],
                 (top==`ALU_OP_ADD), (top==`ALU_OP_SUB));

      // quota tracking (legal ops only)
      if (top==`ALU_OP_ADD)  q_add  = q_add + 1;
      if (top==`ALU_OP_SUB)  q_sub  = q_sub + 1;
      if (top==`ALU_OP_AND)  q_and  = q_and + 1;
      if (top==`ALU_OP_OR)   q_or   = q_or  + 1;
      if (top==`ALU_OP_XOR)  q_xor  = q_xor + 1;
      if (top==`ALU_OP_SLL)  q_sll  = q_sll + 1;
      if (top==`ALU_OP_SRL)  q_srl  = q_srl + 1;
      if (top==`ALU_OP_SRA)  q_sra  = q_sra + 1;
      if (top==`ALU_OP_SLT)  q_slt  = q_slt + 1;
      if (top==`ALU_OP_SLTU) q_sltu = q_sltu + 1;
    end
  endtask

/////////////////////////////////////////////////////////////////////////////////////////////////////

  task quota_enforce_or_fail;
    begin
      if (q_add  < QUOTA) begin $display("FAIL: quota ADD=%0d < %0d", q_add, QUOTA); $stop; end
      if (q_sub  < QUOTA) begin $display("FAIL: quota SUB=%0d < %0d", q_sub, QUOTA); $stop; end
      if (q_and  < QUOTA) begin $display("FAIL: quota AND=%0d < %0d", q_and, QUOTA); $stop; end
      if (q_or   < QUOTA) begin $display("FAIL: quota OR=%0d  < %0d", q_or,  QUOTA); $stop; end
      if (q_xor  < QUOTA) begin $display("FAIL: quota XOR=%0d < %0d", q_xor, QUOTA); $stop; end
      if (q_sll  < QUOTA) begin $display("FAIL: quota SLL=%0d < %0d", q_sll, QUOTA); $stop; end
      if (q_srl  < QUOTA) begin $display("FAIL: quota SRL=%0d < %0d", q_srl, QUOTA); $stop; end
      if (q_sra  < QUOTA) begin $display("FAIL: quota SRA=%0d < %0d", q_sra, QUOTA); $stop; end
      if (q_slt  < QUOTA) begin $display("FAIL: quota SLT=%0d < %0d", q_slt, QUOTA); $stop; end
      if (q_sltu < QUOTA) begin $display("FAIL: quota SLTU=%0d < %0d", q_sltu, QUOTA); $stop; end
    end
  endtask

//////////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    // Optional VCD for debug: +DUMP_VCD
    if ($test$plusargs("DUMP_VCD")) begin
      $dumpfile("waves_alu_regress.vcd");
      $dumpvars(0, tb_alu_regress);
    end

    // knobs
    SEED  = 1;
    NVECS = 10000;
    QUOTA = 200;

    if ($value$plusargs("SEED=%d", SEED)) begin end
    if ($value$plusargs("NVECS=%d", NVECS)) begin end
    if ($value$plusargs("QUOTA=%d", QUOTA)) begin end

    $display("TB_ALU_REGRESS: SEED=%0d NVECS=%0d QUOTA=%0d", SEED, NVECS, QUOTA);

    // init
    lfsr = (SEED == 0) ? 32'h1 : SEED;
    cov_init;
    quota_init();

    // Phase-1 quota warm-up: round-robin legal ops to avoid starvation
    for (i=0; i<QUOTA; i=i+1) begin
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_ADD);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_SUB);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_AND);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_OR );
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_XOR);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_SLL);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_SRL);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_SRA);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_SLT);
      lfsr = rand32(lfsr); check_one(pick_operand(lfsr), pick_operand(~lfsr), `ALU_OP_SLTU);
    end

    // Phase-2 weighted random (includes illegal ops)
    for (i=0; i<NVECS; i=i+1) begin
      lfsr = rand32(lfsr);
      op   = pick_opcode_weighted(lfsr);
      lfsr = rand32(lfsr);
      a    = pick_operand(lfsr);
      lfsr = rand32(lfsr);
      b    = pick_operand(lfsr);

      check_one(a,b,op);
    end

    quota_enforce_or_fail();
    cov_report;

    $display("TB_ALU_REGRESS: PASS");
    $finish;
  end

endmodule
