`timescale 1ns / 1ps

module tb_oled_controller;

reg clk = 0;
always #80 clk = ~clk;
reg reset = 1;
reg round_start = 0;
reg [17:0] board = 0;
reg [3:0] cursor = 0;
reg invalid_move = 0;
reg game_over = 0;
wire [7:0] JA;
integer i;

oled_controller #(.INVALID_CYCLES(8)) dut (
    .clk6p25m(clk), .reset(reset), .round_start(round_start),
    .board(board), .cursor(cursor), .current_player(1'b0),
    .score_x(7'd12), .score_o(7'd34), .game_over(game_over),
    .winner(2'd0), .draw(1'b0), .winning_mask(9'd0),
    .invalid_move(invalid_move), .JA(JA)
);

task tick;
    begin
        @(posedge clk);
        #1;
    end
endtask

initial begin
    force dut.frame_begin = 0;
    tick;
    tick;
    @(negedge clk);
    reset = 0;
    board = 18'h00001;
    cursor = 4;
    tick;
    if (dut.frame_board !== 0)
        $fatal(1, "FAIL changed outside frame boundary");
    force dut.frame_begin = 1;
    tick;
    if (dut.frame_board !== board || dut.frame_cursor !== 4)
        $fatal(1, "FAIL frame capture");
    force dut.frame_begin = 0;
    @(negedge clk);
    board = 18'h00201;
    invalid_move = 1;
    tick;
    if (dut.invalid_timer !== 8)
        $fatal(1, "FAIL invalid pulse not captured");
    @(negedge clk);
    invalid_move = 0;
    force dut.frame_begin = 1;
    tick;
    if (dut.frame_invalid !== 1)
        $fatal(1, "FAIL invalid feedback not held");
    force dut.frame_begin = 0;
    for (i = 0; i < 7; i = i + 1)
        tick;
    if (dut.invalid_timer !== 0)
        $fatal(1, "FAIL invalid timer length");
    force dut.frame_begin = 1;
    tick;
    if (dut.frame_invalid !== 0)
        $fatal(1, "FAIL invalid feedback not cleared");
    @(negedge clk);
    invalid_move = 1;
    tick;
    @(negedge clk);
    invalid_move = 0;
    round_start = 1;
    tick;
    if (dut.invalid_timer !== 0 || dut.frame_invalid !== 0)
        $fatal(1, "FAIL next round clear");
    @(negedge clk);
    round_start = 0;
    reset = 1;
    tick;
    if (dut.frame_board !== 0 || dut.frame_score_x !== 0 || JA[2] !== 0)
        $fatal(1, "FAIL display reset");
    $display("PASS tb_oled_controller: snapshots, invalid pulse, timer, round clear, reset");
    $finish;
end

endmodule
