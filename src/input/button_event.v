`timescale 1ns / 1ps
`default_nettype none

// Defaults: 6.25 MHz clock, 1 ms sampling, 200 ms lockout,
// and approximately 20 ms of stable release before another press.
module button_event #(
    parameter integer CLK_HZ          = 6250000,
    parameter integer SAMPLE_CYCLES   = CLK_HZ / 1000,
    parameter integer LOCKOUT_CYCLES  = (CLK_HZ / 1000) * 200,
    parameter integer RELEASE_SAMPLES = 20
) (
    input  wire clk,
    input  wire rst,
    input  wire key_async,
    output reg  key_pulse
);

    localparam integer SAMPLE_WIDTH =
        (SAMPLE_CYCLES > 1) ? $clog2(SAMPLE_CYCLES) : 1;
    localparam integer LOCKOUT_WIDTH =
        (LOCKOUT_CYCLES > 1) ? $clog2(LOCKOUT_CYCLES) : 1;
    localparam integer RELEASE_WIDTH =
        (RELEASE_SAMPLES > 1) ? $clog2(RELEASE_SAMPLES) : 1;

    (* ASYNC_REG = "TRUE" *) reg key_meta;
    (* ASYNC_REG = "TRUE" *) reg key_sync;
    reg [SAMPLE_WIDTH-1:0] sample_count;
    reg [LOCKOUT_WIDTH-1:0] lockout_count;
    reg [RELEASE_WIDTH-1:0] release_count;
    reg armed;

    wire sample_tick = (sample_count == SAMPLE_CYCLES - 1);

    always @(posedge clk) begin
        if (rst) begin
            key_meta <= 1'b1;
            key_sync <= 1'b1;
        end else begin
            key_meta <= key_async;
            key_sync <= key_meta;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            sample_count  <= 0;
            lockout_count <= 0;
            release_count <= 0;
            armed         <= 1'b0;
            key_pulse     <= 1'b0;
        end else begin
            key_pulse <= 1'b0;

            if (sample_tick)
                sample_count <= 0;
            else
                sample_count <= sample_count + 1'b1;

            if (lockout_count != 0) begin
                lockout_count <= lockout_count - 1'b1;
                release_count <= 0;
            end else if (armed) begin
                if (sample_tick && key_sync) begin
                    key_pulse     <= 1'b1;
                    armed         <= 1'b0;
                    lockout_count <= LOCKOUT_CYCLES - 1;
                    release_count <= 0;
                end
            end else begin
                if (key_sync) begin
                    release_count <= 0;
                end else if (sample_tick) begin
                    if (release_count == RELEASE_SAMPLES - 1) begin
                        armed         <= 1'b1;
                        release_count <= 0;
                    end else begin
                        release_count <= release_count + 1'b1;
                    end
                end
            end
        end
    end

endmodule

`default_nettype wire
