`timescale 1ns / 1ps

module clock_gen (
    input clk100,
    input reset,
    output clk6p25m,
    output locked
);

wire feedback;
wire feedback_buffered;
wire clock_unbuffered;

MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKIN1_PERIOD(10.0),
    .DIVCLK_DIVIDE(1),
    .CLKFBOUT_MULT_F(8.0),
    .CLKOUT0_DIVIDE_F(128.0),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0.0),
    .STARTUP_WAIT("FALSE")
) mmcm (
    .CLKIN1(clk100),
    .CLKFBIN(feedback_buffered),
    .RST(reset),
    .PWRDWN(1'b0),
    .CLKFBOUT(feedback),
    .CLKFBOUTB(),
    .CLKOUT0(clock_unbuffered),
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .LOCKED(locked)
);

BUFG feedback_buf (.I(feedback), .O(feedback_buffered));
BUFG clock_buf (.I(clock_unbuffered), .O(clk6p25m));

endmodule
