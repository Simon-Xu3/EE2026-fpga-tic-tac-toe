`timescale 1ns / 1ps

module Display_Test_Top (
    input clk100mhz,
    input [15:0] sw,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input btnC,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an,
    output dp,
    output pmodoledrgb_cs,
    output pmodoledrgb_sdin,
    output pmodoledrgb_sclk,
    output pmodoledrgb_d_cn,
    output pmodoledrgb_resn,
    output pmodoledrgb_vccen,
    output pmodoledrgb_pmoden
);

wire clk;
reg [3:0] startup_reset = 4'b1111;
(* ASYNC_REG = "TRUE" *) reg [15:0] switches_meta = 0;
(* ASYNC_REG = "TRUE" *) reg [15:0] switches_sync = 0;
wire rst = |startup_reset || switches_sync[15];
wire [17:0] board;
wire [3:0] cursor_cell;
wire current_player;
wire [7:0] score_x;
wire [7:0] score_o;
wire game_over;
wire [1:0] winner;
wire draw;
wire [8:0] winning_mask;
wire show_invalid;
reg previous_invalid = 0;
wire move_error_pulse = show_invalid && !previous_invalid;
wire [12:0] pixel_index;
wire [15:0] oled_data;

clock_gen clocks (.clk100mhz(clk100mhz), .clk(clk));

always @(posedge clk) begin
    startup_reset <= {startup_reset[2:0], 1'b0};
    switches_meta <= sw;
    switches_sync <= switches_meta;
    if (rst)
        previous_invalid <= 0;
    else
        previous_invalid <= show_invalid;
end

display_test_pattern scenes (
    .scene(switches_sync[3:0]),
    .selected_cursor(switches_sync[7:4]),
    .board(board),
    .cursor_cell(cursor_cell),
    .current_player(current_player),
    .score_x(score_x),
    .score_o(score_o),
    .game_over(game_over),
    .winner(winner),
    .draw(draw),
    .winning_mask(winning_mask),
    .show_invalid(show_invalid)
);

oled_renderer renderer (
    .clk(clk),
    .rst(rst),
    .pixel_index(pixel_index),
    .cursor_cell(cursor_cell),
    .board(board),
    .current_player(current_player),
    .game_over(game_over),
    .move_error_pulse(move_error_pulse),
    .winner(winner),
    .draw(draw),
    .winning_mask(winning_mask),
    .score_x(score_x),
    .score_o(score_o),
    .oled_data(oled_data)
);

Oled_Display display (
    .clk(clk), .reset(rst), .pixel_data(oled_data),
    .pixel_index(pixel_index), .frame_begin(), .sending_pixels(),
    .sample_pixel(), .cs(pmodoledrgb_cs), .sdin(pmodoledrgb_sdin),
    .sclk(pmodoledrgb_sclk), .d_cn(pmodoledrgb_d_cn),
    .resn(pmodoledrgb_resn), .vccen(pmodoledrgb_vccen),
    .pmoden(pmodoledrgb_pmoden)
);

assign led = {8'b0, btnC, btnU, btnD, btnL, btnR, game_over, rst, 1'b1};
assign seg = 7'b1111111;
assign an = 4'b1111;
assign dp = 1'b1;

endmodule
