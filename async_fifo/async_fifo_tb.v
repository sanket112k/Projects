`timescale 1ns/1ps

module async_fifo_tb;
parameter DATA_WIDTH = 8;
parameter DEPTH = 16;

reg wclk;
reg wreset;
reg wen;
reg [DATA_WIDTH-1:0] wdata;
wire full;

reg rclk;
reg rreset;
reg ren;
wire [DATA_WIDTH-1:0] rdata;
wire empty;
wire rvalid;

fifo_top #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
) async_fifo(
    .wclk(wclk),
    .wreset(wreset),
    .wen(wen),
    .wdata(wdata),
    .rclk(rclk),
    .rreset(rreset),
    .ren(ren),
    .rdata(rdata),
    .full(full),
    .empty(empty),
    .rvalid(rvalid)
);

always #8  wclk = ~wclk;        // 62.5MHz
always #10 rclk = ~rclk;        // 50MHz

initial begin
    if ((DEPTH & (DEPTH - 1)) != 0) begin
        $error("DEPTH must be power of 2");
        $finish;
    end
end

initial begin
    wclk = 0;
    wen = 0;
    wdata = 0;
    rclk = 0;
    ren = 0;
    wreset = 1;
    rreset = 1;
 
    #20;
    wreset = 0;
    rreset = 0;

    $display("Writing to FIFO");

    while(!full) begin
        @(negedge wclk);
        wen = 1;
        wdata = wdata + 1;
    end

    @(negedge wclk);
    wen = 0;

    @(negedge wclk);
    wen = 1;
    wdata = 8'hAA;    // Try writing when FULL

    @(negedge wclk);
    wen = 0;
    $display("Reading from FIFO");
    while(!empty) begin
        @(negedge rclk);
        ren = 1;
    end

    @(negedge rclk);
    ren = 0;

    @(negedge rclk);
    ren = 1;            // Try reading when empty

    #50;
    $finish;
end

initial begin
    $monitor("Time=%0t | wen=%b ren=%b wdata=%h rdata=%h full=%b empty=%b rvalid=%b",
        $time, wen, ren, wdata, rdata, full, empty, rvalid);
    $dumpfile("async_fifo.vcd");
    $dumpvars(0, async_fifo_tb);
end
endmodule
