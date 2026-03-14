//`include "bcd_counter.v"
module digital_clock(
    input clk,
    input reset,    // async active high reset
    input ena,
    output reg pm,
    output reg [7:0] hh,
    output [7:0] mm,
    output [7:0] ss
);

wire carry_sec;
wire carry_min;
wire ena_sec = ena;
wire ena_min = carry_sec;

bcd_counter #(.MAX_TENS(5)) count_ss(
    .clk(clk),
    .reset(reset),
    .ena(ena_sec),
    .q(ss),
    .carry(carry_sec)
);
bcd_counter #(.MAX_TENS(5)) count_mm(
    .clk(clk),
    .reset(reset),
    .ena(ena_min),
    .q(mm),
    .carry(carry_min)
);

// hrs => 01am -> 02am -> .... -> 11am -> 12pm -> 01pm
always @(posedge clk or posedge reset) begin
    if(reset) begin
    	hh <= 8'h12;
        pm <= 1'b0;
    end
    else begin
        if(carry_min) begin
        	if(hh == 8'h11) begin      //if hh=11PM->12AM or 11AM->12PM
        		hh <= 8'h12;
           		pm <= ~pm;
            end
            else if(hh == 8'h12)
                hh <= 8'h01;           //hh changes:12AM->1AM or 12PM->1PM
            else if(hh[3:0] == 4'h9) begin
                hh[3:0] <= 4'h0;
                hh[7:4] <= hh[7:4] + 1'b1;
            end
            else hh[3:0] <= hh[3:0] + 1'b1;
        end
    end
end
endmodule
