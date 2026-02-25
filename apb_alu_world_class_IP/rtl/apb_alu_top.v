// -----------------------------------------------------------------------------
// APB_ALU IP — apb_alu_top: top-level (APB regs + alu_core + 1-cycle FSM).
// Start W1P latches operands/opcode and sets busy 1 cycle; then done sticky.
// Done cleared by W1C write to STATUS.bit1. Parameter: DW (default 32).
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
`include "alu_pkg.vh"
module apb_alu_top #(
  parameter integer DW = 32
)(
  input  wire         pclk,
  input  wire         presetn,

  // APB
  input  wire         psel,
  input  wire         penable,
  input  wire         pwrite,
  input  wire [7:0]   paddr,
  input  wire [31:0]  pwdata,
  output wire [31:0]  prdata,
  output wire         pready,
  output wire         pslverr
);

  // CSR outputs from regfile
  wire [DW-1:0] op_a, op_b;
  wire [3:0]    opcode;
  wire          start_pulse, done_clr_pulse;

  // FSM state registers
  reg           busy_r, done_r, err_illegal_op_r;
  reg [DW-1:0]  res_r;
  reg [3:0]     flags_r;

  // Latched operands/opcode for execution
  reg [DW-1:0]  a_lat, b_lat;
  reg [3:0]     op_lat;

  // ALU combinational outputs
  wire [DW-1:0] alu_y;
  wire [3:0]    alu_flags;
  wire          alu_illegal;
//////////////////////////////////////////////////////////////////////////////////
  alu_core #(.DW(DW)) u_alu (
    .a(a_lat),
    .b(b_lat),
    .op(op_lat),
    .y(alu_y),
    .flags(alu_flags),
    .illegal(alu_illegal)
  );

  apb_regs #(.DW(DW)) u_regs (
    .pclk(pclk),
    .presetn(presetn),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr),

    .op_a(op_a),
    .op_b(op_b),
    .opcode(opcode),
    .start_pulse(start_pulse),
    .done_clr_pulse(done_clr_pulse),

    .busy(busy_r),
    .done(done_r),
    .err_illegal_op(err_illegal_op_r),

    .result(res_r),
    .flags(flags_r)
  );
//////////////////////////////////////////////////////////////////////////////////
  // Minimal 1-cycle execute FSM
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      busy_r           <= 1'b0;         // busy_r=0; APB starts sendind data to ALU
      done_r           <= 1'b0;
      err_illegal_op_r <= 1'b0;
      res_r            <= {DW{1'b0}};
      flags_r          <= 4'h0;
      a_lat            <= {DW{1'b0}};
      b_lat            <= {DW{1'b0}};
      op_lat           <= 4'h0;
    end


    else begin
      // clear done sticky
      if (done_clr_pulse) done_r <= 1'b0;

      // launch exec on start (if not busy)
      if (start_pulse && !busy_r) begin
        // clear status for new op
        done_r           <= 1'b0;
        err_illegal_op_r <= 1'b0;

        // latch operands/opcode for this run
        a_lat  <= op_a;         // send data to ALU
        b_lat  <= op_b;         // send data to ALU
        op_lat <= opcode;       // send data to ALU

        busy_r <= 1'b1;         // one-cycle busy; ALU is busy till it is calculating
      end

      // complete exec if busy
      if (busy_r) begin
        res_r            <= alu_y;          // recieve data from ALU
        flags_r          <= alu_flags;      // recieve data from ALU
        err_illegal_op_r <= alu_illegal;    // recieve data from ALU

        busy_r           <= 1'b0;           // ALU has done; next start recieving data
        done_r           <= 1'b1;           // done calculating
      end
    end
  end

endmodule
