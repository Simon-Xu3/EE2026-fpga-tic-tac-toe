`timescale 1ns / 1ps

module oled_renderer (
    input [12:0] pixel_index,
    input [17:0] board,
    input [3:0] cursor,
    input current_player,
    input [6:0] score_x,
    input [6:0] score_o,
    input game_over,
    input [1:0] winner,
    input draw,
    input [8:0] winning_mask,
    input invalid_flash,
    output reg [15:0] oled_data
);

localparam BLACK = 16'h0000;
localparam WHITE = 16'hFFFF;
localparam RED = 16'hF800;
localparam CYAN = 16'h07FF;
localparam YELLOW = 16'hFFE0;
localparam GREEN = 16'h07E0;
localparam GREY = 16'h4208;

wire [6:0] x = pixel_index % 13'd96;
wire [6:0] y = pixel_index / 13'd96;
wire [6:0] sx = score_x > 7'd99 ? 7'd99 : score_x;
wire [6:0] so = score_o > 7'd99 ? 7'd99 : score_o;

reg [1:0] col;
reg [1:0] row;
reg [3:0] cell_number;
reg [4:0] local_x;
reg [4:0] local_y;
reg [3:0] dx;
reg [3:0] dy;
reg [8:0] distance_squared;
reg [1:0] piece;
reg piece_pixel;
reg border_pixel;
reg [95:0] text_line;
reg [6:0] text_x;
reg [6:0] text_y;
reg [15:0] text_colour;
reg text_enabled;

function [7:0] digit;
    input [6:0] value;
    begin
        digit = 8'd48 + value;
    end
endfunction

function [14:0] font;
    input [7:0] character;
    begin
        case (character)
            "0": font = 15'b111_101_101_101_111;
            "1": font = 15'b010_110_010_010_111;
            "2": font = 15'b111_001_111_100_111;
            "3": font = 15'b111_001_111_001_111;
            "4": font = 15'b101_101_111_001_001;
            "5": font = 15'b111_100_111_001_111;
            "6": font = 15'b111_100_111_101_111;
            "7": font = 15'b111_001_010_010_010;
            "8": font = 15'b111_101_111_101_111;
            "9": font = 15'b111_101_111_001_111;
            "A": font = 15'b010_101_111_101_101;
            "B": font = 15'b110_101_110_101_110;
            "C": font = 15'b111_100_100_100_111;
            "D": font = 15'b110_101_101_101_110;
            "E": font = 15'b111_100_110_100_111;
            "F": font = 15'b111_100_110_100_100;
            "G": font = 15'b111_100_101_101_111;
            "H": font = 15'b101_101_111_101_101;
            "I": font = 15'b111_010_010_010_111;
            "L": font = 15'b100_100_100_100_111;
            "M": font = 15'b101_111_111_101_101;
            "N": font = 15'b101_111_111_111_101;
            "O": font = 15'b111_101_101_101_111;
            "P": font = 15'b111_101_111_100_100;
            "R": font = 15'b110_101_110_101_101;
            "S": font = 15'b111_100_111_001_111;
            "T": font = 15'b111_010_010_010_010;
            "U": font = 15'b101_101_101_101_111;
            "V": font = 15'b101_101_101_101_010;
            "W": font = 15'b101_101_111_111_101;
            "X": font = 15'b101_101_010_101_101;
            "Y": font = 15'b101_101_010_010_010;
            ":": font = 15'b000_010_000_010_000;
            default: font = 15'b000_000_000_000_000;
        endcase
    end
endfunction

function text_pixel;
    input [6:0] px;
    input [6:0] py;
    input [6:0] origin_x;
    input [6:0] origin_y;
    input [95:0] line;
    integer character_number;
    integer font_column;
    integer font_row;
    reg [7:0] character;
    reg [14:0] bits;
    begin
        text_pixel = 1'b0;
        character_number = 0;
        font_column = 0;
        font_row = 0;
        character = 0;
        bits = 0;
        if (px >= origin_x && px < origin_x + 48 &&
            py >= origin_y && py < origin_y + 5) begin
            character_number = (px - origin_x) / 4;
            font_column = (px - origin_x) % 4;
            font_row = py - origin_y;
            character = line >> ((11 - character_number) * 8);
            bits = font(character);
            if (font_column < 3)
                text_pixel = bits[(4 - font_row) * 3 + 2 - font_column];
        end
    end
endfunction

always @* begin
    oled_data = BLACK;
    col = 0;
    row = 0;
    cell_number = 0;
    local_x = 0;
    local_y = 0;
    dx = 0;
    dy = 0;
    distance_squared = 0;
    piece = 0;
    piece_pixel = 0;
    border_pixel = 0;
    text_line = "            ";
    text_x = 7'd59;
    text_y = 0;
    text_colour = WHITE;
    text_enabled = 0;

    if (pixel_index < 13'd6144) begin
        if (x == 56 && y >= 10)
            oled_data = GREY;

        if (x < 54 && y >= 10 && y < 64) begin
            col = x < 18 ? 0 : (x < 36 ? 1 : 2);
            row = y < 28 ? 0 : (y < 46 ? 1 : 2);
            local_x = x - col * 18;
            local_y = y - 10 - row * 18;
            cell_number = row * 3 + col;
            piece = board[cell_number * 2 +: 2];
            dx = local_x >= 8 ? local_x - 8 : 8 - local_x;
            dy = local_y >= 8 ? local_y - 8 : 8 - local_y;
            distance_squared = dx * dx + dy * dy;

            if (x == 17 || x == 35 || y == 27 || y == 45)
                oled_data = WHITE;

            border_pixel = local_x >= 1 && local_x <= 16 &&
                           local_y >= 1 && local_y <= 16 &&
                           (local_x == 1 || local_x == 16 ||
                            local_y == 1 || local_y == 16);

            if (!game_over && cursor < 9 && cell_number == cursor && border_pixel)
                oled_data = invalid_flash ? RED : YELLOW;

            if (game_over && winner != 0 && winning_mask[cell_number] && border_pixel)
                oled_data = GREEN;

            if (piece == 2'b01) begin
                piece_pixel = local_x >= 4 && local_x <= 13 &&
                              local_y >= 4 && local_y <= 13 &&
                              (local_x == local_y || local_x + 1 == local_y ||
                               local_y + 1 == local_x ||
                               local_x + local_y == 16 ||
                               local_x + local_y == 17 ||
                               local_x + local_y == 18);
                if (piece_pixel)
                    oled_data = game_over && winner != 0 && winning_mask[cell_number] ? GREEN : RED;
            end

            if (piece == 2'b10 && distance_squared >= 16 && distance_squared <= 36)
                oled_data = game_over && winner != 0 && winning_mask[cell_number] ? GREEN : CYAN;
        end

        if (y >= 1 && y < 6) begin
            text_enabled = 1;
            text_line = "TIC TAC TOE ";
            text_x = 1;
            text_y = 1;
        end else if (y >= 11 && y < 16) begin
            text_enabled = 1;
            text_line = "SCORE       ";
            text_y = 11;
        end else if (y >= 19 && y < 24) begin
            text_enabled = 1;
            text_line = {"X:", digit(sx / 7'd10), digit(sx % 7'd10), "        "};
            text_y = 19;
            text_colour = RED;
        end else if (y >= 27 && y < 32) begin
            text_enabled = 1;
            text_line = {"O:", digit(so / 7'd10), digit(so % 7'd10), "        "};
            text_y = 27;
            text_colour = CYAN;
        end else if (y >= 36 && y < 41) begin
            text_enabled = 1;
            text_y = 36;
            if (game_over) begin
                text_colour = GREEN;
                if (winner == 2'b01)
                    text_line = "X WINS      ";
                else if (winner == 2'b10)
                    text_line = "O WINS      ";
                else if (draw)
                    text_line = "DRAW        ";
                else
                    text_line = "ROUND END   ";
            end else if (invalid_flash) begin
                text_line = "BAD MOVE    ";
                text_colour = RED;
            end else if (current_player == 0) begin
                text_line = "X TURN      ";
                text_colour = RED;
            end else begin
                text_line = "O TURN      ";
                text_colour = CYAN;
            end
        end else if (y >= 45 && y < 50) begin
            text_enabled = 1;
            text_line = game_over ? "SW0:NEXT    " : "C:PLACE     ";
            text_y = 45;
        end else if (y >= 54 && y < 59) begin
            text_enabled = 1;
            text_line = "SW15:RST    ";
            text_y = 54;
        end

        if (text_enabled && text_pixel(x, y, text_x, text_y, text_line))
            oled_data = text_colour;
    end
end

endmodule
