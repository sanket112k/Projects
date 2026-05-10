// uart_tx.v - 8N1 UART transmitter
// 8 data bits, no parity, 1 stop bit, LSB first
// FIX: busy is now correctly set/cleared - asserted on load, deasserted after stop bit
module uart_tx #(
    parameter CLK_HZ = 50_000_000,
    parameter BAUD   = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       valid,    // assert one cycle to load and start transmit
    input  wire [7:0] data,     // byte to send (sampled when valid=1)
    output reg        tx,       // serial output, idle HIGH
    output reg        busy      // HIGH from start bit through end of stop bit
);
    // BAUD_DIV = floor(CLK_HZ / BAUD) = 434 cycles at 50MHz/115200
    localparam BAUD_DIV = CLK_HZ / BAUD;
    localparam BD_W     = $clog2(BAUD_DIV + 1);

    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0]      state;
    reg [BD_W-1:0] baud_cnt;
    reg [3:0]      bit_cnt;
    reg [7:0]      shreg;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            tx       <= 1'b1;   // idle line HIGH
            busy     <= 1'b0;
            baud_cnt <= 0;
            bit_cnt  <= 4'd0;
            shreg    <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (valid) begin
                        shreg    <= data;       // latch byte on valid
                        busy     <= 1'b1;       // FIX: assert busy immediately
                        baud_cnt <= 0;
                        bit_cnt  <= 4'd0;
                        state    <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0;                 // start bit LOW
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        state    <= S_DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                S_DATA: begin
                    tx <= shreg[0];             // LSB first
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        shreg    <= {1'b0, shreg[7:1]};  // right shift
                        if (bit_cnt == 4'd7) begin
                            state   <= S_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1;                 // stop bit HIGH
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        // FIX: return to IDLE; busy will be cleared next cycle
                        state    <= S_IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    tx    <= 1'b1;
                    busy  <= 1'b0;
                end
            endcase
        end
    end
endmodule
