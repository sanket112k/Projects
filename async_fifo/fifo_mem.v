// FIFO memory buffer
module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wclk,
    input wen,
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] wdata,

    input rclk,
    input ren,
    input [ADDR_WIDTH-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rdata
);
localparam RAM_DEPTH = 1 << ADDR_WIDTH;
reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];

always @(posedge wclk)
    if (wen) mem[waddr] <= wdata;

always @(posedge rclk)
    if (ren) rdata <= mem[raddr];

endmodule
