// Write pointer & full generation logic
module wptr_full #(
    parameter ADDR_WIDTH = 4
)(
    input wclk,
    input wreset,
    input winc,
    input      [ADDR_WIDTH:0]   wrptr2,     // gray
    
    output     [ADDR_WIDTH-1:0] waddr,      
    output reg [ADDR_WIDTH:0]   wptr,       // gray
    output reg full
);
reg [ADDR_WIDTH:0] wbin;    // binary
reg [ADDR_WIDTH:0] wgnext;  // gray next
reg [ADDR_WIDTH:0] wbnext;  // binary next
reg waddrmsb;

// graystyle pointer
always @(posedge wclk) begin: next_transition
    if (wreset) begin
        wptr     <= 0;
        waddrmsb <= 0;
    end
    else begin
        wptr     <= wgnext;
        waddrmsb <= wgnext[ADDR_WIDTH] ^ wgnext[ADDR_WIDTH-1];
    end
end

always @(wptr or winc) begin: gray_inc_logic
    integer i;
    for (i=0; i<=ADDR_WIDTH; i=i+1)
        wbin[i] = ^(wptr>>i);           // gray to binary convertion

    if (!full) wbnext = wbin + winc;    // increment
    else       wbnext = wbin;
    
    wgnext = (wbnext>>1) ^ wbnext;      // binary to gray convertion
end

// Memory write-address pointer
assign waddr = {waddrmsb, wptr[ADDR_WIDTH-2:0]};
wire w_nextmsb  = wgnext[ADDR_WIDTH] ^ wgnext[ADDR_WIDTH-1];
wire wr_nextmsb = wrptr2[ADDR_WIDTH] ^ wrptr2[ADDR_WIDTH-1];

always @(posedge wclk)
    if (wreset) full <= 0;
    else        full <= ((wgnext[ADDR_WIDTH] != wrptr2[ADDR_WIDTH]) &&
        (w_nextmsb == wr_nextmsb ) &&
        (wgnext[ADDR_WIDTH-2:0] == wrptr2[ADDR_WIDTH-2:0]));
endmodule
