`timescale 1ns / 1ps

// tb for game_core
// A and C are not here so I just poke the inputs myself
// prints PASS / FAIL in the tcl console, no need to stare at waveform

module tb_game_core;
    reg clk;
    reg rst;
    reg [3:0] cursor_cell;
    reg place_req;
    reg new_round_req;
    reg [1:0] winner; // this is me pretending to be C
    reg draw;
    wire [17:0] board;
    wire current_player;
    wire game_over;
    wire move_ok_pulse;
    wire move_error_pulse;
    wire round_start;
    wire round_done;

    game_core dut (clk, rst, cursor_cell, place_req, new_round_req, winner, draw,
                   board, current_player, game_over, move_ok_pulse, move_error_pulse, round_start, round_done);

    initial begin
        clk = 0;
    end

    always begin
        #80; clk = ~clk; // 6.25 MHz
    end

    // how many times round_done fired, shd be 1 per game
    integer done_cnt = 0;
    always @(posedge clk) begin
        if (round_done) done_cnt = done_cnt + 1;
    end

    // move cursor to cell c and tap the centre button for 1 clk
    // change stuff on negedge so it doesnt clash with the posedge inside dut
    task place(input [3:0] c);
        begin
            @(negedge clk);
            cursor_cell = c;
            place_req = 1;
            @(negedge clk);
            place_req = 0;
        end
    endtask

    initial begin
        // reset first
        rst = 1; cursor_cell = 4'd4; place_req = 0; new_round_req = 0; winner = 2'b00; draw = 0;
        #400;
        rst = 0;
        #200;
        if (board == 0 && current_player == 0 && game_over == 0) $display("PASS reset");
        else $display("FAIL reset board=%b", board);

        // X on cell 4 -> bits [9:8] = 01, then its O's turn
        place(4);
        #400; // 2 clk to go WAIT_MOVE -> CHECK_RESULT -> WAIT_MOVE, 400 is enough
        if (board == 18'b00_0000_0001_0000_0000 && current_player == 1) $display("PASS X on cell 4");
        else $display("FAIL X on cell 4 board=%b player=%b", board, current_player);

        // O presses cell 4 again, taken already so nothing shd change
        place(4);
        #400;
        if (board == 18'b00_0000_0001_0000_0000 && current_player == 1) $display("PASS occupied cell");
        else $display("FAIL occupied cell board=%b player=%b", board, current_player);

        // O on cell 0 -> bits [1:0] = 10, back to X
        place(0);
        #400;
        if (board == 18'b00_0000_0001_0000_0010 && current_player == 0) $display("PASS O on cell 0");
        else $display("FAIL O on cell 0 board=%b player=%b", board, current_player);

        // X on cell 1, and this time C says X won
        winner = 2'b01;
        place(1);
        #400;
        if (game_over == 1 && done_cnt == 1) $display("PASS game over, round_done once");
        else $display("FAIL game over=%b done_cnt=%0d", game_over, done_cnt);

        // game is over, pressing cell 2 shd do nothing
        place(2);
        #400;
        if (board[5:4] == 2'b00 && done_cnt == 1) $display("PASS board locked");
        else $display("FAIL board locked board=%b done_cnt=%0d", board, done_cnt);

        // flip SW0 -> new round, board clears, X first again
        winner = 2'b00;
        @(negedge clk);
        new_round_req = 1;
        @(negedge clk);
        new_round_req = 0;
        #400;
        if (board == 0 && game_over == 0 && current_player == 0) $display("PASS new round");
        else $display("FAIL new round board=%b", board);

        $display("done");
        $finish;
    end
endmodule
