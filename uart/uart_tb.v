`timescale 1ns/1ns;
module uart_tb;
reg clk;
reg [7:0] data;
reg tx_start;
wire tx_done;
wire rx_done;
wire [7:0] data_out;

uart_topmodule dut(
    .clk(clk),
    .data(data),
    .tx_start(tx_start),
    .tx_done(tx_done),
    .data_out(data_out),
    .rx_done(rx_done)
);

always #10 clk = ~clk;

initial begin
   clk = 0;
   tx_start = 1;
   data = 8'hff;
   @(negedge tx_done);
   data = 8'h00;
   @(negedge tx_done);
   data = 8'h55;
   @(negedge tx_done);
   data = 8'h99;
   @(negedge tx_done);
   data = 8'h01;
   @(negedge tx_done);
   data = 8'h10;
   @(negedge tx_done);
   data = 8'h08;
   @(negedge tx_done);
   data = 8'h80;
   @(negedge tx_done);
   #100_000 $finish;
end

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0,uart_tb);
end
endmodule
