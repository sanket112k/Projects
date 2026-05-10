// seg7_controller.v - 4-digit multiplexed 7-segment display controller
// Spec §4.5: 1ms per digit scan period, active-LOW anodes and segments
// Encoding: IDLE=blank, PREDICT=P+party+count, VOTE=V+party+count, RESULT=E+winners+match
module seg7_controller #(
    parameter CLK_HZ = 50_000_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  mode,
    input  wire [2:0]  pred_winner,
    input  wire [2:0]  vote_winner,
    input  wire [7:0]  pred_max,
    input  wire [7:0]  vote_max,
    output reg  [3:0]  an,   // anode enables, active-LOW (one-hot 0)
    output reg  [7:0]  seg   // {dp,g,f,e,d,c,b,a}, active-LOW
);
    // 1ms per digit at 50MHz = 50,000 cycles
    localparam SCAN_DIV = CLK_HZ / 50_000;

    localparam IDLE    = 2'd0;
    localparam PREDICT = 2'd1;
    localparam VOTE    = 2'd2;
    localparam RESULT  = 2'd3;

    // Scan counter and digit selector
    reg [$clog2(SCAN_DIV)-1:0] scan_cnt;
    reg [1:0] digit_sel;   // 0=rightmost, 3=leftmost

    always @(posedge clk) begin
        if (rst) begin
            scan_cnt  <= 0;
            digit_sel <= 2'd0;
        end else begin
            if (scan_cnt == SCAN_DIV - 1) begin
                scan_cnt  <= 0;
                digit_sel <= digit_sel + 1'b1;
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end
        end
    end

    // 7-segment encoding function - active-LOW, {dp,g,f,e,d,c,b,a}
    function [7:0] enc7;
        input [3:0] d;
        begin
            case (d)
                4'h0: enc7 = 8'hC0;  // 0
                4'h1: enc7 = 8'hF9;  // 1
                4'h2: enc7 = 8'hA4;  // 2
                4'h3: enc7 = 8'hB0;  // 3
                4'h4: enc7 = 8'h99;  // 4
                4'h5: enc7 = 8'h92;  // 5
                4'h6: enc7 = 8'h82;  // 6
                4'h7: enc7 = 8'hF8;  // 7
                4'h8: enc7 = 8'h80;  // 8
                4'h9: enc7 = 8'h90;  // 9
                4'hA: enc7 = 8'h8C;  // P
                4'hB: enc7 = 8'hC1;  // V
                4'hC: enc7 = 8'h86;  // E
                4'hD: enc7 = 8'hBF;  // dash
                default: enc7 = 8'hFF; // blank
            endcase
        end
    endfunction

    // Digit value selection (combinational)
    reg [3:0] digit_val;

    always @(*) begin
        // Default: all anodes off (all digits off)
        an        = 4'b1111;
        digit_val = 4'hF;  // blank

        // Activate current digit
        an[digit_sel] = 1'b0;

        case (mode)
            IDLE: begin
                digit_val = 4'hF;  // blank all digits
            end

            PREDICT: begin
                // Digit 3(left)=P, 2=party(1-5), 1=pred_max[7:4], 0=pred_max[3:0]
                case (digit_sel)
                    2'd3: digit_val = 4'hA;                           // P glyph
                    2'd2: digit_val = {1'b0, pred_winner} + 4'd1;     // party 1-5
                    2'd1: digit_val = pred_max[7:4];                   // count high nibble
                    2'd0: digit_val = pred_max[3:0];                   // count low nibble
                endcase
            end

            VOTE: begin
                // Digit 3=V, 2=party(1-5), 1=vote_max[7:4], 0=vote_max[3:0]
                case (digit_sel)
                    2'd3: digit_val = 4'hB;                           // V glyph
                    2'd2: digit_val = {1'b0, vote_winner} + 4'd1;     // party 1-5
                    2'd1: digit_val = vote_max[7:4];                   // count high nibble
                    2'd0: digit_val = vote_max[3:0];                   // count low nibble
                endcase
            end

            RESULT: begin
                // Digit 3=E, 2=vote winner(1-5), 1=pred winner(1-5), 0=match(1 or 0)
                case (digit_sel)
                    2'd3: digit_val = 4'hC;                               // E glyph
                    2'd2: digit_val = {1'b0, vote_winner} + 4'd1;         // vote winner 1-5
                    2'd1: digit_val = {1'b0, pred_winner} + 4'd1;         // pred winner 1-5
                    2'd0: digit_val = (pred_winner == vote_winner) ? 4'h1 : 4'h0; // match
                endcase
            end
        endcase

        seg = enc7(digit_val);
    end
endmodule
