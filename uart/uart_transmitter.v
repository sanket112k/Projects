module uart_transmitter(
    input clk,
    input [7:0] data,   // 8-bit data to transmit
    input tx_start,     // Trigger transmission
    output reg tx_out,  // Serial output
    output tx_done      // Transmission complete
);

parameter CLK_FREQ = 50_000_000;
parameter BAUD_RATE = 9600;
localparam BIT_TIME = CLK_FREQ / BAUD_RATE;

reg [2:0] state = 0;
reg [8:0] shift_reg = 0;
wire p_bit;
reg [3:0] i = 0;
reg [15:0] count = 0;

parameter [2:0] IDLE  = 3'd0,
                START = 3'd1,
                DATA  = 3'd2,
                PARITY= 3'd3,
                STOP  = 3'd4;

assign p_bit = ~(^data);

always @(posedge clk) begin
    case (state)
        IDLE: begin  // Idle bit (1)
            tx_out <= 1;  
            if (tx_start) begin
                state <= START;
                count <= 0;
            end
        end
        START: begin  // Start bit (0)
            tx_out <= 0;
            i <= 0;
            if (count == BIT_TIME - 1) begin
                shift_reg <= {p_bit, data};
                count <= 0;
                state <= DATA;
            end else count <= count + 1;
        end
        DATA: begin  // Data bits (LSB first)
            tx_out <= shift_reg[i];
            if (count == BIT_TIME - 1) begin
                count <= 0;
                i = i + 1;
                if (i == 9) state <= STOP;
                else state <= DATA;
            end else count <= count + 1;
        end
        STOP: begin  // Stop bit (1)
            tx_out <= 1;
            i <= 0;
            if (count == BIT_TIME - 1) begin
                count <= 0;
                state <= IDLE;
            end else count <= count + 1;
        end
    endcase
end
assign tx_done = (state == STOP);
endmodule
