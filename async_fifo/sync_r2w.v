// Read-domain to write-domain synchronizer
module sync_r2w #(
  parameter ADDR_WIDTH = 4
)(
  input wclk,
  input wreset,
  input [ADDR_WIDTH:0] rptr,
  output reg [ADDR_WIDTH:0] wrptr2
);
reg [ADDR_WIDTH:0] wrptr1;
always @(posedge wclk) begin
    if (wreset) begin
        wrptr1 <= 0;
        wrptr2 <= 0;
    else begin
        wrptr1 <= rptr;
        wrptr2 <= wrptr1;
    end
end
endmodule
