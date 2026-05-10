// uart_reporter.v - UART message serialiser
// On trigger pulse, sends "P=X V=Y\r\n" (9 bytes) over UART
// FIX: Last byte (ptr==8) is now correctly sent before clearing 'sending'
// FIX: ptr advances before clearing 'sending' to avoid double-send edge case
module uart_reporter (
    input  wire       clk,
    input  wire       rst,
    input  wire       trigger,         // one-cycle pulse: begin sending
    input  wire [2:0] pred_winner,     // 0-4
    input  wire [2:0] vote_winner,     // 0-4
    output reg        tx_valid,        // connect to uart_tx valid
    output reg  [7:0] tx_data,         // connect to uart_tx data
    input  wire       tx_busy          // connect to uart_tx busy
);
    reg        sending;
    reg [3:0]  ptr;           // byte index 0-8
    reg [7:0]  msg [0:8];     // 9-byte message buffer

    // States for the byte-send handshake
    localparam WAIT_FREE  = 1'b0;   // waiting for tx_busy=0
    localparam SEND_BYTE  = 1'b1;   // asserting tx_valid for one cycle
    reg send_state;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            sending     <= 1'b0;
            ptr         <= 4'd0;
            tx_valid    <= 1'b0;
            tx_data     <= 8'd0;
            send_state  <= WAIT_FREE;
            for (i = 0; i < 9; i = i + 1) msg[i] <= 8'd0;
        end else begin
            // Default: de-assert valid every cycle (spec §4.7.4)
            tx_valid <= 1'b0;

            // Accept trigger only when not already sending
            if (trigger && !sending) begin
                // Build the 9-byte message
                msg[0] <= 8'h50;                              // 'P'
                msg[1] <= 8'h3D;                              // '='
                msg[2] <= 8'h31 + {5'h0, pred_winner};       // '1'..'5'
                msg[3] <= 8'h20;                              // ' '
                msg[4] <= 8'h56;                              // 'V'
                msg[5] <= 8'h3D;                              // '='
                msg[6] <= 8'h31 + {5'h0, vote_winner};       // '1'..'5'
                msg[7] <= 8'h0D;                              // CR
                msg[8] <= 8'h0A;                              // LF
                ptr        <= 4'd0;
                sending    <= 1'b1;
                send_state <= WAIT_FREE;
            end

            if (sending) begin
                case (send_state)
                    WAIT_FREE: begin
                        // Wait until uart_tx is not busy
                        if (!tx_busy) begin
                            tx_valid   <= 1'b1;
                            tx_data    <= msg[ptr];
                            send_state <= SEND_BYTE;
                        end
                    end

                    SEND_BYTE: begin
                        // tx_valid was high last cycle - uart_tx has latched the byte
                        // FIX: advance ptr, then check if we just sent the last byte
                        if (ptr == 4'd8) begin
                            sending    <= 1'b0;  // all 9 bytes sent
                            send_state <= WAIT_FREE;
                        end else begin
                            ptr        <= ptr + 1'b1;
                            send_state <= WAIT_FREE;  // wait for busy before next byte
                        end
                    end
                endcase
            end
        end
    end
endmodule
