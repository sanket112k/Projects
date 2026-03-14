//`include "enable_generator.v"
//`include "digital_clock.v"
module clock_top(
    input clk,       // 50 MHz
    input reset,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss,
    output pm
);

wire ena_1hz;

enable_generator u1 (
    .clk(clk),
    .reset(reset),
    .ena_1hz(ena_1hz)
);

digital_clock u2 (
    .clk(clk),
    .reset(reset),
    .ena(ena_1hz),
    .pm(pm),
    .hh(hh),
    .mm(mm),
    .ss(ss)
);

endmodule
