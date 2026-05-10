// poll_renderer_advanced.v - VGA pixel renderer for exit poll dashboard
// Produces 4-bit RGB pixel output as combinational function of (x, y, counts, mode)
//
// FIXES applied:
//  1. Header color is now mode-dependent (spec Table 1)
//  2. Static "RESULT" label removed from header (was overlapping dynamic mode text)
//  3. Bar width now uses spec formula: min(510, count*2) via left-shift
//  4. percent_val uses 16-bit intermediate to prevent overflow
//  5. Font ROM now includes digit glyphs '0'-'9' (were missing - rendered blank)
//  6. Blink counter reset on rst input

module poll_renderer_advanced #(
    parameter COUNT_W = 8
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire        active,
    input  wire [1:0]  mode,
    input  wire [2:0]  pred_winner,
    input  wire [2:0]  vote_winner,
    input  wire [COUNT_W-1:0] pred_dmk,
    input  wire [COUNT_W-1:0] pred_admk,
    input  wire [COUNT_W-1:0] pred_tvk,
    input  wire [COUNT_W-1:0] pred_ntk,
    input  wire [COUNT_W-1:0] pred_other,
    input  wire [COUNT_W-1:0] vote_dmk,
    input  wire [COUNT_W-1:0] vote_admk,
    input  wire [COUNT_W-1:0] vote_tvk,
    input  wire [COUNT_W-1:0] vote_ntk,
    input  wire [COUNT_W-1:0] vote_other,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);

// ------------------------------------------------------------------
// Blink counter (synchronous, with reset)
// ------------------------------------------------------------------
reg [23:0] blink_ctr;
wire blink_on = blink_ctr[23];

always @(posedge clk) begin
    if (rst) blink_ctr <= 24'd0;
    else     blink_ctr <= blink_ctr + 1'b1;
end

// ------------------------------------------------------------------
// 8x8 FONT ROM
// FIX: Added digit glyphs '0'-'9' - previously missing, caused blank count display
// ------------------------------------------------------------------
function [7:0] font8x8;
    input [7:0] ch;
    input [2:0] row;
    begin
        case (ch)
            // --- Digits ---
            "0": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h46;3:font8x8=8'h4A;4:font8x8=8'h52;5:font8x8=8'h62;6:font8x8=8'h3C;default:font8x8=0; endcase
            "1": case(row) 0:font8x8=8'h18;1:font8x8=8'h28;2:font8x8=8'h08;3:font8x8=8'h08;4:font8x8=8'h08;5:font8x8=8'h08;6:font8x8=8'h3E;default:font8x8=0; endcase
            "2": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h02;3:font8x8=8'h1C;4:font8x8=8'h20;5:font8x8=8'h40;6:font8x8=8'h7E;default:font8x8=0; endcase
            "3": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h02;3:font8x8=8'h1C;4:font8x8=8'h02;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "4": case(row) 0:font8x8=8'h08;1:font8x8=8'h18;2:font8x8=8'h28;3:font8x8=8'h48;4:font8x8=8'h7E;5:font8x8=8'h08;6:font8x8=8'h08;default:font8x8=0; endcase
            "5": case(row) 0:font8x8=8'h7E;1:font8x8=8'h40;2:font8x8=8'h40;3:font8x8=8'h7C;4:font8x8=8'h02;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "6": case(row) 0:font8x8=8'h1C;1:font8x8=8'h20;2:font8x8=8'h40;3:font8x8=8'h7C;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "7": case(row) 0:font8x8=8'h7E;1:font8x8=8'h02;2:font8x8=8'h04;3:font8x8=8'h08;4:font8x8=8'h10;5:font8x8=8'h10;6:font8x8=8'h10;default:font8x8=0; endcase
            "8": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h3C;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "9": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h3E;4:font8x8=8'h02;5:font8x8=8'h04;6:font8x8=8'h38;default:font8x8=0; endcase
            // --- Letters ---
            "A": case(row) 0:font8x8=8'h18;1:font8x8=8'h24;2:font8x8=8'h42;3:font8x8=8'h7E;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h42;default:font8x8=0; endcase
            "B": case(row) 0:font8x8=8'h7C;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h7C;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h7C;default:font8x8=0; endcase
            "C": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h40;3:font8x8=8'h40;4:font8x8=8'h40;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "D": case(row) 0:font8x8=8'h78;1:font8x8=8'h44;2:font8x8=8'h42;3:font8x8=8'h42;4:font8x8=8'h42;5:font8x8=8'h44;6:font8x8=8'h78;default:font8x8=0; endcase
            "E": case(row) 0:font8x8=8'h7E;1:font8x8=8'h40;2:font8x8=8'h40;3:font8x8=8'h7C;4:font8x8=8'h40;5:font8x8=8'h40;6:font8x8=8'h7E;default:font8x8=0; endcase
            "G": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h40;3:font8x8=8'h4E;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "H": case(row) 0:font8x8=8'h42;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h7E;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h42;default:font8x8=0; endcase
            "I": case(row) 0:font8x8=8'h3C;1:font8x8=8'h18;2:font8x8=8'h18;3:font8x8=8'h18;4:font8x8=8'h18;5:font8x8=8'h18;6:font8x8=8'h3C;default:font8x8=0; endcase
            "K": case(row) 0:font8x8=8'h42;1:font8x8=8'h44;2:font8x8=8'h48;3:font8x8=8'h70;4:font8x8=8'h48;5:font8x8=8'h44;6:font8x8=8'h42;default:font8x8=0; endcase
            "L": case(row) 0:font8x8=8'h40;1:font8x8=8'h40;2:font8x8=8'h40;3:font8x8=8'h40;4:font8x8=8'h40;5:font8x8=8'h40;6:font8x8=8'h7E;default:font8x8=0; endcase
            "M": case(row) 0:font8x8=8'h42;1:font8x8=8'h66;2:font8x8=8'h5A;3:font8x8=8'h42;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h42;default:font8x8=0; endcase
            "N": case(row) 0:font8x8=8'h42;1:font8x8=8'h62;2:font8x8=8'h52;3:font8x8=8'h4A;4:font8x8=8'h46;5:font8x8=8'h42;6:font8x8=8'h42;default:font8x8=0; endcase
            "O": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h42;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "P": case(row) 0:font8x8=8'h7C;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h7C;4:font8x8=8'h40;5:font8x8=8'h40;6:font8x8=8'h40;default:font8x8=0; endcase
            "R": case(row) 0:font8x8=8'h7C;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h7C;4:font8x8=8'h48;5:font8x8=8'h44;6:font8x8=8'h42;default:font8x8=0; endcase
            "S": case(row) 0:font8x8=8'h3C;1:font8x8=8'h42;2:font8x8=8'h40;3:font8x8=8'h3C;4:font8x8=8'h02;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "T": case(row) 0:font8x8=8'h7E;1:font8x8=8'h18;2:font8x8=8'h18;3:font8x8=8'h18;4:font8x8=8'h18;5:font8x8=8'h18;6:font8x8=8'h18;default:font8x8=0; endcase
            "U": case(row) 0:font8x8=8'h42;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h42;4:font8x8=8'h42;5:font8x8=8'h42;6:font8x8=8'h3C;default:font8x8=0; endcase
            "V": case(row) 0:font8x8=8'h42;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h42;4:font8x8=8'h24;5:font8x8=8'h24;6:font8x8=8'h18;default:font8x8=0; endcase
            "W": case(row) 0:font8x8=8'h42;1:font8x8=8'h42;2:font8x8=8'h42;3:font8x8=8'h5A;4:font8x8=8'h5A;5:font8x8=8'h66;6:font8x8=8'h42;default:font8x8=0; endcase
            "%": case(row) 0:font8x8=8'h62;1:font8x8=8'h64;2:font8x8=8'h08;3:font8x8=8'h10;4:font8x8=8'h26;5:font8x8=8'h46;6:font8x8=8'h00;default:font8x8=0; endcase
            ":": case(row) 0:font8x8=8'h00;1:font8x8=8'h18;2:font8x8=8'h18;3:font8x8=8'h00;4:font8x8=8'h18;5:font8x8=8'h18;6:font8x8=8'h00;default:font8x8=0; endcase
            default: font8x8 = 8'h00;
        endcase
    end
endfunction

// Draw a single character: returns 1 if pixel (px,py) is lit in glyph at (x0,y0)
function draw_char;
    input [9:0] px, py, x0, y0;
    input [7:0] ch;
    reg   [2:0] row, col;
    reg   [7:0] bits;
    begin
        if (px >= x0 && px < x0 + 10'd8 && py >= y0 && py < y0 + 10'd8) begin
            row      = py[2:0] - y0[2:0];
            col      = px[2:0] - x0[2:0];
            bits     = font8x8(ch, row);
            draw_char = bits[7 - col];
        end else begin
            draw_char = 1'b0;
        end
    end
endfunction

// Convert 4-bit digit index to ASCII character
function [7:0] digit_ascii;
    input [3:0] d;
    begin
        digit_ascii = 8'd48 + {4'h0, d};  // '0' = 48
    end
endfunction

// Convert byte value to 3-digit BCD {hundreds, tens, units}
function [11:0] to_bcd3;
    input [7:0] val;
    begin
        to_bcd3[11:8] = val / 8'd100;
        to_bcd3[7:4]  = (val % 8'd100) / 8'd10;
        to_bcd3[3:0]  = val % 8'd10;
    end
endfunction

// FIX: Widened to 16-bit intermediate to prevent 8-bit overflow in count*100
// e.g. 255*100 = 25500 - overflows 8 bits but fits in 16 bits
function [7:0] percent_val;
    input [7:0]          count;
    input [COUNT_W+2:0]  total;
    reg   [15:0]         wide_count;
    begin
        if (total == 0)
            percent_val = 8'd0;
        else begin
            wide_count  = {8'h00, count};          // zero-extend to 16 bits
            percent_val = (wide_count * 16'd100) / total;
        end
    end
endfunction

// Rectangle hit test
function in_rect;
    input [9:0] px, py, x0, y0, w, h;
    begin
        in_rect = (px >= x0) && (px < x0 + w) && (py >= y0) && (py < y0 + h);
    end
endfunction

// FIX: Bar width = min(510, count*2) per spec §4.4.2
// Left-shift by 1 achieves x2 without multiplier; cap at 510 pixels
function [9:0] bar_w;
    input [COUNT_W-1:0] cnt;
    reg   [9:0]         shifted;
    begin
        shifted = {1'b0, cnt, 1'b0};   // cnt * 2, 10-bit safe for 8-bit cnt
        bar_w   = (shifted > 10'd510) ? 10'd510 : shifted;
    end
endfunction

// Totals for percentage calculation
wire [COUNT_W+2:0] pred_total = pred_dmk + pred_admk + pred_tvk + pred_ntk + pred_other;
wire [COUNT_W+2:0] vote_total = vote_dmk + vote_admk + vote_tvk + vote_ntk + vote_other;

// ------------------------------------------------------------------
// Pixel colour combinational logic
// ------------------------------------------------------------------
always @(*) begin
    // Default: black when outside active region
    if (!active) begin
        r = 4'h0; g = 4'h0; b = 4'h0;

    end else begin
        // ---- Layer 0: White background ----
        r = 4'hF; g = 4'hF; b = 4'hF;

        // ---- Layer 1: Title/status band (mode-dependent colour) ----
        // FIX: colour changes with mode per spec Table 1
        if (in_rect(x, y, 10'd0, 10'd0, 10'd640, 10'd47)) begin
            case (mode)
                2'd0: begin r = 4'h1; g = 4'h1; b = 4'h3; end  // IDLE    - dark navy
                2'd1: begin r = 4'h0; g = 4'h2; b = 4'h7; end  // PREDICT - deep blue
                2'd2: begin r = 4'h0; g = 4'h5; b = 4'h3; end  // VOTE    - dark green
                2'd3: begin r = 4'h7; g = 4'h0; b = 4'h0; end  // RESULT  - dark maroon
            endcase
        end

        // ---- Layer 2: Dynamic mode label in header ----
        // FIX: removed static "RESULT" text that was always drawn and overlapped this
        case (mode)
            2'd0: begin  // IDLE
                if (draw_char(x,y,10'd250,10'd17,"I") || draw_char(x,y,10'd258,10'd17,"D") ||
                    draw_char(x,y,10'd266,10'd17,"L") || draw_char(x,y,10'd274,10'd17,"E"))
                    begin r = 4'hF; g = 4'hF; b = 4'hF; end
            end
            2'd1: begin  // PREDICT
                if (draw_char(x,y,10'd204,10'd17,"P") || draw_char(x,y,10'd212,10'd17,"R") ||
                    draw_char(x,y,10'd220,10'd17,"E") || draw_char(x,y,10'd228,10'd17,"D") ||
                    draw_char(x,y,10'd236,10'd17,"I") || draw_char(x,y,10'd244,10'd17,"C") ||
                    draw_char(x,y,10'd252,10'd17,"T"))
                    begin r = 4'hF; g = 4'hF; b = 4'hF; end
            end
            2'd2: begin  // VOTE
                if (draw_char(x,y,10'd220,10'd17,"V") || draw_char(x,y,10'd228,10'd17,"O") ||
                    draw_char(x,y,10'd236,10'd17,"T") || draw_char(x,y,10'd244,10'd17,"E"))
                    begin r = 4'hF; g = 4'hF; b = 4'hF; end
            end
            2'd3: begin  // RESULT
                if (draw_char(x,y,10'd208,10'd17,"R") || draw_char(x,y,10'd216,10'd17,"E") ||
                    draw_char(x,y,10'd224,10'd17,"S") || draw_char(x,y,10'd232,10'd17,"U") ||
                    draw_char(x,y,10'd240,10'd17,"L") || draw_char(x,y,10'd248,10'd17,"T"))
                    begin r = 4'hF; g = 4'hF; b = 4'hF; end
            end
        endcase

        // ---- Layer 3: Outer border ----
        if (x == 10'd10 || x == 10'd629 || y == 10'd10 || y == 10'd469)
            begin r = 4'h0; g = 4'h0; b = 4'h0; end

        // ---- Layer 4: Internal separators ----
        if (y == 10'd60 || y == 10'd240 || y == 10'd400)
            begin r = 4'h4; g = 4'h4; b = 4'h4; end

        if (x == 10'd160 || x == 10'd220 || x == 10'd290 || x == 10'd500)
            begin r = 4'hA; g = 4'hA; b = 4'hA; end

        // ---- Layer 5: Section box borders ----
        if (in_rect(x,y,10'd25,10'd65,10'd475,10'd160) &&
            (x==10'd25 || x==10'd499 || y==10'd65 || y==10'd224))
            begin r = 4'h0; g = 4'h0; b = 4'h0; end

        if (in_rect(x,y,10'd25,10'd245,10'd475,10'd160) &&
            (x==10'd25 || x==10'd499 || y==10'd245 || y==10'd404))
            begin r = 4'h0; g = 4'h0; b = 4'h0; end

        if (in_rect(x,y,10'd510,10'd175,10'd110,10'd130) &&
            (x==10'd510 || x==10'd619 || y==10'd175 || y==10'd304))
            begin r = 4'h0; g = 4'h0; b = 4'h0; end

        // ---- Layer 6: Winner row blink highlights ----
        // Prediction section - yellow highlight
        if (blink_on && pred_winner == 3'd0 && in_rect(x,y,10'd30,10'd83,10'd455,10'd22))
            begin r = 4'hF; g = 4'hF; b = 4'hC; end
        if (blink_on && pred_winner == 3'd1 && in_rect(x,y,10'd30,10'd108,10'd455,10'd22))
            begin r = 4'hF; g = 4'hF; b = 4'hC; end
        if (blink_on && pred_winner == 3'd2 && in_rect(x,y,10'd30,10'd133,10'd455,10'd22))
            begin r = 4'hF; g = 4'hF; b = 4'hC; end
        if (blink_on && pred_winner == 3'd3 && in_rect(x,y,10'd30,10'd158,10'd455,10'd22))
            begin r = 4'hF; g = 4'hF; b = 4'hC; end
        if (blink_on && pred_winner == 3'd4 && in_rect(x,y,10'd30,10'd183,10'd455,10'd22))
            begin r = 4'hF; g = 4'hF; b = 4'hC; end

        // Vote section - green highlight
        if (blink_on && vote_winner == 3'd0 && in_rect(x,y,10'd30,10'd263,10'd455,10'd22))
            begin r = 4'hC; g = 4'hF; b = 4'hC; end
        if (blink_on && vote_winner == 3'd1 && in_rect(x,y,10'd30,10'd288,10'd455,10'd22))
            begin r = 4'hC; g = 4'hF; b = 4'hC; end
        if (blink_on && vote_winner == 3'd2 && in_rect(x,y,10'd30,10'd313,10'd455,10'd22))
            begin r = 4'hC; g = 4'hF; b = 4'hC; end
        if (blink_on && vote_winner == 3'd3 && in_rect(x,y,10'd30,10'd338,10'd455,10'd22))
            begin r = 4'hC; g = 4'hF; b = 4'hC; end
        if (blink_on && vote_winner == 3'd4 && in_rect(x,y,10'd30,10'd363,10'd455,10'd22))
            begin r = 4'hC; g = 4'hF; b = 4'hC; end

        // ---- Layer 7: Party colour label blocks ----
        // Prediction section (spec Table 2 label block colours)
        if (in_rect(x,y,10'd30,10'd85,10'd60,10'd18))  begin r=4'hF;g=4'h4;b=4'h4; end // DMK
        if (in_rect(x,y,10'd30,10'd110,10'd60,10'd18)) begin r=4'h3;g=4'hB;b=4'h3; end // ADMK
        if (in_rect(x,y,10'd30,10'd135,10'd60,10'd18)) begin r=4'hF;g=4'hB;b=4'h0; end // TVK
        if (in_rect(x,y,10'd30,10'd160,10'd60,10'd18)) begin r=4'h9;g=4'h1;b=4'h1; end // NTK
        if (in_rect(x,y,10'd30,10'd185,10'd60,10'd18)) begin r=4'h7;g=4'h7;b=4'h7; end // Other

        // Vote section
        if (in_rect(x,y,10'd30,10'd265,10'd60,10'd18)) begin r=4'hF;g=4'h4;b=4'h4; end
        if (in_rect(x,y,10'd30,10'd290,10'd60,10'd18)) begin r=4'h3;g=4'hB;b=4'h3; end
        if (in_rect(x,y,10'd30,10'd315,10'd60,10'd18)) begin r=4'hF;g=4'hB;b=4'h0; end
        if (in_rect(x,y,10'd30,10'd340,10'd60,10'd18)) begin r=4'h9;g=4'h1;b=4'h1; end
        if (in_rect(x,y,10'd30,10'd365,10'd60,10'd18)) begin r=4'h7;g=4'h7;b=4'h7; end

        // ---- Layer 8: Party name text labels ----
        // Prediction section
        if (draw_char(x,y,10'd95,10'd88,"D")||draw_char(x,y,10'd103,10'd88,"M")||draw_char(x,y,10'd111,10'd88,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd113,"A")||draw_char(x,y,10'd103,10'd113,"D")||draw_char(x,y,10'd111,10'd113,"M")||draw_char(x,y,10'd119,10'd113,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd138,"T")||draw_char(x,y,10'd103,10'd138,"V")||draw_char(x,y,10'd111,10'd138,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd163,"N")||draw_char(x,y,10'd103,10'd163,"T")||draw_char(x,y,10'd111,10'd163,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd188,"O")||draw_char(x,y,10'd103,10'd188,"T")||draw_char(x,y,10'd111,10'd188,"H")||draw_char(x,y,10'd119,10'd188,"E")||draw_char(x,y,10'd127,10'd188,"R"))
            begin r=4'h0;g=4'h0;b=4'h0; end

        // Vote section
        if (draw_char(x,y,10'd95,10'd268,"D")||draw_char(x,y,10'd103,10'd268,"M")||draw_char(x,y,10'd111,10'd268,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd293,"A")||draw_char(x,y,10'd103,10'd293,"D")||draw_char(x,y,10'd111,10'd293,"M")||draw_char(x,y,10'd119,10'd293,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd318,"T")||draw_char(x,y,10'd103,10'd318,"V")||draw_char(x,y,10'd111,10'd318,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd343,"N")||draw_char(x,y,10'd103,10'd343,"T")||draw_char(x,y,10'd111,10'd343,"K"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd368,"O")||draw_char(x,y,10'd103,10'd368,"T")||draw_char(x,y,10'd111,10'd368,"H")||draw_char(x,y,10'd119,10'd368,"E")||draw_char(x,y,10'd127,10'd368,"R"))
            begin r=4'h0;g=4'h0;b=4'h0; end

        // ---- Layer 9: Column headers ----
        // Prediction headers: CNT / PCT / BAR
        if (draw_char(x,y,10'd165,10'd70,"C")||draw_char(x,y,10'd173,10'd70,"N")||draw_char(x,y,10'd181,10'd70,"T"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd228,10'd70,"P")||draw_char(x,y,10'd236,10'd70,"C")||draw_char(x,y,10'd244,10'd70,"T"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd350,10'd70,"B")||draw_char(x,y,10'd358,10'd70,"A")||draw_char(x,y,10'd366,10'd70,"R"))
            begin r=4'h0;g=4'h0;b=4'h0; end

        // Vote section headers
        if (draw_char(x,y,10'd165,10'd250,"C")||draw_char(x,y,10'd173,10'd250,"N")||draw_char(x,y,10'd181,10'd250,"T"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd228,10'd250,"P")||draw_char(x,y,10'd236,10'd250,"C")||draw_char(x,y,10'd244,10'd250,"T"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd350,10'd250,"B")||draw_char(x,y,10'd358,10'd250,"A")||draw_char(x,y,10'd366,10'd250,"R"))
            begin r=4'h0;g=4'h0;b=4'h0; end

        // Section labels: PRED / ACT
        if (draw_char(x,y,10'd35,10'd70,"P")||draw_char(x,y,10'd43,10'd70,"R")||draw_char(x,y,10'd51,10'd70,"E")||draw_char(x,y,10'd59,10'd70,"D"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd35,10'd250,"A")||draw_char(x,y,10'd43,10'd250,"C")||draw_char(x,y,10'd51,10'd250,"T"))
            begin r=4'h0;g=4'h0;b=4'h0; end

        // ---- Layer 10: Prediction bars (spec Table 2 prediction bar colours) ----
        if (in_rect(x,y,10'd300,10'd88,  bar_w(pred_dmk),  10'd14)) begin r=4'hF;g=4'h4;b=4'h4; end
        if (in_rect(x,y,10'd300,10'd111, bar_w(pred_admk), 10'd14)) begin r=4'h3;g=4'hB;b=4'h3; end
        if (in_rect(x,y,10'd300,10'd135, bar_w(pred_tvk),  10'd14)) begin r=4'hF;g=4'hB;b=4'h0; end
        if (in_rect(x,y,10'd300,10'd160, bar_w(pred_ntk),  10'd14)) begin r=4'h9;g=4'h1;b=4'h1; end
        if (in_rect(x,y,10'd300,10'd185, bar_w(pred_other),10'd14)) begin r=4'h7;g=4'h7;b=4'h7; end

        // ---- Layer 11: Vote bars (spec Table 2 vote bar colours) ----
        if (in_rect(x,y,10'd300,10'd268, bar_w(vote_dmk),  10'd14)) begin r=4'hD;g=4'h0;b=4'h0; end
        if (in_rect(x,y,10'd300,10'd291, bar_w(vote_admk), 10'd14)) begin r=4'h0;g=4'h8;b=4'h0; end
        if (in_rect(x,y,10'd300,10'd315, bar_w(vote_tvk),  10'd14)) begin r=4'hD;g=4'h8;b=4'h0; end
        if (in_rect(x,y,10'd300,10'd340, bar_w(vote_ntk),  10'd14)) begin r=4'h7;g=4'h0;b=4'h0; end
        if (in_rect(x,y,10'd300,10'd365, bar_w(vote_other),10'd14)) begin r=4'h4;g=4'h4;b=4'h4; end

        // ---- Layer 12: Count values (3 digits each) ----
        begin : COUNT_RENDER
            reg [11:0] bcd;

            bcd = to_bcd3(pred_dmk);
            if (draw_char(x,y,10'd163,10'd88,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd88,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd88,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(pred_admk);
            if (draw_char(x,y,10'd163,10'd113,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd113,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd113,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(pred_tvk);
            if (draw_char(x,y,10'd163,10'd138,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd138,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd138,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(pred_ntk);
            if (draw_char(x,y,10'd163,10'd163,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd163,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd163,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(pred_other);
            if (draw_char(x,y,10'd163,10'd188,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd188,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd188,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end

            bcd = to_bcd3(vote_dmk);
            if (draw_char(x,y,10'd163,10'd268,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd268,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd268,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(vote_admk);
            if (draw_char(x,y,10'd163,10'd293,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd293,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd293,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(vote_tvk);
            if (draw_char(x,y,10'd163,10'd318,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd318,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd318,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(vote_ntk);
            if (draw_char(x,y,10'd163,10'd343,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd343,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd343,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            bcd = to_bcd3(vote_other);
            if (draw_char(x,y,10'd163,10'd368,digit_ascii(bcd[11:8]))||draw_char(x,y,10'd171,10'd368,digit_ascii(bcd[7:4]))||draw_char(x,y,10'd179,10'd368,digit_ascii(bcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
        end

        // ---- Layer 13: Percentage values (2 digits + %) ----
        begin : PCT_RENDER
            reg [7:0]  pct;
            reg [11:0] pbcd;

            pct = percent_val(pred_dmk,   pred_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd88,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd88,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd88,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(pred_admk,  pred_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd113,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd113,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd113,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(pred_tvk,   pred_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd138,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd138,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd138,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(pred_ntk,   pred_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd163,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd163,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd163,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(pred_other, pred_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd188,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd188,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd188,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end

            pct = percent_val(vote_dmk,   vote_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd268,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd268,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd268,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(vote_admk,  vote_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd293,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd293,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd293,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(vote_tvk,   vote_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd318,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd318,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd318,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(vote_ntk,   vote_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd343,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd343,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd343,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
            pct = percent_val(vote_other, vote_total); pbcd = to_bcd3(pct);
            if (draw_char(x,y,10'd228,10'd368,digit_ascii(pbcd[7:4]))||draw_char(x,y,10'd236,10'd368,digit_ascii(pbcd[3:0]))||draw_char(x,y,10'd244,10'd368,"%"))
                begin r=4'h0;g=4'h0;b=4'h0; end
        end

        // ---- Layer 14: Winner summary panel ----
        // Background for winner panel
        if (in_rect(x,y,10'd510,10'd175,10'd110,10'd130)) begin
            r = 4'hF; g = 4'hF; b = 4'hF;
        end

        // Labels: RESULT / PRED / ACTUAL
        if (draw_char(x,y,10'd515,10'd180,"R")||draw_char(x,y,10'd523,10'd180,"E")||draw_char(x,y,10'd531,10'd180,"S")||draw_char(x,y,10'd539,10'd180,"U")||draw_char(x,y,10'd547,10'd180,"L")||draw_char(x,y,10'd555,10'd180,"T"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd515,10'd200,"P")||draw_char(x,y,10'd523,10'd200,"R")||draw_char(x,y,10'd531,10'd200,"E")||draw_char(x,y,10'd539,10'd200,"D"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd515,10'd240,"A")||draw_char(x,y,10'd523,10'd240,"C")||draw_char(x,y,10'd531,10'd240,"T"))
            begin r=4'h0;g=4'h0;b=4'h0; end

        // Predicted winner party name badge
        if (in_rect(x,y,10'd555,10'd197,10'd55,10'd18)) begin
            case (pred_winner)
                3'd0: begin r=4'hF;g=4'h4;b=4'h4; end
                3'd1: begin r=4'h3;g=4'hB;b=4'h3; end
                3'd2: begin r=4'hF;g=4'hB;b=4'h0; end
                3'd3: begin r=4'h9;g=4'h1;b=4'h1; end
                3'd4: begin r=4'h7;g=4'h7;b=4'h7; end
                default: begin r=4'hF;g=4'hF;b=4'hF; end
            endcase
        end

        // Actual winner party name badge
        if (in_rect(x,y,10'd555,10'd237,10'd55,10'd18)) begin
            case (vote_winner)
                3'd0: begin r=4'hD;g=4'h0;b=4'h0; end
                3'd1: begin r=4'h0;g=4'h8;b=4'h0; end
                3'd2: begin r=4'hD;g=4'h8;b=4'h0; end
                3'd3: begin r=4'h7;g=4'h0;b=4'h0; end
                3'd4: begin r=4'h4;g=4'h4;b=4'h4; end
                default: begin r=4'hF;g=4'hF;b=4'hF; end
            endcase
        end

        // Party name text on badges (PRED)
        case (pred_winner)
            3'd0: if(draw_char(x,y,10'd557,10'd200,"D")||draw_char(x,y,10'd565,10'd200,"M")||draw_char(x,y,10'd573,10'd200,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd1: if(draw_char(x,y,10'd555,10'd200,"A")||draw_char(x,y,10'd563,10'd200,"D")||draw_char(x,y,10'd571,10'd200,"M")||draw_char(x,y,10'd579,10'd200,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd2: if(draw_char(x,y,10'd557,10'd200,"T")||draw_char(x,y,10'd565,10'd200,"V")||draw_char(x,y,10'd573,10'd200,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd3: if(draw_char(x,y,10'd557,10'd200,"N")||draw_char(x,y,10'd565,10'd200,"T")||draw_char(x,y,10'd573,10'd200,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd4: if(draw_char(x,y,10'd555,10'd200,"O")||draw_char(x,y,10'd563,10'd200,"T")||draw_char(x,y,10'd571,10'd200,"H")||draw_char(x,y,10'd579,10'd200,"E")||draw_char(x,y,10'd587,10'd200,"R")) begin r=4'h0;g=4'h0;b=4'h0; end
            default:;
        endcase

        // Party name text on badges (ACT)
        case (vote_winner)
            3'd0: if(draw_char(x,y,10'd557,10'd240,"D")||draw_char(x,y,10'd565,10'd240,"M")||draw_char(x,y,10'd573,10'd240,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd1: if(draw_char(x,y,10'd555,10'd240,"A")||draw_char(x,y,10'd563,10'd240,"D")||draw_char(x,y,10'd571,10'd240,"M")||draw_char(x,y,10'd579,10'd240,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd2: if(draw_char(x,y,10'd557,10'd240,"T")||draw_char(x,y,10'd565,10'd240,"V")||draw_char(x,y,10'd573,10'd240,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd3: if(draw_char(x,y,10'd557,10'd240,"N")||draw_char(x,y,10'd565,10'd240,"T")||draw_char(x,y,10'd573,10'd240,"K")) begin r=4'h0;g=4'h0;b=4'h0; end
            3'd4: if(draw_char(x,y,10'd555,10'd240,"O")||draw_char(x,y,10'd563,10'd240,"T")||draw_char(x,y,10'd571,10'd240,"H")||draw_char(x,y,10'd579,10'd240,"E")||draw_char(x,y,10'd587,10'd240,"R")) begin r=4'h0;g=4'h0;b=4'h0; end
            default:;
        endcase

        // ---- Layer 15: MATCH/WRONG result box ----
        if (in_rect(x,y,10'd515,10'd260,10'd95,10'd30)) begin
            if (pred_winner == vote_winner) begin
                // MATCH - green box
                r = 4'h0; g = 4'hA; b = 4'h0;
                if (draw_char(x,y,10'd518,10'd268,"M")||draw_char(x,y,10'd526,10'd268,"A")||draw_char(x,y,10'd534,10'd268,"T")||draw_char(x,y,10'd542,10'd268,"C")||draw_char(x,y,10'd550,10'd268,"H"))
                    begin r=4'hF;g=4'hF;b=4'hF; end
            end else begin
                // WRONG - red box
                r = 4'hA; g = 4'h0; b = 4'h0;
                if (draw_char(x,y,10'd518,10'd268,"W")||draw_char(x,y,10'd526,10'd268,"R")||draw_char(x,y,10'd534,10'd268,"O")||draw_char(x,y,10'd542,10'd268,"N")||draw_char(x,y,10'd550,10'd268,"G"))
                    begin r=4'hF;g=4'hF;b=4'hF; end
            end
        end

        // ---- Layer 16: TOTAL row ----
        if (draw_char(x,y,10'd95,10'd210,"T")||draw_char(x,y,10'd103,10'd210,"O")||draw_char(x,y,10'd111,10'd210,"T")||draw_char(x,y,10'd119,10'd210,"A")||draw_char(x,y,10'd127,10'd210,"L"))
            begin r=4'h0;g=4'h0;b=4'h0; end
        if (draw_char(x,y,10'd95,10'd390,"T")||draw_char(x,y,10'd103,10'd390,"O")||draw_char(x,y,10'd111,10'd390,"T")||draw_char(x,y,10'd119,10'd390,"A")||draw_char(x,y,10'd127,10'd390,"L"))
            begin r=4'h0;g=4'h0;b=4'h0; end

        begin : TOTAL_RENDER
            reg [11:0] tbcd;
            // Prediction total
            tbcd = to_bcd3(pred_total[7:0]);
            if (draw_char(x,y,10'd163,10'd210,digit_ascii(tbcd[11:8]))||draw_char(x,y,10'd171,10'd210,digit_ascii(tbcd[7:4]))||draw_char(x,y,10'd179,10'd210,digit_ascii(tbcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
            // Vote total
            tbcd = to_bcd3(vote_total[7:0]);
            if (draw_char(x,y,10'd163,10'd390,digit_ascii(tbcd[11:8]))||draw_char(x,y,10'd171,10'd390,digit_ascii(tbcd[7:4]))||draw_char(x,y,10'd179,10'd390,digit_ascii(tbcd[3:0])))
                begin r=4'h0;g=4'h0;b=4'h0; end
        end

    end // active
end // always

endmodule
