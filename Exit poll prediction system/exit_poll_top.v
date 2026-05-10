module exit_poll_top (
    input  wire        clk,          // 50 MHz on-board oscillator (pin N11)

    // Buttons (active-HIGH, on-board PULLDOWN)
    input  wire        rst_btn,      // pb[0] K13 - synchronous reset
    input  wire        next_btn,     // pb[1] L14 - advance phase
  
    input wire btn_dmk,
    input wire btn_admk,
    input wire btn_tvk,
    input wire btn_ntk,
    input wire btn_other,    

    // VGA output (12-bit colour, 4R+4G+4B)
    output wire        hsync,
    output wire        vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,

    // 4-digit 7-segment display
    output wire [3:0]  seg_an,       // anode enables, active-LOW
    output wire [7:0]  seg_cat,      // {dp,g,f,e,d,c,b,a}, active-LOW

    // LEDs (active-HIGH)
    output wire [15:0] led,

    // UART TX (to USB-UART bridge, pin C4)
    output wire        uart_tx_out
);
    wire dmk_pulse, admk_pulse, tvk_pulse, ntk_pulse, other_pulse;
  
    wire next_clean, next_pulse;


    // ----------------------------------------------------------------
    // Synchronous reset - debounce the reset button
    // ----------------------------------------------------------------
    wire rst_clean;
    wire rst = rst_clean;   // active-HIGH synchronous reset
    debounce db_rst (
        .clk(clk), .rst(1'b0), .noisy(rst_btn), .clean(rst_clean)
    );

    // ----------------------------------------------------------------
    // FIX: Pixel clock enable - toggle every cycle = effective 25 MHz
    // No separate clock domain; vga_sync uses pix_ce on 50 MHz clock
    // ----------------------------------------------------------------
    reg pix_phase;
    always @(posedge clk) begin
        if (rst) pix_phase <= 1'b0;
        else     pix_phase <= ~pix_phase;
    end
    wire pix_ce = pix_phase;

    // ----------------------------------------------------------------
    // Debounce + edge-detect all buttons
    // ----------------------------------------------------------------
      
    // DMK
    wire dmk_clean;
    debounce db_dmk (.clk(clk), .rst(1'b0), .noisy(btn_dmk), .clean(dmk_clean));
    edge_detect ed_dmk (.clk(clk), .rst(rst), .sig(dmk_clean), .rise_pulse(dmk_pulse));
    
    // ADMK
    wire admk_clean;
    debounce db_admk (.clk(clk), .rst(1'b0), .noisy(btn_admk), .clean(admk_clean));
    edge_detect ed_admk (.clk(clk), .rst(rst), .sig(admk_clean), .rise_pulse(admk_pulse));
    
    // TVK
    wire tvk_clean;
    debounce db_tvk (.clk(clk), .rst(1'b0), .noisy(btn_tvk), .clean(tvk_clean));
    edge_detect ed_tvk (.clk(clk), .rst(rst), .sig(tvk_clean), .rise_pulse(tvk_pulse));
    
    // NTK
    wire ntk_clean;
    debounce db_ntk (.clk(clk), .rst(1'b0), .noisy(btn_ntk), .clean(ntk_clean));
    edge_detect ed_ntk (.clk(clk), .rst(rst), .sig(ntk_clean), .rise_pulse(ntk_pulse));
    
    // OTHER
    wire other_clean;
    debounce db_other (.clk(clk), .rst(1'b0), .noisy(btn_other), .clean(other_clean));
    edge_detect ed_other (.clk(clk), .rst(rst), .sig(other_clean), .rise_pulse(other_pulse));
  
    debounce db_next (.clk(clk), .rst(1'b0), .noisy(next_btn), .clean(next_clean));
    edge_detect ed_next (.clk(clk), .rst(rst), .sig(next_clean), .rise_pulse(next_pulse));

    // ----------------------------------------------------------------
    // FSM - mode state machine
    // ----------------------------------------------------------------
    wire [1:0] mode;

    exit_poll_fsm fsm (
        .clk        (clk),
        .rst        (rst),
        .next_pulse (next_pulse),
        .mode       (mode)
    );

    // ----------------------------------------------------------------
    // Generate predict_pulse and vote_pulse from action_pulse + mode
    // Mode gating done here in top so poll_counters stays generic
    // ----------------------------------------------------------------
    wire pred_dmk_pulse   = dmk_pulse   && (mode == 2'd1);
    wire pred_admk_pulse  = admk_pulse  && (mode == 2'd1);
    wire pred_tvk_pulse   = tvk_pulse   && (mode == 2'd1);
    wire pred_ntk_pulse   = ntk_pulse   && (mode == 2'd1);
    wire pred_other_pulse = other_pulse && (mode == 2'd1);
    
    wire vote_dmk_pulse   = dmk_pulse   && (mode == 2'd2);
    wire vote_admk_pulse  = admk_pulse  && (mode == 2'd2);
    wire vote_tvk_pulse   = tvk_pulse   && (mode == 2'd2);
    wire vote_ntk_pulse   = ntk_pulse   && (mode == 2'd2);
    wire vote_other_pulse = other_pulse && (mode == 2'd2);    
    // ----------------------------------------------------------------
    wire [7:0] pred_dmk, pred_admk, pred_tvk, pred_ntk, pred_other;
    wire [7:0] vote_dmk, vote_admk, vote_tvk, vote_ntk, vote_other;

    poll_counters #(.COUNT_W(8)) counters (
        .clk           (clk),
        .rst           (rst),
        .mode            (mode),
        .pred_dmk_pulse  (pred_dmk_pulse),
        .pred_admk_pulse (pred_admk_pulse),
        .pred_tvk_pulse  (pred_tvk_pulse),
        .pred_ntk_pulse  (pred_ntk_pulse),
        .pred_other_pulse(pred_other_pulse),
        .vote_dmk_pulse  (vote_dmk_pulse),
        .vote_admk_pulse (vote_admk_pulse),
        .vote_tvk_pulse  (vote_tvk_pulse),
        .vote_ntk_pulse  (vote_ntk_pulse),
        .vote_other_pulse(vote_other_pulse),
        .pred_dmk        (pred_dmk),
        .pred_admk       (pred_admk),
        .pred_tvk        (pred_tvk),
        .pred_ntk        (pred_ntk),
        .pred_other      (pred_other),
        .vote_dmk        (vote_dmk),
        .vote_admk       (vote_admk),
        .vote_tvk        (vote_tvk),
        .vote_ntk        (vote_ntk),
        .vote_other      (vote_other)
    );

    // ----------------------------------------------------------------
    // Winner logic - two instances (pred + vote)
    // FIX: module name is winner_logic (was mismatched as winner_detect)
    // ----------------------------------------------------------------
    wire [2:0] pred_winner, vote_winner;
    wire [7:0] pred_max,    vote_max;

    winner_logic #(.COUNT_W(8)) pred_win (
        .c0        (pred_dmk),
        .c1        (pred_admk),
        .c2        (pred_tvk),
        .c3        (pred_ntk),
        .c4        (pred_other),
        .winner    (pred_winner),
        .max_count (pred_max)
    );

    winner_logic #(.COUNT_W(8)) vote_win (
        .c0        (vote_dmk),
        .c1        (vote_admk),
        .c2        (vote_tvk),
        .c3        (vote_ntk),
        .c4        (vote_other),
        .winner    (vote_winner),
        .max_count (vote_max)
    );

    // ----------------------------------------------------------------
    // VGA sync timing generator
    // ----------------------------------------------------------------
    wire [9:0] px, py;
    wire       active;

    vga_sync_640x480 vga_sync (
        .clk    (clk),
        .pix_ce (pix_ce),        // FIX: clock-enable, not separate clock
        .rst    (rst),
        .x      (px),
        .y      (py),
        .hsync  (hsync),
        .vsync  (vsync),
        .active (active)
    );

    // ----------------------------------------------------------------
    // VGA pixel renderer
    // ----------------------------------------------------------------
    poll_renderer_advanced #(.COUNT_W(8)) renderer (
        .clk        (clk),
        .rst        (rst),
        .x          (px),
        .y          (py),
        .active     (active),
        .mode       (mode),
        .pred_winner(pred_winner),
        .vote_winner(vote_winner),
        .pred_dmk   (pred_dmk),
        .pred_admk  (pred_admk),
        .pred_tvk   (pred_tvk),
        .pred_ntk   (pred_ntk),
        .pred_other (pred_other),
        .vote_dmk   (vote_dmk),
        .vote_admk  (vote_admk),
        .vote_tvk   (vote_tvk),
        .vote_ntk   (vote_ntk),
        .vote_other (vote_other),
        .r          (vga_r),
        .g          (vga_g),
        .b          (vga_b)
    );

    // ----------------------------------------------------------------
    // 7-segment display controller
    // ----------------------------------------------------------------
    seg7_controller #(.CLK_HZ(50_000_000)) seg7 (
        .clk        (clk),
        .rst        (rst),
        .mode       (mode),
        .pred_winner(pred_winner),
        .vote_winner(vote_winner),
        .pred_max   (pred_max),
        .vote_max   (vote_max),
        .an         (seg_an),
        .seg        (seg_cat)
    );

    // ----------------------------------------------------------------
    // UART transmitter + reporter
    // ----------------------------------------------------------------
    wire uart_tx_valid;
    wire [7:0] uart_tx_data;
    wire uart_tx_busy;

    uart_tx #(
        .CLK_HZ(50_000_000),
        .BAUD  (115200)
    ) u_uart_tx (
        .clk   (clk),
        .rst   (rst),
        .valid (uart_tx_valid),
        .data  (uart_tx_data),
        .tx    (uart_tx_out),
        .busy  (uart_tx_busy)
    );

    // Trigger UART report when entering RESULT mode (rising edge of mode==RESULT)
    wire result_mode = (mode == 2'd3);
    wire result_mode_d;
    reg  result_mode_r;
    always @(posedge clk) begin
        if (rst) result_mode_r <= 1'b0;
        else     result_mode_r <= result_mode;
    end
    wire uart_trigger = result_mode & ~result_mode_r;  // rising edge of RESULT

    uart_reporter reporter (
        .clk        (clk),
        .rst        (rst),
        .trigger    (uart_trigger),
        .pred_winner(pred_winner),
        .vote_winner(vote_winner),
        .tx_valid   (uart_tx_valid),
        .tx_data    (uart_tx_data),
        .tx_busy    (uart_tx_busy)
    );

    // ----------------------------------------------------------------
    // FIX: LED outputs per spec §6.2
    // led[4:0]   - currently selected party (one-hot from party_sel switches)
    // led[9:5]   - predicted winner (one-hot)
    // led[14:10] - actual vote winner (one-hot)
    // led[15]    - prediction correct (RESULT mode only)
    // ----------------------------------------------------------------

    // Party select one-hot (from 3-bit switch)
    reg [4:0] party_onehot;
    always @(posedge clk) begin
        if (rst)
            party_onehot <= 5'b00000;
        else begin
            if (dmk_pulse)       party_onehot <= 5'b00001;
            else if (admk_pulse) party_onehot <= 5'b00010;
            else if (tvk_pulse)  party_onehot <= 5'b00100;
            else if (ntk_pulse)  party_onehot <= 5'b01000;
            else if (other_pulse)party_onehot <= 5'b10000;
        end
    end

    // Winner one-hot encoder
    function [4:0] winner_onehot;
        input [2:0] w;
        begin
            case (w)
                3'd0: winner_onehot = 5'b00001;
                3'd1: winner_onehot = 5'b00010;
                3'd2: winner_onehot = 5'b00100;
                3'd3: winner_onehot = 5'b01000;
                3'd4: winner_onehot = 5'b10000;
                default: winner_onehot = 5'b00000;
            endcase
        end
    endfunction

    assign led[4:0]   = party_onehot;
    assign led[9:5]   = winner_onehot(pred_winner);
    assign led[14:10] = winner_onehot(vote_winner);
    assign led[15]    = (mode == 2'd3) ? (pred_winner == vote_winner) : 1'b0;

endmodule
