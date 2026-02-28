`timescale 1ns/1ps
`include "../rtl/alu_pkg.vh"
// -----------------------------------------------------------------------------
// APB smoke — Self-checking pure-Verilog TB: BFM tasks + compare vs reference.
// apb_write / apb_read / start_and_wait_done; run_case vs scoreboard; illegal-addr check.
// -----------------------------------------------------------------------------
module tb_apb_smoke;
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
  
  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
  end
////////////////////////////////////////////////////////////////////////
  task apb_write;           // write task- pwrite=1;
    input [7:0] addr;
    input [31:0] data;

    begin
      @(negedge pclk);      // setup state (psel=1; penable=0)
      psel <= 1; penable <= 0; pwrite <= 1; paddr <= addr; pwdata <= data;
      @(negedge pclk);      // access state (psel=1; penable=0)
      penable <= 1;
      @(negedge pclk);      // idle state (psel=0; penable=0)
      psel <= 0; penable <= 0; pwrite <= 0; paddr <= 0; pwdata <= 0;
    end
  endtask
////////////////////////////////////////////////////////////////////////
  task apb_read;            // read task- pwrite=0;
    input [7:0] addr;
    output [31:0] data;

    begin
      @(negedge pclk);      // setup state
      psel <= 1; penable <= 0; pwrite <= 0; paddr <= addr; pwdata <= 0;
      @(negedge pclk);      // access state
      penable <= 1;
      @(posedge pclk);      // wait for half cycle
      data = prdata;
      @(negedge pclk);      // idle state
      psel <= 0; penable <= 0; paddr <= 0;
    end
  endtask
///////////////////////////////////////////////////////////////////////
  task start_and_wait_done;

    integer guard;
    reg [31:0] st;

    begin
      apb_write(A_CTRL, 32'h1);     // write start_pulse

      guard = 0;
      st = 0;
      while (st[1] !== 1'b1) begin  // check status done != 1;
        apb_read(A_STATUS, st);     // read status

        guard = guard + 1;
        if (guard > 200) begin
          $display("FAIL(APB_SMOKE): timeout waiting done");
          $stop;
        end

      end
      apb_write(A_STATUS, 32'h2);   // write done_clr_pulse (write status)
    end
  endtask
//////////////////////////////////////////////////////////////////////
  task run_case;
    input [31:0] a;
    input [31:0] b;
    input [3:0]  op;

    reg [31:0] r_res;
    reg [31:0] r_flags;
    reg [31:0] st;
    reg [36:0] exp;
    reg [31:0] exp_y;
    reg [3:0]  exp_f;
    reg        exp_il;

    begin
      apb_write(A_OPA, a);          // write a
      apb_write(A_OPB, b);          // write b
      apb_write(A_OPCODE, {28'h0, op});     // write opcode
      start_and_wait_done;          // calling task start & wait done

      apb_read(A_STATUS, st);       // read status
      apb_read(A_RESULT, r_res);    // read result
      apb_read(A_FLAGS,  r_flags);  // read flags

      exp = sb.ref_alu(a,b,op);     // call scoreboard function
      exp_il = exp[36];             // expected illegal_opcode
      exp_f  = exp[35:32];          // expected flags
      exp_y  = exp[31:0];           // expected result

      if (r_res !== exp_y) begin
        $display("FAIL(APB_SMOKE): RES a=%h b=%h op=%h exp=%h got=%h", a,b,op,exp_y,r_res);
        $stop;
      end
      if (r_flags[3:0] !== exp_f) begin
        $display("FAIL(APB_SMOKE): FLAGS a=%h b=%h op=%h exp=%b got=%b", a,b,op,exp_f,r_flags[3:0]);
        $stop;
      end
      if (st[2] !== exp_il) begin
        $display("FAIL(APB_SMOKE): ILLEGAL a=%h b=%h op=%h exp=%b got=%b", a,b,op,exp_il,st[2]);
        $stop;
      end
    end
  endtask
//////////////////////////////////////////////////////////////////
  task illegal_addr_check;
    reg [31:0] d;
    begin
      apb_read(8'h7C, d);
      if (pslverr !== 1'b1) begin
        $display("FAIL(APB_SMOKE): expected PSLVERR=1 on illegal addr");
        $stop;
      end
    end
  endtask
///////////////////////////////////////////////////////////////////
  initial begin
    $dumpfile("waves_apb_smoke.vcd");
    $dumpvars(0,tb_apb_smoke);

    psel=0; penable=0; pwrite=0; paddr=0; pwdata=0;
    presetn=0;
    repeat(5) @(negedge pclk);
    presetn=1;

    illegal_addr_check();

    run_case(32'h1,         32'h2, `ALU_OP_ADD);
    run_case(32'h7FFF_FFFF, 32'h1, `ALU_OP_ADD);        // overflow
    run_case(32'h0,         32'h1, `ALU_OP_SUB);        // borrow
    run_case(32'h8000_0000, 32'h1, `ALU_OP_SRA);
    run_case(32'hFFFF_FFFF, 32'h1, `ALU_OP_SLT);
    run_case(32'hFFFF_FFFF, 32'h1, `ALU_OP_SLTU);
    run_case(32'h1234,      32'h5678, 4'hF);          // illegal opcode

    $display("TB_APB_SMOKE: PASS");
    $finish;
  end

endmodule
