// vga_sync_640x480.v - VGA 640x480 @ 60Hz timing generator
// Uses pix_ce clock-enable on a 50MHz system clock (effective 25MHz pixel rate)
// hsync and vsync are active-LOW per VGA standard
module vga_sync_640x480 (
    input  wire        clk,     // 50 MHz system clock
    input  wire        pix_ce,  // pixel clock enable (high every 2 cycles = 25 MHz effective)
    input  wire        rst,
    output reg  [9:0]  x,       // pixel column 0..799
    output reg  [9:0]  y,       // pixel row    0..524
    output wire        hsync,
    output wire        vsync,
    output wire        active   // high when x<640 and y<480
);
    // Standard 640x480 @ 60 Hz timing parameters
    localparam H_VISIBLE = 640;
    localparam H_FP      = 16;
    localparam H_SYNC    = 96;
    localparam H_BP      = 48;
    localparam H_TOTAL   = 800;  // 640+16+96+48

    localparam V_VISIBLE = 480;
    localparam V_FP      = 10;
    localparam V_SYNC    = 2;
    localparam V_BP      = 33;
    localparam V_TOTAL   = 525;  // 480+10+2+33

    always @(posedge clk) begin
        if (rst) begin
            x <= 10'd0;
            y <= 10'd0;
        end else if (pix_ce) begin
            if (x == H_TOTAL - 1) begin
                x <= 10'd0;
                if (y == V_TOTAL - 1)
                    y <= 10'd0;
                else
                    y <= y + 10'd1;
            end else begin
                x <= x + 10'd1;
            end
        end
    end

    // Sync pulses are active-LOW
    assign hsync  = ~((x >= H_VISIBLE + H_FP) && (x < H_VISIBLE + H_FP + H_SYNC));
    assign vsync  = ~((y >= V_VISIBLE + V_FP) && (y < V_VISIBLE + V_FP + V_SYNC));
    assign active =  (x < H_VISIBLE) && (y < V_VISIBLE);
endmodule
