// Write-domain to read-domain synchronizer
module sync_w2r #(
    parameter ADDR_WIDTH = 4
)(
    input rclk,
    input rreset,
    input [ADDR_WIDTH:0] wptr,
    output reg [ADDR_WIDTH:0] rwptr2
);
reg [ADDR_WIDTH:0] rwptr1;
always @(posedge rclk) begin
    if (rreset) begin
        rwptr1 <= 0;
        rwptr2 <= 0;
    end
    else begin
        rwptr1 <= wptr;
        rwptr2 <= rwptr1;
    end
end
endmodule
