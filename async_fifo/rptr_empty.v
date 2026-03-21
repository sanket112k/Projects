// Read pointer & empty generation logic
module rptr_empty #(
    parameter ADDR_WIDTH = 4
)(
    input rclk,
    input rreset,
    input rinc,
    input [ADDR_WIDTH:0] rwptr2,

    output     [ADDR_WIDTH-1:0] raddr,
    output reg [ADDR_WIDTH:0] rptr,
    output reg empty
);
reg [ADDR_WIDTH:0] rbin;
reg [ADDR_WIDTH:0] rgnext;
reg [ADDR_WIDTH:0] rbnext;
reg raddrmsb;

// graystyle pointer
always @(posedge rclk) begin: next_transition
    if (rreset) begin
        rptr     <= 0;
        raddrmsb <= 0;
    end
    else begin
        rptr <= rgnext;
        raddrmsb <= rgnext[ADDR_WIDTH] ^ rgnext[ADDR_WIDTH-1];
    end
end

always @(rptr or rinc) begin: gray_inc_logic
    integer i;
    for (i=0; i<=ADDRWIDTH; i=i+1)
        rbin[i] = ^(rptr>>i);

    if(!empty) rbnext = rbin + rinc;
    else       rbnext = rbin;

    rgnext = (rbnext>>1) ^ rbnext;
end

// Memory read-address pointer
assign raddr = {raddrmsb, rptr[ADDR_WIDTH-2:0]};

always @(posedge rclk)
    if (rreset) empty <= 0;
    else        empty <= (rgnext == rwptr2);
endmodule
