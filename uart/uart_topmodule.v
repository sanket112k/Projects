module uart_topmodule(
    input clk,
    input [7:0] data,
    input tx_start,
    output tx_done,
    output rx_done,
    output [7:0] data_out
);

wire bus;

uart_transmitter tx(
    .clk(clk),
    .data(data),
    .tx_start(tx_start),
    .tx_out(bus),
    .tx_done(tx_done)
);

uart_receiver rx(
    .clk(clk),
    .data(data_out),
    .rx_in(bus),
    .rx_done(rx_done)
);

endmodule
