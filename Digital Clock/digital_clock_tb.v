`timescale 1ns/1ns

module digital_clock_tb;

reg clk;    // 50MHz
reg reset;
//reg ena;

wire pm;
wire [7:0] hh;
wire [7:0] mm;
wire [7:0] ss;

clock_top dut (
    .clk(clk),
    .reset(reset),
    .pm(pm),
    .hh(hh),
    .mm(mm),
    .ss(ss)
);

always #5 clk = ~clk;
reg ena;
localparam COUNT_MAX = 50_000_000 - 1;
reg [$clog2(COUNT_MAX)-1:0] count;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        count   <= 0;
        ena <= 0;
    end
    else if (count == COUNT_MAX) begin
        count   <= 0;
        ena <= 1;
    end
    else begin
        count   <= count + 1;
        ena <= 0;
    end
end

// Reference model variables
reg ref_pm;
reg [7:0] ref_hh, ref_mm, ref_ss;

integer error_count = 0;

// TASK: Increment BCD (00–59)
task increment_bcd60;
    inout [7:0] val;
begin
    if(val[3:0] == 4'h9) begin
        if (val[7:4] == 4'h5)
            val = 8'h00;
        else begin
            val[3:0] = 4'h0;
            val[7:4] = val[7:4] + 1'b1;
        end
    end
    else
        val[3:0] = val[3:0] + 1'b1;
end
endtask

// TASK: Increment Hour (12-hour format)
task increment_hour;
begin
    if(ref_hh == 8'h11) begin
    	ref_hh = 8'h12;
    	ref_pm = ~ref_pm;
    end
    else if(ref_hh == 8'h12)
        ref_hh = 8'h01;
    else if(ref_hh[3:0] == 4'h9) begin
        ref_hh[3:0] = 4'h0;
        ref_hh[7:4] = ref_hh[7:4] + 1'b1;
    end
    else
        ref_hh[3:0] = ref_hh[3:0] + 1'b1;
end
endtask

// Reference Model Update
always @(posedge clk or posedge reset) begin
    if (reset) begin
        ref_hh <= 8'h12;
        ref_mm <= 8'h00;
        ref_ss <= 8'h00;
        ref_pm <= 1'b0;
    end
    else if (ena) begin
        if (ref_ss == 8'h59) begin
            ref_ss <= 8'h00;

            if (ref_mm == 8'h59) begin
                ref_mm = 8'h00;
                increment_hour();
            end
            else
                increment_bcd60(ref_mm);
        end
        else
            increment_bcd60(ref_ss);
    end
end

// Checker
always @(negedge clk) begin // values update @posedge clk and gets checked @negedge clk
    if ((!reset) && (hh !== ref_hh || mm !== ref_mm || ss !== ref_ss || pm !== ref_pm)) begin
        $display("ERROR at time %0t", $time);
        $display("DUT = %h:%h:%h PM=%b", hh, mm, ss, pm);
        $display("REF = %h:%h:%h PM=%b", ref_hh, ref_mm, ref_ss, ref_pm);
        error_count = error_count + 1;
        $stop;
    end
end

initial begin
    clk = 0;
    reset = 1;

    #20;
    reset = 0;

    repeat (5_000_000_000_000) @(posedge clk);

    if (error_count == 0)
        $display("TEST PASSED");
    else
        $display("TEST FAILED");

    $finish;
end
endmodule
