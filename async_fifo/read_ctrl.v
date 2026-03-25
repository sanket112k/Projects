// Read pointer & empty generation logic
module read_ctrl #(
    parameter ADDR_WIDTH = 4
)(
    input rclk,
    input rreset,
    input ren,
    input      [ADDR_WIDTH:0]   wptr_sync,

    output     [ADDR_WIDTH-1:0] raddr,
    output reg [ADDR_WIDTH:0]   rptr_gray,
    output reg empty,
    output reg rvalid
);
reg [ADDR_WIDTH:0] rptr_bin;
reg [ADDR_WIDTH:0] rgnext;
reg [ADDR_WIDTH:0] rbnext;
reg ren_d;

always @(posedge rclk) begin:next_transition
    if (rreset) begin
        rptr_bin  <= 0;
        rptr_gray <= 0;
    end
    else begin
        rptr_bin  <= rbnext;
        rptr_gray <= rgnext;
    end
end

always @(*) begin:ptr_inc_logic
    rbnext = rptr_bin + (ren & ~empty);
    rgnext = (rbnext>>1) ^ rbnext;
end

assign raddr = rptr_bin[ADDR_WIDTH-1:0];

always @(posedge rclk) begin:empty_flag
    if (rreset)
        empty <= 1;
    else
        empty <= (rgnext == wptr_sync);
end

always @(posedge rclk) begin:valid_generatoion
    if (rreset)
        rvalid <= 0;
    else
        rvalid <= ren & ~empty;
end
endmodule
