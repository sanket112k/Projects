module bcd_counter #(parameter MAX_TENS = 5)(
	input clk,
    input reset,
    input ena,
    output [7:0] q,
    output wire carry
);

reg [3:0] msd;  // msd - most significant digit
reg [3:0] lsd;  // lsd - least significant digit

assign q = {msd, lsd};
assign carry = ena && (q == {MAX_TENS[3:0], 4'd9});

always @(posedge clk or posedge reset) begin
    if(reset)
        {msd, lsd} <= 8'h00;
    else if(ena) begin 
        if(lsd == 4'h9) begin
            if(msd == MAX_TENS)
                {msd, lsd} <= 8'h00;
            else begin
                lsd <= 4'h0;
                msd <= msd + 1'b1;
            end 
        end
        else
            lsd <= lsd + 1'b1; 
    end
end
endmodule
