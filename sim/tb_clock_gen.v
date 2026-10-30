`timescale 1ns / 1ps

module tb_clock_gen;

reg clk100 = 0;
always #5 clk100 = ~clk100;
reg reset = 1;
wire clk6p25m;
wire locked;
real previous_edge;
real period_ns;
integer i;

clock_gen dut (
    .clk100(clk100), .reset(reset), .clk6p25m(clk6p25m), .locked(locked)
);

initial begin
    #200;
    reset = 0;
    wait (locked === 1'b1);
    repeat (3) @(posedge clk6p25m);
    previous_edge = $realtime;
    for (i = 0; i < 20; i = i + 1) begin
        @(posedge clk6p25m);
        period_ns = $realtime - previous_edge;
        if (period_ns < 159.99 || period_ns > 160.01)
            $fatal(1, "FAIL clock period = %0.3f ns", period_ns);
        previous_edge = $realtime;
    end
    $display("PASS tb_clock_gen: 20 periods of 160 ns");
    $finish;
end

initial begin
    #200000;
    $fatal(1, "FAIL MMCM lock timeout; use Vivado UNISIM simulation");
end

endmodule
