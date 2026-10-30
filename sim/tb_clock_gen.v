`timescale 1ns / 1ps

module tb_clock_gen;

reg clk100mhz = 0;
always #5 clk100mhz = ~clk100mhz;
wire clk;
real previous_edge;
real period_ns;
integer i;

clock_gen dut (.clk100mhz(clk100mhz), .clk(clk));

initial begin
    wait (dut.mmcm_locked === 1'b1);
    repeat (3) @(posedge clk);
    previous_edge = $realtime;
    for (i = 0; i < 20; i = i + 1) begin
        @(posedge clk);
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
    $fatal(1, "FAIL MMCM lock timeout; run using Vivado UNISIM models");
end

endmodule
