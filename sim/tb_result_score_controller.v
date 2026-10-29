`timescale 1ns / 1ps

module tb_result_score_controller;
    reg clk=0;
    reg rst=1;
    reg [17:0] board=0;
    reg current_player=0;
    reg game_over=0;
    reg round_done=0;

    wire [1:0] winner;
    wire draw;
    wire [8:0] winning_mask;
    wire [7:0] score_x, score_o;
    wire [15:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;

    integer i;
    reg [3:0] digits_seen;

    result_score_controller dut (
        .clk(clk), .rst(rst), .board(board),
        .current_player(current_player), .game_over(game_over),
        .round_done(round_done), .winner(winner), .draw(draw),
        .winning_mask(winning_mask), .score_x(score_x), .score_o(score_o),
        .led(led), .seg(seg), .an(an), .dp(dp)
    );

    // 160 ns period = 6.25 MHz.
    always #80 clk=~clk;

    // Build an 18-bit board from two 9-bit X/O position masks.
    task put_board;
        input [8:0] xs, os;
        integer cell;
        begin
            if ((xs & os)!=0) $fatal(1, "X and O overlap");
            @(negedge clk);
            board=0;
            for (cell=0; cell<9; cell=cell+1) begin
                if (xs[cell]) board[2*cell +: 2]=2'b01;
                else if (os[cell]) board[2*cell +: 2]=2'b10;
            end
            #1;
        end
    endtask

    task check_result;
        input [1:0] expected_winner;
        input expected_draw;
        input [8:0] expected_mask;
        begin
            #1;
            if (winner !== expected_winner || draw !== expected_draw ||
                winning_mask !== expected_mask)
                $fatal(1, "Wrong result for board %h: winner=%b draw=%b mask=%b",
                    board, winner, draw, winning_mask);
        end
    endtask

    task check_score;
        input [7:0] x, o;
        begin
            #1;
            if (score_x !== x || score_o !== o)
                $fatal(1, "Wrong score: X=%h O=%h, expected X=%h O=%h",
                    score_x, score_o, x, o);
        end
    endtask

    // round_done stays high for exactly one clock cycle.
    task finish_round;
        begin
            @(negedge clk);
            round_done=1;
            @(negedge clk);
            round_done=0;
            #1;
        end
    endtask

    task check_line;
        input [8:0] cells;
        begin
            put_board(cells, 9'b0);
            check_result(2'b01, 1'b0, cells);
            put_board(9'b0, cells);
            check_result(2'b10, 1'b0, cells);
        end
    endtask

    initial begin
        #20000000;
        $fatal(1, "Test timed out");
    end

    initial begin
        // Reset clears scores and blanks the display.
        @(posedge clk);
        #1;
        check_score(8'h00, 8'h00);
        if (an !== 4'b1111 || seg !== 7'b1111111 ||
            dp !== 1'b1 || led !== 16'h0000)
            $fatal(1, "Reset outputs are wrong");

        @(negedge clk);
        rst=0;
        put_board(9'b0, 9'b0);
        check_result(2'b00, 1'b0, 9'b0);
        if (led !== 16'h0001) $fatal(1, "X-turn LED is wrong");

        put_board(9'b000010000, 9'b000000001);
        check_result(2'b00, 1'b0, 9'b0);

        // All eight lines must work for both X and O.
        check_line(9'b000000111);
        check_line(9'b000111000);
        check_line(9'b111000000);
        check_line(9'b001001001);
        check_line(9'b010010010);
        check_line(9'b100100100);
        check_line(9'b100010001);
        check_line(9'b001010100);

        // If two lines win, highlight both.
        put_board(9'b001001111, 9'b0);
        check_result(2'b01, 1'b0, 9'b001001111);
        put_board(9'b0, 9'b001001111);
        check_result(2'b10, 1'b0, 9'b001001111);

        put_board(9'b110001101, 9'b001110010);
        check_result(2'b00, 1'b1, 9'b0); // Draw

        // The last empty square can produce a win instead of a draw.
        put_board(9'b001110001, 9'b010001110);
        check_result(2'b00, 1'b0, 9'b0);
        put_board(9'b101110001, 9'b010001110);
        check_result(2'b01, 1'b0, 9'b100010001);

        repeat (5) @(posedge clk);
        check_score(8'h00, 8'h00); // A win alone does not add points
        finish_round;
        check_score(8'h01, 8'h00);
        repeat (5) @(posedge clk);
        check_score(8'h01, 8'h00); // Only one point per pulse

        repeat (8) finish_round;
        check_score(8'h09, 8'h00);
        finish_round;
        check_score(8'h10, 8'h00); // BCD carry: 09 -> 10

        put_board(9'b0, 9'b000000111);
        finish_round;
        check_score(8'h10, 8'h01);

        put_board(9'b110001101, 9'b001110010);
        finish_round;
        check_score(8'h10, 8'h01); // Draw adds no points

        current_player=1;
        #1;
        if (led !== 16'h0002) $fatal(1, "O-turn LED is wrong");
        game_over=1;
        #1;
        if (led !== 16'h0004) $fatal(1, "Game-over LED is wrong");

        // X=10 and O=01 should read 1 0 0 1 from left to right.
        digits_seen=4'b0000;
        repeat (4) begin
            @(an);
            #1;
            if (dp !== 1'b1) $fatal(1, "Decimal point should be off");
            case (an)
                4'b0111: begin
                    digits_seen[3]=1;
                    if (seg !== 7'b1111001) $fatal(1, "X tens is wrong");
                end
                4'b1011: begin
                    digits_seen[2]=1;
                    if (seg !== 7'b1000000) $fatal(1, "X ones is wrong");
                end
                4'b1101: begin
                    digits_seen[1]=1;
                    if (seg !== 7'b1000000) $fatal(1, "O tens is wrong");
                end
                4'b1110: begin
                    digits_seen[0]=1;
                    if (seg !== 7'b1111001) $fatal(1, "O ones is wrong");
                end
                default: $fatal(1, "Invalid digit selection: %b", an);
            endcase
        end
        if (digits_seen !== 4'b1111) $fatal(1, "Not all digits were scanned");

        game_over=0;
        put_board(9'b0, 9'b0);
        check_score(8'h10, 8'h01); // New round keeps scores

        put_board(9'b0, 9'b000000111);
        repeat (8) finish_round;
        check_score(8'h10, 8'h09);
        finish_round;
        check_score(8'h10, 8'h10); // O also carries correctly

        put_board(9'b000000111, 9'b0);
        repeat (89) finish_round;
        check_score(8'h99, 8'h10);
        finish_round;
        check_score(8'h99, 8'h10); // Stops at 99

        put_board(9'b0, 9'b000000111);
        repeat (89) finish_round;
        check_score(8'h99, 8'h99);
        finish_round;
        check_score(8'h99, 8'h99);

        @(negedge clk);
        rst=1;
        @(posedge clk);
        #1;
        check_score(8'h00, 8'h00);
        if (an !== 4'b1111 || seg !== 7'b1111111 || led !== 16'h0000)
            $fatal(1, "Final reset failed");

        $display("PASS: Member C testbench");
        $finish;
    end
endmodule
