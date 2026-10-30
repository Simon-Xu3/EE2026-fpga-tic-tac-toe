`timescale 1ns / 1ps

module clock_gen (
    input clk100mhz,
    output clk
);

wire feedback;
wire feedback_buffered;
wire clock_unbuffered;
wire mmcm_locked;

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
    .CLKIN1(clk100mhz),
    .CLKFBIN(feedback_buffered),
    .RST(1'b0),
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
    .LOCKED(mmcm_locked)
);

BUFG feedback_buf (.I(feedback), .O(feedback_buffered));
BUFGCE clock_buf (.I(clock_unbuffered), .CE(mmcm_locked), .O(clk));

endmodule
