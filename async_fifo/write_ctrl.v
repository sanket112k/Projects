// Write pointer & full generation logic
module write_ctrl #(
    parameter ADDR_WIDTH = 4
)(
    input wclk,
    input wreset,
    input wen,
    input      [ADDR_WIDTH:0]   rptr_sync,     // gray
    
    output     [ADDR_WIDTH-1:0] waddr,      // binary
    output reg [ADDR_WIDTH:0]   wptr_gray,       // gray
    output reg full
);
reg [ADDR_WIDTH:0] wptr_bin;    // binary
reg [ADDR_WIDTH:0] wgnext;      // gray next
reg [ADDR_WIDTH:0] wbnext;      // binary next

always @(posedge wclk) begin: next_transition
    if (wreset) begin
        wptr_bin  <= 0;
        wptr_gray <= 0;
    end
    else begin
        wptr_bin  <= wbnext;
        wptr_gray <= wgnext;
    end
end

always @(*) begin: ptr_inc_logic
    wbnext = wptr_bin + (wen & ~full);    // increment
    wgnext = (wbnext>>1) ^ wbnext;      // binary to gray convertion
end

assign waddr = wptr_bin[ADDR_WIDTH-1:0];

always @(posedge wclk) begin:full_flag
    if (wreset) full <= 0;
    else        full <= (wgnext == {~rptr_sync[ADDR_WIDTH : ADDR_WIDTH-1], rptr_sync[ADDR_WIDTH-2 : 0]});
end

endmodule
