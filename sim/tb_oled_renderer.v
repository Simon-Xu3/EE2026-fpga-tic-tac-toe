`timescale 1ns / 1ps

module tb_oled_renderer;

reg [12:0] pixel_index = 0;
reg [17:0] board = 0;
reg [3:0] cursor = 0;
reg current_player = 0;
reg [6:0] score_x = 0;
reg [6:0] score_o = 0;
reg game_over = 0;
reg [1:0] winner = 0;
reg draw = 0;
reg [8:0] winning_mask = 0;
reg invalid_flash = 0;
wire [15:0] oled_data;
integer c;
integer i;
integer line_number;
integer checks = 0;

oled_renderer dut (
    .pixel_index(pixel_index), .board(board), .cursor(cursor),
    .current_player(current_player), .score_x(score_x), .score_o(score_o),
    .game_over(game_over), .winner(winner), .draw(draw),
    .winning_mask(winning_mask), .invalid_flash(invalid_flash),
    .oled_data(oled_data)
);

task check_pixel;
    input integer x;
    input integer y;
    input [15:0] expected;
    begin
        pixel_index = y * 96 + x;
        #1;
        checks = checks + 1;
        if (oled_data !== expected)
            $fatal(1, "FAIL x=%0d y=%0d expected=%h got=%h", x, y, expected, oled_data);
    end
endtask

initial begin
    #1;
    for (c = 0; c < 9; c = c + 1) begin
        cursor = c;
        for (i = 0; i < 9; i = i + 1)
            check_pixel((i % 3) * 18 + 1, (i / 3) * 18 + 11,
                        i == c ? 16'hFFE0 : 16'h0000);
    end
    cursor = 15;
    check_pixel(1, 11, 16'h0000);
    check_pixel(17, 20, 16'hFFFF);
    check_pixel(35, 50, 16'hFFFF);
    check_pixel(10, 27, 16'hFFFF);
    check_pixel(40, 45, 16'hFFFF);
    board[1:0] = 1;
    board[9:8] = 2;
    check_pixel(4, 14, 16'hF800);
    check_pixel(26, 30, 16'h07FF);
    check_pixel(26, 36, 16'h0000);
    cursor = 0;
    invalid_flash = 1;
    check_pixel(1, 11, 16'hF800);
    check_pixel(59, 36, 16'hF800);
    invalid_flash = 0;
    check_pixel(1, 11, 16'hFFE0);
    current_player = 1;
    check_pixel(59, 36, 16'h07FF);

    game_over = 1;
    winner = 1;
    for (line_number = 0; line_number < 8; line_number = line_number + 1) begin
        case (line_number)
            0: winning_mask = 9'b000000111;
            1: winning_mask = 9'b000111000;
            2: winning_mask = 9'b111000000;
            3: winning_mask = 9'b001001001;
            4: winning_mask = 9'b010010010;
            5: winning_mask = 9'b100100100;
            6: winning_mask = 9'b100010001;
            7: winning_mask = 9'b001010100;
        endcase
        board = 0;
        for (i = 0; i < 9; i = i + 1) begin
            if (winning_mask[i])
                board[i * 2 +: 2] = 1;
            check_pixel((i % 3) * 18 + 1, (i / 3) * 18 + 11,
                        winning_mask[i] ? 16'h07E0 : 16'h0000);
        end
    end
    check_pixel(59, 36, 16'h07E0);
    winner = 0;
    winning_mask = 0;
    draw = 1;
    check_pixel(59, 36, 16'h07E0);
    check_pixel(1, 11, 16'h0000);

    game_over = 0;
    draw = 0;
    score_x = 9;
    score_o = 34;
    check_pixel(67, 19, 16'hF800);
    check_pixel(71, 19, 16'hF800);
    check_pixel(67, 28, 16'h0000);
    check_pixel(69, 28, 16'h07FF);
    check_pixel(71, 27, 16'h07FF);
    check_pixel(72, 27, 16'h0000);
    score_x = 10;
    check_pixel(67, 19, 16'h0000);
    check_pixel(68, 19, 16'hF800);
    check_pixel(72, 20, 16'h0000);
    score_x = 127;
    check_pixel(67, 19, 16'hF800);
    check_pixel(67, 22, 16'h0000);
    check_pixel(71, 22, 16'h0000);

    for (i = 0; i < 6144; i = i + 1) begin
        pixel_index = i;
        #1;
        if ((^oled_data) === 1'bx)
            $fatal(1, "FAIL unknown pixel at %0d", i);
    end
    pixel_index = 8191;
    #1;
    if (oled_data !== 0)
        $fatal(1, "FAIL out-of-range pixel");
    $display("PASS tb_oled_renderer: %0d key pixels and one full frame", checks);
    $finish;
end

endmodule
