// exit_poll_fsm.v - Mode state machine
// Four states: IDLE(0) -> PREDICT(1) -> VOTE(2) -> RESULT(3) -> PREDICT ...
// rst always returns to IDLE; rst takes priority over next_pulse
module exit_poll_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       next_pulse,  // single-cycle pulse to advance state
    output reg  [1:0] mode
);
    localparam IDLE    = 2'd0;
    localparam PREDICT = 2'd1;
    localparam VOTE    = 2'd2;
    localparam RESULT  = 2'd3;

    always @(posedge clk) begin
        if (rst) begin
            mode <= IDLE;          // synchronous reset, highest priority
        end else if (next_pulse) begin
            case (mode)
                IDLE   : mode <= PREDICT;
                PREDICT: mode <= VOTE;
                VOTE   : mode <= RESULT;
                RESULT : mode <= PREDICT;  // new round without full reset
                default: mode <= IDLE;
            endcase
        end
        // hold mode when no pulse
    end
endmodule
