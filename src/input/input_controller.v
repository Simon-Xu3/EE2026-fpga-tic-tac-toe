`timescale 1ns / 1ps
`default_nettype none

// Member A: synchronized reset, button events and the 3x3 cursor.
// clk MUST be the common 6.25 MHz clock, not the raw 100 MHz board clock.
// Port names match the team's My_Top_Module.v.
// AI-assisted implementation; record this assistance in the project report.
module input_controller #(
    parameter integer CLK_HZ          = 6250000,
    parameter integer SAMPLE_CYCLES   = CLK_HZ / 1000,
    parameter integer LOCKOUT_CYCLES  = (CLK_HZ / 1000) * 200,
    parameter integer RELEASE_SAMPLES = 20
) (
    input  wire       clk,
    input  wire       btnU,
    input  wire       btnD,
    input  wire       btnL,
    input  wire       btnR,
    input  wire       btnC,
    input  wire       sw0_async,
    input  wire       sw15_async,
    input  wire       game_over,
    input  wire       round_start,
    output wire       rst,
    output reg  [3:0] cursor_cell,
    output reg        place_req,
    output reg        new_round_req
);

    // FPGA configuration initializes both stages high, holding the system
    // in reset at startup. This synchronizer never resets itself with rst.
    (* ASYNC_REG = "TRUE" *) reg sw15_meta = 1'b1;
    (* ASYNC_REG = "TRUE" *) reg sw15_sync = 1'b1;

    always @(posedge clk) begin
        sw15_meta <= sw15_async;
        sw15_sync <= sw15_meta;
    end

    assign rst = sw15_sync;

    // Six independent channels, from bit 0 to bit 5:
    // up, down, left, right, centre, SW0.
    wire [5:0] raw_keys;
    wire [5:0] key_pulses;
    assign raw_keys = {sw0_async, btnC, btnR, btnL, btnD, btnU};

    genvar channel;
    generate
        for (channel = 0; channel < 6; channel = channel + 1) begin : keys
            button_event #(
                .CLK_HZ          (CLK_HZ),
                .SAMPLE_CYCLES   (SAMPLE_CYCLES),
                .LOCKOUT_CYCLES  (LOCKOUT_CYCLES),
                .RELEASE_SAMPLES (RELEASE_SAMPLES)
            ) u_button_event (
                .clk       (clk),
                .rst       (rst),
                .key_async (raw_keys[channel]),
                .key_pulse (key_pulses[channel])
            );
        end
    endgenerate

    // Cursor numbering:
    // 0 1 2
    // 3 4 5
    // 6 7 8
    always @(posedge clk) begin
        place_req     <= 1'b0;
        new_round_req <= 1'b0;

        if (rst) begin
            cursor_cell <= 4'd4;
        end else if (round_start) begin
            cursor_cell <= 4'd4;
        end else begin
            // SW0 remains usable after game_over. Member B decides whether
            // to accept the request; this module never clears the board.
            new_round_req <= key_pulses[5];

            if (!game_over) begin
                // Event priority: centre, up, down, left, right.
                // Lower-priority simultaneous events are consumed, not queued.
                if (key_pulses[4]) begin
                    place_req <= 1'b1;
                end else if (key_pulses[0]) begin
                    if (cursor_cell >= 4'd3)
                        cursor_cell <= cursor_cell - 4'd3;
                end else if (key_pulses[1]) begin
                    if (cursor_cell <= 4'd5)
                        cursor_cell <= cursor_cell + 4'd3;
                end else if (key_pulses[2]) begin
                    if (cursor_cell != 4'd0 && cursor_cell != 4'd3 &&
                        cursor_cell != 4'd6)
                        cursor_cell <= cursor_cell - 4'd1;
                end else if (key_pulses[3]) begin
                    if (cursor_cell != 4'd2 && cursor_cell != 4'd5 &&
                        cursor_cell != 4'd8)
                        cursor_cell <= cursor_cell + 4'd1;
                end
            end
        end
    end

endmodule

`default_nettype wire
