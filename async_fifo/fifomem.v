module fifomem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input w_clk,
    input w_en,
    input [ADDR_WIDTH-1:0] w_addr,
    input [DATA_WIDTH-1:0] w_data,

    input r_clk,
    input r_en,
    input [ADDR_WIDTH-1:0] r_addr,
    output reg [DATA_WIDTH-1:0] r_data,
);

localparam RAM_DEPTH = 1 << ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];

always @ (posedge w_clk) begin:write
   if (w_en) mem[w_addr] <= w_data;
end

always @ (posedge r_clk) begin:read
    if(R_en) r_data <= mem[r_addr];
end

endmodule
