module fifo_sync #(
  parameter ADDR_WIDTH = 4
)(
  input xclk,
  input xreset,
  input [ADDR_WIDTH:0] ptr_in,
  output reg [ADDR_WIDTH:0] ptr_out
);
reg [ADDR_WIDTH:0] ptr_mid;

always @(posedge xclk) begin
    if (xreset) begin
        ptr_mid <= 0;
        ptr_out <= 0;
    end
    else begin
        ptr_mid <= ptr_in;
        ptr_out <= ptr_mid;
    end
end

endmodule
