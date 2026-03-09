`timescale 1ns/1ns
module apb_slave(
    input pclk, presetn,
    input psel, penable, pwrite,
    input [7:0] paddr, pwdata,
    output reg pready,
    output [7:0] prdata
);
reg [7:0] mem [0:255];
reg [7:0] addr_reg;

always @(posedge pclk) begin
    if (!presetn) pready = 0;
end

always @(*) begin
    if (psel) begin
        if (!penable) pready = 0;
        else begin
            pready = 1;
            if (pwrite) mem[paddr] = pwdata;
            else addr_reg = paddr;
        end
    end
end

assign prdata = mem[addr_reg];
endmodule
