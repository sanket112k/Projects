//`include "clock_top.v"
module fpga_clock(
    input clk,
    input reset,
    output reg [3:0] anode,
    output reg [7:0] cathode,
    output sled
);

wire [7:0] hh;
wire [7:0] mm;
wire [7:0] ss;
wire pm;

clock_top(
    .clk(clk),
    .reset(reset),
    .hh(hh),
    .mm(mm),
    .ss(ss),
    .pm(pm)
);

reg [$clog2(25000)-1:0] count;
reg [1:0] count_1khz;
reg [3:0] digit;

assign sled = ss[0];    // blink led for 1s

always @(posedge clk or posedge reset)begin
    if (reset) begin
        count <= 0;
        count_1khz <= 0;
    end else begin
        if(count == 25000 - 1)begin
            count <= 0;
            count_1khz <= count_1khz + 1;
        end
        else count <= count + 1;
    end
end

always @(*)begin    // seven segment multiplexing logic
    case(count_1khz)
        2'd0: begin digit = mm[3:0]; anode = 4'b1000; end
        2'd1: begin digit = mm[7:4]; anode = 4'b0100; end
        2'd2: begin digit = hh[3:0]; anode = 4'b0010; end
        2'd3: begin digit = hh[7:4]; anode = 4'b0001; end
    endcase
end

always @(*)begin    // seven segment decoder
    case(digit)
        4'd0: cathode = 8'b11000000;
        4'd1: cathode = 8'b11111001;
        4'd2: cathode = 8'b10100100;
        4'd3: cathode = 8'b10110000;
        4'd4: cathode = 8'b10011001;
        4'd5: cathode = 8'b10010010;
        4'd6: cathode = 8'b10000010;
        4'd7: cathode = 8'b11111000;
        4'd8: cathode = 8'b10000000;
        4'd9: cathode = 8'b10010000;
    endcase
end
endmodule
