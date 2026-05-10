`timescale 1ns / 1ps

// debounce.v - Button de-glitch filter
// Waits for input to be stable for COUNT_MAX cycles before updating output
module debounce #(
    parameter COUNT_MAX = 500_000  // ~20ms at 50MHz
)(
    input  wire clk,
    input  wire rst,
    input  wire noisy,
    output reg  clean
);
    reg [$clog2(COUNT_MAX)-1:0] cnt;
    reg sync0, sync1;

    // Double-flop synchroniser to prevent metastability
    always @(posedge clk) begin
        if (rst) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
            cnt   <= 0;
            clean <= 1'b0;
        end else begin
            sync0 <= noisy;
            sync1 <= sync0;

            if (sync1 == clean) begin
                cnt <= 0;                      // input matches output - reset counter
            end else if (cnt == COUNT_MAX - 1) begin
                clean <= sync1;                // stable long enough - accept
                cnt   <= 0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
