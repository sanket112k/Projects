`timescale 1ns/1ns
`include "apb_master.v"
`include "apb_slave.v"
module apb_top(
    input pclk, presetn,
    input transfer, read_write,
    input [7:0] apb_write_addr, apb_read_addr,
    input [7:0] apb_write_data,
    output [7:0] apb_read_data
);
wire [7:0] prdata, pwdata, paddr;
wire pready, pwrite, psel, penable;

apb_master mdut(
    pclk, presetn,
    transfer, read_write,
    apb_write_addr, apb_read_addr,
    apb_write_data,
    prdata,
    pready,
    apb_read_data,
    paddr, pwdata,
    pwrite, psel, penable
);

apb_slave sdut(
    pclk, presetn,
    psel, penable, pwrite,
    paddr, pwdata,
    pready,
    prdata
);
endmodule
