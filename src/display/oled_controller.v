`timescale 1ns / 1ps

module oled_controller #(
    parameter integer INVALID_CYCLES = 3125000
) (
    input clk6p25m,
    input reset,
    input round_start,
    input [17:0] board,
    input [3:0] cursor,
    input current_player,
    input [6:0] score_x,
    input [6:0] score_o,
    input game_over,
    input [1:0] winner,
    input draw,
    input [8:0] winning_mask,
    input invalid_move,
    output [7:0] JA
);

localparam integer TIMER_WIDTH = INVALID_CYCLES < 2 ? 1 : $clog2(INVALID_CYCLES + 1);
reg [TIMER_WIDTH-1:0] invalid_timer;
reg [17:0] frame_board;
reg [3:0] frame_cursor;
reg frame_player;
reg [6:0] frame_score_x;
reg [6:0] frame_score_o;
reg frame_game_over;
reg [1:0] frame_winner;
reg frame_draw;
reg [8:0] frame_mask;
reg frame_invalid;
wire frame_begin;
wire [12:0] pixel_index;
wire [15:0] oled_data;

always @(posedge clk6p25m) begin
    if (reset || round_start || game_over)
        invalid_timer <= 0;
    else if (invalid_move)
        invalid_timer <= INVALID_CYCLES;
    else if (invalid_timer != 0)
        invalid_timer <= invalid_timer - 1'b1;
end

always @(posedge clk6p25m) begin
    if (reset) begin
        frame_board <= 0;
        frame_cursor <= 0;
        frame_player <= 0;
        frame_score_x <= 0;
        frame_score_o <= 0;
        frame_game_over <= 0;
        frame_winner <= 0;
        frame_draw <= 0;
        frame_mask <= 0;
        frame_invalid <= 0;
    end else if (frame_begin) begin
        frame_board <= board;
        frame_cursor <= cursor;
        frame_player <= current_player;
        frame_score_x <= score_x;
        frame_score_o <= score_o;
        frame_game_over <= game_over;
        frame_winner <= winner;
        frame_draw <= draw;
        frame_mask <= winning_mask;
        frame_invalid <= !round_start && !game_over && (invalid_move || invalid_timer != 0);
    end
end

oled_renderer renderer (
    .pixel_index(pixel_index),
    .board(frame_board),
    .cursor(frame_cursor),
    .current_player(frame_player),
    .score_x(frame_score_x),
    .score_o(frame_score_o),
    .game_over(frame_game_over),
    .winner(frame_winner),
    .draw(frame_draw),
    .winning_mask(frame_mask),
    .invalid_flash(frame_invalid),
    .oled_data(oled_data)
);

Oled_Display driver (
    .clk(clk6p25m),
    .reset(reset),
    .frame_begin(frame_begin),
    .sending_pixels(),
    .sample_pixel(),
    .pixel_index(pixel_index),
    .pixel_data(oled_data),
    .cs(JA[0]),
    .sdin(JA[1]),
    .sclk(JA[3]),
    .d_cn(JA[4]),
    .resn(JA[5]),
    .vccen(JA[6]),
    .pmoden(JA[7])
);

assign JA[2] = 1'b0;

endmodule
