// winner_logic.v - Combinational 5-way maximum with tie-breaking
// Spec §4.3: purely combinational; lower-indexed party wins on tie
// FIX: Module name is 'winner_logic' (was mismatched with 'winner_detect' in top)
module winner_logic #(
    parameter COUNT_W = 8
)(
    input  wire [COUNT_W-1:0] c0,   // DMK
    input  wire [COUNT_W-1:0] c1,   // ADMK
    input  wire [COUNT_W-1:0] c2,   // TVK
    input  wire [COUNT_W-1:0] c3,   // NTK
    input  wire [COUNT_W-1:0] c4,   // Other

    output reg  [2:0]         winner,     // index 0-4
    output reg  [COUNT_W-1:0] max_count
);
    // Purely combinational - no registers
    always @(*) begin
        // Start with party 0 (DMK) as default
        // Strict > means ties keep the lower-indexed party (correct per spec)
        winner    = 3'd0;
        max_count = c0;

        if (c1 > max_count) begin
            winner    = 3'd1;
            max_count = c1;
        end
        if (c2 > max_count) begin
            winner    = 3'd2;
            max_count = c2;
        end
        if (c3 > max_count) begin
            winner    = 3'd3;
            max_count = c3;
        end
        if (c4 > max_count) begin
            winner    = 3'd4;
            max_count = c4;
        end
        // When all counts are 0: winner=0, max_count=0 - correct per spec
    end
endmodule
