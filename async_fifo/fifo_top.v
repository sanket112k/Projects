// FIFO top-level module
module fifo_top #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input wclk,
    input wreset,
    input winc,
    output full,
    output [DATA_WIDTH-1:0] wdata,

    input rclk,
    input rreset,
    input rinc,
    output empty,
    output [DATA_WIDTH-1:0] rdata
);
wire [ADDR_WIDTH-1:0] waddr, raddr;
wire [ADDR_WIDTH:0] wptr, rptr, wrptr2, rwptr2;

sync_r2w sync_r2w
(.wrptr2(wrptr2), .rptr(rptr),
.wclk(wclk), .wrst_n(wrst_n));

sync_w2r sync_w2r
(.rwptr2(rwptr2), .wptr(wptr),
.rclk(rclk), .rrst_n(rrst_n));

fifomem #(DSIZE, ASIZE) fifomem
(.rdata(rdata), .wdata(wdata),
.waddr(waddr), .raddr(raddr),
.wclken(winc), .wclk(wclk));

rptr_empty #(ASIZE) rptr_empty
(.rempty(rempty), .raddr(raddr),
.rptr(rptr), .rwptr2(rwptr2),
.rinc(rinc), .rclk(rclk), .rrst_n(rrst_n));

wptr_full #(ASIZE) wptr_full
(.wfull(wfull), .waddr(waddr),
.wptr(wptr), .wrptr2(wrptr2),
.winc(winc), .wclk(wclk), .wrst_n(wrst_n));
endmodule
