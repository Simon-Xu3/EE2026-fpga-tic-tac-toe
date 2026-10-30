`timescale 1ns / 1ps

module member4_display_system (
    input clk100,
    input full_reset,
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
    output clk6p25m,
    output reset,
    output locked,
    output [7:0] JA
);

clock_gen clocks (
    .clk100(clk100),
    .reset(1'b0),
    .clk6p25m(clk6p25m),
    .locked(locked)
);

reset_sync resets (
    .clk(clk6p25m),
    .async_reset(full_reset || !locked),
    .reset(reset)
);

oled_controller display (
    .clk6p25m(clk6p25m),
    .reset(reset),
    .round_start(round_start),
    .board(board),
    .cursor(cursor),
    .current_player(current_player),
    .score_x(score_x),
    .score_o(score_o),
    .game_over(game_over),
    .winner(winner),
    .draw(draw),
    .winning_mask(winning_mask),
    .invalid_move(invalid_move),
    .JA(JA)
);

endmodule
