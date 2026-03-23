/* FIFO top module
*           fifo_top
           /    |    \
          /     |     \
   write_ctrl  mem   read_ctrl
         |              |
       sync            sync
*/
module fifo_top #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
)(
    input wclk,
    input wreset,
    input wen,
    input [DATA_WIDTH-1:0] wdata,
    output full,

    input rclk,
    input rreset,
    input ren,
    output [DATA_WIDTH-1:0] rdata,
    output empty,
    output rvalid
);
localparam ADDR_WIDTH = $clog2(DEPTH);
wire [ADDR_WIDTH-1:0] waddr, raddr;
wire [ADDR_WIDTH:0] wptr_gray, rptr_gray, rptr_sync, wptr_sync;

fifo_mem #(DATA_WIDTH, ADDR_WIDTH) fifo_mem(
    .wclk(wclk),
    .wen(wen & ~full),
    .waddr(waddr),
    .wdata(wdata),

    .rclk(rclk),
    .ren(ren & ~empty),
    .raddr(raddr),
    .rdata(rdata)
);

fifo_sync #(ADDR_WIDTH) r2w(
    .xclk(wclk),
    .xreset(wreset),
    .ptr_in(rptr_gray),
    .ptr_out(rptr_sync)
);

fifo_sync #(ADDR_WIDTH) w2r(
    .xclk(rclk),
    .xreset(rreset),
    .ptr_in(wptr_gray),
    .ptr_out(wptr_sync)
);

write_ctrl #(ADDR_WIDTH) write_ctrl(
    .wclk(wclk),
    .wreset(wreset),
    .wen(wen),
    .rptr_sync(rptr_sync),
    .waddr(waddr),
    .wptr_gray(wptr_gray),
    .full(full)
);

read_ctrl #(ADDR_WIDTH) read_ctrl(
    .rclk(rclk),
    .rreset(rreset),
    .ren(ren),
    .wptr_sync(wptr_sync),
    .raddr(raddr),
    .rptr_gray(rptr_gray),
    .empty(empty),
    .rvalid(rvalid)
);

endmodule
