`timescale 1ns / 1ps

// game_core.v
// board + one round of the game, A gives cursor/buttons, C gives winner/draw

module game_core (
    input wire clk,
    input wire rst,
    input wire [3:0] cursor_cell, // 0-8
    input wire place_req, // centre button
    input wire new_round_req, // SW0
    input wire [1:0] winner, // from C
    input wire draw, // from C
    output reg [17:0] board, // 9 cells x 2 bits
    output reg current_player, // 0 X, 1 O
    output reg game_over,
    output reg move_ok_pulse,
    output reg move_error_pulse,
    output reg round_start,
    output reg round_done
);

    localparam WAIT_MOVE = 2'd0;
    localparam CHECK_RESULT = 2'd1;
    localparam GAME_OVER = 2'd2;
    reg [1:0] state;

    wire [17:0] shifted = board >> (2 * cursor_cell); // cell i at bits [2i+1:2i]
    wire [1:0] cell_val = shifted[1:0]; // 01 X, 10 O
    wire cell_empty = (cursor_cell <= 4'd8) && (cell_val == 2'b00); // 2'b00 -> can choose here
    wire [1:0] my_mark = current_player ? 2'b10 : 2'b01;
    wire [17:0] mark_shift = {16'd0, my_mark} << (2 * cursor_cell); // Update code

    always @(posedge clk) begin
        move_ok_pulse <= 1'b0;
        move_error_pulse <= 1'b0;
        round_start <= 1'b0; // mouse at centre
        round_done <= 1'b0;  // Add 1 mark

        // Reset
        if (rst) begin
            board <= 18'd0;  // clean up
            current_player <= 1'b0;
            game_over <= 1'b0;
            state <= WAIT_MOVE;
        end else begin
            case (state)
                WAIT_MOVE: begin
                    if (place_req) begin
                        if (cell_empty) begin
                            board <= board | mark_shift; // only that cell changes
                            move_ok_pulse <= 1'b1;
                            state <= CHECK_RESULT;
                        end else begin
                            move_error_pulse <= 1'b1; // occupied, same player tries again
                        end
                    end
                end

                CHECK_RESULT: begin
                    // board updated last cycle so winner/draw from C is correct now
                    if (winner != 2'b00 || draw) begin
                        game_over <= 1'b1;
                        round_done <= 1'b1;
                        state <= GAME_OVER;
                    end else begin
                        current_player <= ~current_player; // switch
                        state <= WAIT_MOVE;
                    end
                end

                GAME_OVER: begin
                    // no place_req here so board is locked
                    if (new_round_req) begin
                        board <= 18'd0;
                        current_player <= 1'b0;
                        game_over <= 1'b0;
                        round_start <= 1'b1;
                        state <= WAIT_MOVE;
                    end
                end

                default: state <= WAIT_MOVE;
            endcase
        end
    end

endmodule
