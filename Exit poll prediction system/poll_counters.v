module poll_counters #(
    parameter COUNT_W = 8
)(
    input wire clk,
    input wire rst,

    input wire [1:0] mode,
    //input wire [4:0] party_pulse,
    
    input pred_dmk_pulse,
    input pred_admk_pulse,
    input pred_tvk_pulse,
    input pred_ntk_pulse,
    input pred_other_pulse,
    
    input vote_dmk_pulse,
    input vote_admk_pulse,
    input vote_tvk_pulse,
    input vote_ntk_pulse,
    input vote_other_pulse,    

    output reg [COUNT_W-1:0] pred_dmk,
    output reg [COUNT_W-1:0] pred_admk,
    output reg [COUNT_W-1:0] pred_tvk,
    output reg [COUNT_W-1:0] pred_ntk,
    output reg [COUNT_W-1:0] pred_other,

    output reg [COUNT_W-1:0] vote_dmk,
    output reg [COUNT_W-1:0] vote_admk,
    output reg [COUNT_W-1:0] vote_tvk,
    output reg [COUNT_W-1:0] vote_ntk,
    output reg [COUNT_W-1:0] vote_other
);

localparam IDLE    = 2'd0;
localparam PREDICT = 2'd1;
localparam VOTE    = 2'd2;
localparam RESULT  = 2'd3;

always @(posedge clk) begin
    if (rst) begin
        pred_dmk   <= 0;
        pred_admk  <= 0;
        pred_tvk   <= 0;
        pred_ntk   <= 0;
        pred_other <= 0;

        vote_dmk   <= 0;
        vote_admk  <= 0;
        vote_tvk   <= 0;
        vote_ntk   <= 0;
        vote_other <= 0;
    end
    else begin
        case (mode)

            PREDICT: begin
                if (pred_dmk_pulse)   pred_dmk   <= pred_dmk + 1;
                if (pred_admk_pulse)  pred_admk  <= pred_admk + 1;
                if (pred_tvk_pulse)   pred_tvk   <= pred_tvk + 1;
                if (pred_ntk_pulse)   pred_ntk   <= pred_ntk + 1;
                if (pred_other_pulse) pred_other <= pred_other + 1;
            end

            VOTE: begin
                if (vote_dmk_pulse)   vote_dmk   <= vote_dmk + 1;
                if (vote_admk_pulse)  vote_admk  <= vote_admk + 1;
                if (vote_tvk_pulse)   vote_tvk   <= vote_tvk + 1;
                if (vote_ntk_pulse)   vote_ntk   <= vote_ntk + 1;
                if (vote_other_pulse) vote_other <= vote_other + 1;
            end

            default: begin
                // IDLE / RESULT -> Hold counts
            end

        endcase
    end
end

endmodule
