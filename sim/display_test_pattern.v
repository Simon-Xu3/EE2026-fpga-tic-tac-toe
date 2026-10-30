`timescale 1ns / 1ps

module display_test_pattern (
    input [3:0] scene,
    input [3:0] selected_cursor,
    output reg [17:0] board,
    output reg [3:0] cursor_cell,
    output reg current_player,
    output reg [7:0] score_x,
    output reg [7:0] score_o,
    output reg game_over,
    output reg [1:0] winner,
    output reg draw,
    output reg [8:0] winning_mask,
    output reg show_invalid
);

always @* begin
    board = 0;
    cursor_cell = selected_cursor < 9 ? selected_cursor : 0;
    current_player = 0;
    score_x = 0;
    score_o = 0;
    game_over = 0;
    winner = 0;
    draw = 0;
    winning_mask = 0;
    show_invalid = 0;

    case (scene)
        1: begin
            board[1:0] = 1;
            board[5:4] = 2;
            board[9:8] = 2;
            board[17:16] = 1;
            score_x = 8'h12;
            score_o = 8'h34;
        end
        2: begin
            board[1:0] = 1;
            board[9:8] = 2;
            cursor_cell = 0;
            show_invalid = 1;
            score_x = 2;
            score_o = 1;
        end
        3: begin
            board[1:0] = 1;
            board[3:2] = 1;
            board[5:4] = 1;
            board[7:6] = 2;
            board[9:8] = 2;
            game_over = 1;
            winner = 1;
            winning_mask = 9'b000000111;
            score_x = 1;
        end
        4: begin
            board[1:0] = 1;
            board[3:2] = 1;
            board[17:16] = 1;
            board[5:4] = 2;
            board[9:8] = 2;
            board[13:12] = 2;
            current_player = 1;
            game_over = 1;
            winner = 2;
            winning_mask = 9'b001010100;
            score_o = 1;
        end
        5: begin
            board = {2'd1, 2'd1, 2'd2, 2'd2, 2'd2, 2'd1, 2'd1, 2'd2, 2'd1};
            game_over = 1;
            draw = 1;
            score_x = 7;
            score_o = 8;
        end
        6: begin
            score_x = 8'h99;
            score_o = 8'h99;
            current_player = 1;
        end
        7: begin
            board[1:0] = 1;
            board[9:8] = 1;
            board[17:16] = 1;
            board[3:2] = 2;
            board[5:4] = 2;
            game_over = 1;
            winner = 1;
            winning_mask = 9'b100010001;
            score_x = 9;
            score_o = 8;
        end
        default: begin
        end
    endcase
end

endmodule
