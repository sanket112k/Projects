module bcd_counter #(parameter MAX_TENS = 5)(
	input clk,
    input reset,
    input ena,
    output [7:0] q,
    output wire carry
);

reg [3:0] msb;
reg [3:0] lsb;

assign q = {msb, lsb};
assign carry = ena && (q == {MAX_TENS[3:0], 4'd9});

always @(posedge clk or posedge reset) begin
    if(reset)
        {msb, lsb} <= 8'h00;
    else if(ena) begin 
        if(lsb == 4'h9) begin
            if(msb == MAX_TENS)
                {msb, lsb} <= 8'h00;
            else begin
                lsb <= 4'h0;
                msb <= msb + 1'b1;
            end 
        end
        else
            lsb <= lsb + 1'b1; 
    end
end
endmodule
