// edge_detect.v - Rising-edge pulse generator
// Outputs a single-cycle high pulse on the rising edge of sig
module edge_detect (
    input  wire clk,
    input  wire rst,
    input  wire sig,
    output wire rise_pulse
);
    reg sig_d;

    always @(posedge clk) begin
        if (rst) sig_d <= 1'b0;   // FIX: reset prevents glitch at power-up
        else     sig_d <= sig;
    end

    assign rise_pulse = sig & ~sig_d;
endmodule
