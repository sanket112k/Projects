`timescale 1ns/1ns
module apb_test;
reg pclk, presetn;
reg transfer, read_write;
reg [7:0] apb_write_addr, apb_read_addr;
reg [7:0] apb_write_data;
wire [7:0] apb_read_data;

apb_top dut(
    pclk, presetn,
    transfer, read_write,
    apb_write_addr, apb_read_addr,
    apb_write_data,
    apb_read_data
);

initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
end

task write;
    input [7:0] waddr;
    input [7:0] wdata;

    begin
        @(negedge pclk);
        read_write = 0;
        apb_write_addr = waddr;
        apb_write_data = wdata;
        @(negedge pclk);
        $display("Writen data = %h at the addr = %h", wdata, waddr);
    end
endtask

task read;
    input [7:0] raddr;

    reg [7:0] rdata;
    begin
        @(negedge pclk);
        read_write = 1;
        apb_read_addr = raddr;
        @(negedge pclk);
        rdata = apb_read_data;
        $display("Read data = %h from the addr = %h", rdata, raddr);
    end
endtask

initial begin
    $dumpfile("apb_test.vcd");
    $dumpvars(0,apb_test);

    transfer = 0; read_write = 0;
    apb_write_addr = 0;
    apb_read_addr = 0;
    apb_write_data = 0;

    presetn = 0;
    repeat(2) @(negedge pclk);
    presetn = 1;

    transfer = 1;
    //@(negedge pclk);

    write(8'hAA, 8'h11);
    read(8'hAA);
    write(8'hBB, 8'h22);
    write(8'h77, 8'h67);
    write(8'h22, 8'h19);
    read(8'h77);
    read(8'hBB);
    read(8'h22);

    $finish;
end
endmodule
