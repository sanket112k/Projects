module enable_generator #(parameter CLK_FREQ = 50_000_000)(
    input clk,
    input reset,
    output reg ena_1hz
);
localparam COUNT_MAX = CLK_FREQ - 1;
reg [$clog2(COUNT_MAX)-1:0] count;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        count   <= 0;
        ena_1hz <= 0;
    end
    else if (count == COUNT_MAX) begin
        count   <= 0;
        ena_1hz <= 1;
    end
    else begin
        count   <= count + 1;
        ena_1hz <= 0;
    end
end
endmodule
