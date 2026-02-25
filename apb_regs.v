// -----------------------------------------------------------------------------
// APB_ALU IP — apb_regs: APB3 register file.
// 8-bit paddr; PREADY=1; PSLVERR on illegal address (read/write).
// CTRL.start W1P, STATUS.done W1C. Parameter: DW (default 32).
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module apb_regs #(
  parameter integer DW = 32
)(
  input  wire         pclk,         // clk
  input  wire         presetn,      // active low reset

  // APB---------------------
  input  wire         psel,         // Select line
  input  wire         penable,      // indicates that master is available for transaction
  input  wire         pwrite,       // W/R control signal
  input  wire [7:0]   paddr,        // address bus from master to slave
                                    // APB has single address bus; it has
                                    // 2 independent data bus pwdata and prdata
  input  wire [31:0]  pwdata,       // Write data bus from master to slave
  
  output reg  [31:0]  prdata,       // Read data bus from slave to master
  output wire         pready,       // indicates that slave is ready for the transaction
  output reg          pslverr,      // Slave error

  // CSR outputs-------------
  output reg  [DW-1:0] op_a,
  output reg  [DW-1:0] op_b,
  output reg  [3:0]    opcode,
  output reg           start_pulse,
  output reg           done_clr_pulse,

  // status inputs----------
  input  wire          busy,
  input  wire          done,
  input  wire          err_illegal_op,

  // result inputs----------
  input  wire [DW-1:0] result,
  input  wire [3:0]    flags
);

  // Address map
  localparam [7:0] A_CTRL   = 8'h00;    // prdata = 32'h0;              // if (pwdata[0]) start_pulse <= 1'b1;
localparam [7:0] A_STATUS = 8'h04;    // prdata = {29'h0, err_illegal_op, done, busy};
                                        // if (pwdata[1]) done_clr_pulse <= 1'b1;
  localparam [7:0] A_OPA    = 8'h08;    // prdata = op_a;               // op_a   <= pwdata[DW-1:0];
  localparam [7:0] A_OPB    = 8'h0C;    // prdata = op_b;               // op_b   <= pwdata[DW-1:0];
  localparam [7:0] A_OPCODE = 8'h10;    // prdata = {28'h0, opcode};    // opcode <= pwdata[3:0];
  localparam [7:0] A_RESULT = 8'h14;    // prdata = result;             // --
  localparam [7:0] A_FLAGS  = 8'h18;    // prdata = {28'h0, flags};     // --
///////////////////////////////////////////////////////////////////////////////
  assign pready = 1'b1;                 // always ready (no wait states)

  wire apb_access = psel & penable;     // access state

  // Read mux + error response
  always @(*) begin
    prdata  = 32'h0;
    pslverr = 1'b0;

    if (psel) begin                     // slave selected by master // latch interferance
      case (paddr)
        A_CTRL: begin
          // CTRL is write-only; reads return 0 by policy
          prdata = 32'h0;
        end
        A_STATUS: begin
          prdata[0] = busy;
          prdata[1] = done;
          prdata[2] = err_illegal_op;
        end
        A_OPA:    prdata = op_a;
        A_OPB:    prdata = op_b;
        A_OPCODE: prdata = {28'h0, opcode};
        A_RESULT: prdata = result;
        A_FLAGS:  prdata = {28'h0, flags};
        default: begin
          prdata  = 32'h0;
          pslverr = apb_access;         // only assert error for actual access
        end
      endcase
    end
  end

  // Writes
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      op_a           <= {DW{1'b0}};
      op_b           <= {DW{1'b0}};
      opcode         <= 4'h0;
      start_pulse    <= 1'b0;
      done_clr_pulse <= 1'b0;
    end else begin
      // default pulses low
      start_pulse    <= 1'b0;
      done_clr_pulse <= 1'b0;

      if (apb_access && pwrite && !pslverr) begin       //access(psel = 1 & penable = 1); pwrite = 1; pslverr = 0;
        case (paddr)
          A_CTRL: begin
            if (pwdata[0]) start_pulse <= 1'b1;         // W1P
          end
          A_STATUS: begin
            if (pwdata[1]) done_clr_pulse <= 1'b1;      // W1C on done
          end
          A_OPA:    op_a   <= pwdata[DW-1:0];
          A_OPB:    op_b   <= pwdata[DW-1:0];
          A_OPCODE: opcode <= pwdata[3:0];
          default: begin
            // illegal writes: ignored; pslverr is asserted via read comb policy on illegal addr
          end
        endcase
      end
    end
  end

endmodule
