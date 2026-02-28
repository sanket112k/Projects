`timescale 1ns/1ps
`include "../rtl/alu_pkg.vh"
// -----------------------------------------------------------------------------
// APB regression — Self-checking pure-Verilog TB: random sequences + negative depth.
// Illegal addr (read/write PSLVERR), double-start, write-while-busy,
// start-without-programming, clear-done-when-not-set; coverage surrogate.
// -----------------------------------------------------------------------------
module tb_apb_regress;
  localparam integer DW = 32;

  reg         pclk;
  reg         presetn;
  reg         psel;
  reg         penable;
  reg         pwrite;
  reg [7:0]   paddr;
  reg [31:0]  pwdata;
  wire [31:0] prdata;
  wire        pready;
  wire        pslverr;

  apb_alu_top #(.DW(DW)) dut (
    .pclk(pclk), .presetn(presetn),
    .psel(psel), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata),
    .prdata(prdata), .pready(pready), .pslverr(pslverr)
  );

  scoreboard sb();

  localparam [7:0] A_CTRL   = 8'h00;
  localparam [7:0] A_STATUS = 8'h04;
  localparam [7:0] A_OPA    = 8'h08;
  localparam [7:0] A_OPB    = 8'h0C;
  localparam [7:0] A_OPCODE = 8'h10;
  localparam [7:0] A_RESULT = 8'h14;
  localparam [7:0] A_FLAGS  = 8'h18;

  integer i;
  integer NOPS;
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

  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
  end

  task apb_write;
    input [7:0] addr;
    input [31:0] data;
    begin
      @(negedge pclk);
      psel<=1; pwrite<=1; paddr<=addr; pwdata<=data; penable<=0;
      @(negedge pclk);
      penable<=1;
      @(negedge pclk);
      psel<=0; penable<=0; pwrite<=0; paddr<=0; pwdata<=0;
    end
  endtask

  task apb_read;
    input [7:0] addr;
    output [31:0] data;
    begin
      @(negedge pclk);
      psel<=1; pwrite<=0; paddr<=addr; pwdata<=0; penable<=0;
      @(negedge pclk);
      penable<=1;
      @(posedge pclk);
      data = prdata;
      @(negedge pclk);
      psel<=0; penable<=0; paddr<=0;
    end
  endtask

  task poll_done_guarded;
    integer guard;
    reg [31:0] st;
    begin
      guard = 0;
      st = 0;
      while (st[1] !== 1'b1) begin
        apb_read(A_STATUS, st);
        guard = guard + 1;
        if (guard > 300) begin
          $display("FAIL(APB_REGRESS): timeout waiting done");
          $stop;
        end
      end
    end
  endtask

  function [3:0] pick_opcode_weighted;
    input [31:0] r;
    reg [31:0] m;
    begin
      m = r % 100;
      if (m < 80) begin
        // legal set
        case (r[3:0] % 10)
          0: pick_opcode_weighted = `ALU_OP_ADD;
          1: pick_opcode_weighted = `ALU_OP_SUB;
          2: pick_opcode_weighted = `ALU_OP_AND;
          3: pick_opcode_weighted = `ALU_OP_OR;
          4: pick_opcode_weighted = `ALU_OP_XOR;
          5: pick_opcode_weighted = `ALU_OP_SLL;
          6: pick_opcode_weighted = `ALU_OP_SRL;
          7: pick_opcode_weighted = `ALU_OP_SRA;
          8: pick_opcode_weighted = `ALU_OP_SLT;
          default: pick_opcode_weighted = `ALU_OP_SLTU;
        endcase
      end else begin
        pick_opcode_weighted = 4'hA + (r[3:0] % 6); // illegal
      end
    end
  endfunction

  function [31:0] pick_operand;
    input [31:0] r;
    reg [31:0] cls;
    begin
      cls = r % 100;
      if (cls < 50) pick_operand = r;
      else if (cls < 75) begin
        case (r[3:0])
          4'h0: pick_operand = 32'h0;
          4'h1: pick_operand = 32'h1;
          4'h2: pick_operand = 32'h7FFF_FFFF;
          4'h3: pick_operand = 32'h8000_0000;
          4'h4: pick_operand = 32'hFFFF_FFFF;
          4'h5: pick_operand = 32'hAAAA_AAAA;
          4'h6: pick_operand = 32'h5555_5555;
          default: pick_operand = r;
        endcase
      end else begin
        pick_operand = (r[0]) ? (32'h1 << (r[4:0])) : ~(32'h1 << (r[4:0]));
      end
    end
  endfunction

  task do_one_valid_sequence;
    input [31:0] a;
    input [31:0] b;
    input [3:0]  op;
    reg [31:0] st;
    reg [31:0] r_res;
    reg [31:0] r_flags;
    reg [36:0] exp;
    reg [31:0] exp_y;
    reg [3:0]  exp_f;
    reg        exp_il;
    begin
      // program
      apb_write(A_OPA, a);
      apb_write(A_OPB, b);
      apb_write(A_OPCODE, {28'h0, op});

      // start
      apb_write(A_CTRL, 32'h1);

      // poll done
      poll_done_guarded();

      // readback
      apb_read(A_STATUS, st);
      apb_read(A_RESULT, r_res);
      apb_read(A_FLAGS,  r_flags);

      // clear done
      apb_write(A_STATUS, 32'h2);

      exp = sb.ref_alu(a,b,op);
      exp_il = exp[36];
      exp_f  = exp[35:32];
      exp_y  = exp[31:0];

      // compare
      if (r_res !== exp_y) begin
        $display("FAIL(APB_REGRESS): SEED=%0d IDX=%0d RES a=%h b=%h op=%h exp=%h got=%h", SEED, i, a,b,op,exp_y,r_res);
        $stop;
      end
      if (r_flags[3:0] !== exp_f) begin
        $display("FAIL(APB_REGRESS): SEED=%0d IDX=%0d FLAGS a=%h b=%h op=%h exp=%b got=%b", SEED, i, a,b,op,exp_f,r_flags[3:0]);
        $stop;
      end
      if (st[2] !== exp_il) begin
        $display("FAIL(APB_REGRESS): SEED=%0d IDX=%0d ILLEGAL a=%h b=%h op=%h exp=%b got=%b", SEED, i, a,b,op,exp_il,st[2]);
        $stop;
      end

      // coverage surrogate sample (uses module-level cov_*)
      cov_sample(op, exp_f, exp_il, b[4:0],
                 (op==`ALU_OP_ADD), (op==`ALU_OP_SUB));
    end
  endtask

  // Negative: illegal address should assert PSLVERR during access (read and write)
  task negative_illegal_addr;
    reg [31:0] d;
    reg        slverr_seen;
    begin
      // Illegal read
      apb_read(8'h7C, d);
      if (pslverr !== 1'b1) begin
        $display("FAIL(APB_REGRESS): expected PSLVERR=1 on illegal read addr");
        $stop;
      end
      // Illegal write: drive APB and sample PSLVERR during access phase
      @(negedge pclk);
      psel<=1; pwrite<=1; paddr<=8'h7C; pwdata<=32'hDEAD_BEEF; penable<=0;
      @(negedge pclk);
      penable<=1;
      @(posedge pclk);
      slverr_seen = pslverr;
      @(negedge pclk);
      psel<=0; penable<=0; pwrite<=0; paddr<=0; pwdata<=0;
      if (slverr_seen !== 1'b1) begin
        $display("FAIL(APB_REGRESS): expected PSLVERR=1 on illegal write addr");
        $stop;
      end
      // Ensure no X propagation
      apb_read(A_STATUS, d);
      if (^d === 1'bX) begin
        $display("FAIL(APB_REGRESS): X detected after illegal write");
        $stop;
      end
    end
  endtask

  // Negative: misuse sequences (should not break determinism)
  task negative_misuse_sequences;
    reg [31:0] st, r_res, r_flags;
    begin
      // start without programming (uses reset defaults)
      apb_write(A_CTRL, 32'h1);
      poll_done_guarded();
      apb_read(A_STATUS, st);
      apb_read(A_RESULT, r_res);
      apb_read(A_FLAGS,  r_flags);
      apb_write(A_STATUS, 32'h2);

      // double-start (second start while busy should be ignored)
      apb_write(A_OPA, 32'h10);
      apb_write(A_OPB, 32'h20);
      apb_write(A_OPCODE, {28'h0, `ALU_OP_ADD});
      apb_write(A_CTRL, 32'h1);
      // immediately start again (likely while busy)
      apb_write(A_CTRL, 32'h1);
      poll_done_guarded();
      apb_write(A_STATUS, 32'h2);

      // write while busy should not affect current run (because operands/op are latched on start)
      apb_write(A_OPA, 32'h1);
      apb_write(A_OPB, 32'h2);
      apb_write(A_OPCODE, {28'h0, `ALU_OP_ADD});
      apb_write(A_CTRL, 32'h1);
      // try to corrupt programmed regs after start (should not affect current latched exec)
      apb_write(A_OPA, 32'hFFFF_FFFF);
      apb_write(A_OPB, 32'hFFFF_FFFF);
      apb_write(A_OPCODE, {28'h0, `ALU_OP_SUB});
      poll_done_guarded();
      apb_read(A_RESULT, r_res);
      if (r_res !== 32'h3) begin
        $display("FAIL(APB_REGRESS): write-while-busy affected result unexpectedly. got=%h exp=00000003", r_res);
        $stop;
      end
      apb_write(A_STATUS, 32'h2);

      // clear done even when not done: should be harmless
      apb_write(A_STATUS, 32'h2);
      apb_read(A_STATUS, st);
      if (st[1] !== 1'b0) begin
        $display("FAIL(APB_REGRESS): done should remain 0 after clearing when not set");
        $stop;
      end
    end
  endtask

  initial begin
    // Optional VCD for debug: +DUMP_VCD
    if ($test$plusargs("DUMP_VCD")) begin
      $dumpfile("waves_apb_regress.vcd");
      $dumpvars(0, tb_apb_regress);
    end

    // knobs
    SEED = 1;
    NOPS = 300;
    if ($value$plusargs("SEED=%d", SEED)) begin end
    if ($value$plusargs("NOPS=%d", NOPS)) begin end

    $display("TB_APB_REGRESS: SEED=%0d NOPS=%0d", SEED, NOPS);

    // init
    psel=0; penable=0; pwrite=0; paddr=0; pwdata=0;
    presetn=0;
    lfsr = (SEED == 0) ? 32'h1 : SEED;

    cov_init;

    repeat(5) @(negedge pclk);
    presetn=1;

    // Negative suites first
    negative_illegal_addr();
    negative_misuse_sequences();

    // Valid random sequences
    for (i=0; i<NOPS; i=i+1) begin
      lfsr = rand32(lfsr);
      do_one_valid_sequence(
        pick_operand(lfsr),
        pick_operand(~lfsr),
        pick_opcode_weighted(lfsr)
      );
    end

    cov_report;

    $display("TB_APB_REGRESS: PASS");
    $finish;
  end

endmodule
