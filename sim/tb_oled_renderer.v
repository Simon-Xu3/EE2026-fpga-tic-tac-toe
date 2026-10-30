`timescale 1ns / 1ps

module tb_oled_renderer;

reg clk = 0;
always #80 clk = ~clk;
reg rst = 1;
reg [12:0] pixel_index = 0;
reg [3:0] cursor_cell = 0;
reg [17:0] board = 0;
reg current_player = 0;
reg game_over = 0;
reg move_error_pulse = 0;
reg [1:0] winner = 0;
reg draw = 0;
reg [8:0] winning_mask = 0;
reg [7:0] score_x = 0;
reg [7:0] score_o = 0;
wire [15:0] oled_data;
integer c;
integer i;
integer line_number;
integer checks = 0;

oled_renderer #(.INVALID_CYCLES(8)) dut (
    .clk(clk), .rst(rst), .pixel_index(pixel_index),
    .cursor_cell(cursor_cell), .board(board),
    .current_player(current_player), .game_over(game_over),
    .move_error_pulse(move_error_pulse), .winner(winner),
    .draw(draw), .winning_mask(winning_mask),
    .score_x(score_x), .score_o(score_o), .oled_data(oled_data)
);

task tick;
    begin
        @(posedge clk);
        #1;
    end
endtask

task snapshot;
    begin
        pixel_index = 0;
        tick;
        pixel_index = 1;
        #1;
    end
endtask

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
    tick;
    tick;
    rst = 0;
    for (c = 0; c < 9; c = c + 1) begin
        cursor_cell = c;
        snapshot;
        for (i = 0; i < 9; i = i + 1)
            check_pixel((i % 3) * 18 + 1, (i / 3) * 18 + 11,
                        i == c ? 16'hFFE0 : 16'h0000);
    end
    cursor_cell = 15;
    board[1:0] = 1;
    board[9:8] = 2;
    score_x = 8'h12;
    score_o = 8'h34;
    snapshot;
    check_pixel(17, 20, 16'hFFFF);
    check_pixel(10, 27, 16'hFFFF);
    check_pixel(4, 14, 16'hF800);
    check_pixel(26, 30, 16'h07FF);
    check_pixel(26, 36, 16'h0000);
    check_pixel(67, 19, 16'h0000);
    check_pixel(68, 19, 16'hF800);
    check_pixel(73, 22, 16'h0000);
    check_pixel(69, 28, 16'h07FF);
    check_pixel(72, 27, 16'h0000);

    pixel_index = 1000;
    board = 18'd2;
    tick;
    if (dut.frame_board !== 18'h00201)
        $fatal(1, "FAIL board changed inside active frame");
    snapshot;
    check_pixel(8, 12, 16'h07FF);

    cursor_cell = 0;
    move_error_pulse = 1;
    pixel_index = 1000;
    tick;
    if (dut.invalid_timer !== 8)
        $fatal(1, "FAIL one-cycle invalid pulse");
    move_error_pulse = 0;
    snapshot;
    check_pixel(1, 11, 16'hF800);
    repeat (7) tick;
    if (dut.invalid_timer !== 0)
        $fatal(1, "FAIL invalid timer expiration");
    snapshot;
    check_pixel(1, 11, 16'hFFE0);

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
            default: winning_mask = 0;
        endcase
        board = 0;
        for (i = 0; i < 9; i = i + 1)
            if (winning_mask[i])
                board[i * 2 +: 2] = 1;
        snapshot;
        for (i = 0; i < 9; i = i + 1)
            check_pixel((i % 3) * 18 + 1, (i / 3) * 18 + 11,
                        winning_mask[i] ? 16'h07E0 : 16'h0000);
    end

    winner = 0;
    winning_mask = 0;
    draw = 1;
    score_x = 8'h99;
    score_o = 8'h99;
    snapshot;
    check_pixel(59, 36, 16'h07E0);
    check_pixel(1, 11, 16'h0000);
    check_pixel(67, 19, 16'hF800);

    rst = 1;
    tick;
    if (dut.frame_board !== 0 || dut.frame_score_x !== 0 || dut.invalid_timer !== 0)
        $fatal(1, "FAIL reset");
    $display("PASS tb_oled_renderer: %0d pixels; BCD, snapshots, timer, reset", checks);
    $finish;
end

endmodule
