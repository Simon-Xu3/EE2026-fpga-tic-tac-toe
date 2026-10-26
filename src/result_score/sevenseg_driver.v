module result_score_controller(
    input clk, input rst,
    input [17:0] board,
    input current_player, input game_over, input round_done,
    output [1:0] winner, output draw,
    output [8:0] winning_mask,
    output [7:0] score_x, output [7:0] score_o,
    output [15:0] led,
    output [6:0] seg, output [3:0] an, output dp
);

result_detector u_result_detector(
    .board(board),
    .winner(winner),
    .draw(draw),
    .winning_mask(winning_mask)
);

score_counter u_score_counter(
    .clk(clk),
    .rst(rst),
    .round_done(round_done),
    .winner(winner),
    .score_x(score_x),
    .score_o(score_o)
);

sevenseg_driver u_sevenseg_driver(
    .clk(clk),
    .rst(rst),
    .score_x(score_x),
    .score_o(score_o),
    .seg(seg),
    .an(an),
    .dp(dp)
);

assign led=rst ? 16'h0000 : game_over ? 16'h0004 : 
    current_player ? 16'h0002 : 16'h0001;

endmodule