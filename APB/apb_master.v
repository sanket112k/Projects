`timescale 1ns/1ns
module apb_master(
    input pclk, presetn,
    input transfer, read_write,
    input [7:0] apb_write_addr, apb_read_addr,
    input [7:0] apb_write_data,
    input [7:0] prdata,
    input pready,
    output reg [7:0] apb_read_data,
    output reg [7:0] paddr, pwdata,
    output reg pwrite, psel, penable
);

localparam [1:0] IDLE = 2'd0, SETUP = 2'd1, ACCESS = 2'd2;
reg [1:0] state, next_state;

always @(posedge pclk) begin:Sequential_next_state_transition
    if (!presetn)       // Active low sync reset
        state <= IDLE;
    else
        state <= next_state;
end

always @(state or transfer or pready) begin:next_state_logic
    case (state)
        IDLE:    next_state = transfer ? SETUP : IDLE;
        SETUP:   next_state = ACCESS;
        ACCESS:  next_state = pready ? (transfer ? SETUP : IDLE) : ACCESS;
        default: next_state = IDLE;
    endcase
end

always @(*) begin:output_logic 
    case (state)
        IDLE: begin
            psel = 0;
            penable = 0;
        end

        SETUP: begin:setup
            psel   = 1;
            pwrite = ~read_write;
            if (read_write) paddr = apb_read_addr;
            else begin
                paddr  = apb_write_addr;
                pwdata = apb_write_data;
            end
        end

        ACCESS: begin:access
            penable = 1;
            if (pready) apb_read_data = prdata;
        end

        default: begin
            psel = 0;
            penable = 0;
        end
    endcase
end
endmodule
