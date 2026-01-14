module uart_receiver(
    input clk,
    input rx_in,
    output [7:0] data,
    output rx_done     // Indicates that the data is recieved and also it is valid
);

parameter CLK_FREQ = 50_000_000;
parameter BAUD_RATE = 9600;
parameter BIT_TIME = CLK_FREQ / BAUD_RATE;

reg [2:0] state = 0, next = 0;
reg [7:0] out_reg;
reg data_valid;
reg [3:0] i = 0;
reg [15:0] count = 0;
parameter [2:0] IDLE = 3'd0,
                START= 3'd1,
                DATA = 3'd2,
                CHECK= 3'd3,     //parity check
                WAIT = 3'd4,
                STOP = 3'd5;

/************************************************************************************/
always @(*) begin 		// State transition logic
    case(state)
        IDLE    : next = rx_in ? IDLE : START;
        START   : next = DATA;
        DATA    : next = (i==7) ? CHECK : DATA;      // 0 to 7 = data; and 8th is parity
        CHECK   : next = rx_in ? STOP : WAIT;
        WAIT    : next = rx_in ? IDLE : WAIT;           // wait till stop bit is recieved
        STOP    : next = rx_in ? IDLE : START;
        default : next = IDLE;
    endcase
end

/************************************************************************************/

always @(posedge clk) begin
    if (state == IDLE) begin
        state <= next;
        count <= 0;
    end
    else if (state >= START && state <= STOP) begin 
        if (count == BIT_TIME - 1) begin
            state <= next;
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end
    else begin 
        state <= IDLE;
        count <= 0;
    end
end

always @(posedge clk) begin
    case(state)
        DATA : if (count == BIT_TIME/2 -1) out_reg[i] <= rx_in;     //Sampling at half bit time
        CHECK: if (count == BIT_TIME/2 -1) data_valid <= ^out_reg^rx_in;
    endcase
end

/**************************************************************************/

always @(posedge clk) begin
    case(state)
        START: i <= 0;
        DATA : if (count == BIT_TIME -1) i <= i + 1;
        default: i <= 0;
    endcase
end

assign rx_done = ((state == STOP) && data_valid);     //process complete indicator
assign data = (rx_done) ? out_reg : 8'b0;          //output

endmodule
