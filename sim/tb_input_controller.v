`timescale 1ns / 1ps

module tb_input_controller;
    reg clk = 0;
    always #80 clk = ~clk; // 6.25 MHz

    reg [5:0] buttons = 0; // SW0, C, R, L, D, U
    reg sw15 = 0;
    reg game_over = 0;
    reg round_start = 0;
    wire rst;
    wire [3:0] cursor_cell;
    wire place_req, new_round_req;
    integer placements = 0;
    integer new_rounds = 0;
    integer checks = 0;
    integer observed_cycles = 0;
    reg previous_place = 0;
    reg previous_new = 0;
    integer position, direction, mask, expected;
    integer before_place, before_new;

    input_controller #(
        .SAMPLE_CYCLES(5),
        .LOCKOUT_CYCLES(50),
        .RELEASE_SAMPLES(3)
    ) dut (
        .clk(clk), .btnU(buttons[0]), .btnD(buttons[1]),
        .btnL(buttons[2]), .btnR(buttons[3]), .btnC(buttons[4]),
        .sw0_async(buttons[5]), .sw15_async(sw15),
        .game_over(game_over), .round_start(round_start),
        .rst(rst), .cursor_cell(cursor_cell),
        .place_req(place_req), .new_round_req(new_round_req)
    );

    always @(posedge clk) begin
        #1;
        observed_cycles = observed_cycles + 1;
        if (observed_cycles > 1) begin
            if ((^cursor_cell === 1'bx) || cursor_cell > 8)
                $fatal(1, "Cursor invalid: %b", cursor_cell);
            if (place_req && previous_place)
                $fatal(1, "place_req lasted longer than one clock");
            if (new_round_req && previous_new)
                $fatal(1, "new_round_req lasted longer than one clock");
        end
        if (place_req) placements = placements + 1;
        if (new_round_req) new_rounds = new_rounds + 1;
        previous_place = place_req;
        previous_new = new_round_req;
    end

    task cycles;
        input integer count;
        begin
            repeat (count) @(negedge clk);
            #1;
        end
    endtask

    task check_cursor;
        input integer wanted;
        begin
            checks = checks + 1;
            if (cursor_cell !== wanted[3:0])
                $fatal(1, "Cursor %0d, expected %0d", cursor_cell, wanted);
        end
    endtask

    task check_counts;
        input integer wanted_place, wanted_new;
        begin
            checks = checks + 1;
            if (placements != wanted_place || new_rounds != wanted_new)
                $fatal(1, "Events place=%0d next=%0d; expected %0d and %0d",
                       placements, new_rounds, wanted_place, wanted_new);
        end
    endtask

    task tap;
        input [5:0] pressed;
        begin
            buttons = pressed;
            cycles(12); 
            buttons = 0;
            cycles(80); 
        end
    endtask

    task centre_cursor;
        begin
            round_start = 1;
            cycles(2);
            round_start = 0;
            cycles(2);
            check_cursor(4);
        end
    endtask

    task go_to;
        input integer wanted;
        begin
            centre_cursor;
            if (wanted / 3 == 0) tap(6'b000001);
            if (wanted / 3 == 2) tap(6'b000010);
            if (wanted % 3 == 0) tap(6'b000100);
            if (wanted % 3 == 2) tap(6'b001000);
            check_cursor(wanted);
        end
    endtask

    task reset_system;
        begin
            sw15 = 1;
            cycles(6);
            if (rst !== 1) $fatal(1, "SW15 did not assert reset");
            check_cursor(4);
            sw15 = 0;
            cycles(40);
            if (rst !== 0) $fatal(1, "SW15 reset did not release");
            check_cursor(4);
        end
    endtask

    initial begin
        #100000000;
        $fatal(1, "Simulation timed out");
    end

    initial begin
        #1;
        if (rst !== 1) $fatal(1, "Startup reset was not asserted");
        cycles(40);
        if (rst !== 0) $fatal(1, "Startup reset did not release");
        check_cursor(4);
        check_counts(0, 0);

        for (position = 0; position < 9; position = position + 1) begin
            for (direction = 0; direction < 4; direction = direction + 1) begin
                go_to(position);
                case (direction)
                    0: expected = position >= 3 ? position - 3 : position;
                    1: expected = position <= 5 ? position + 3 : position;
                    2: expected = position % 3 != 0 ? position - 1 : position;
                    3: expected = position % 3 != 2 ? position + 1 : position;
                endcase
                tap(6'b000001 << direction);
                check_cursor(expected);
            end
            go_to(position);
            before_place = placements;
            before_new = new_rounds;
            tap(6'b010000);
            check_cursor(position); 
            check_counts(before_place + 1, before_new);
        end

        for (mask = 1; mask < 32; mask = mask + 1) begin
            centre_cursor;
            before_place = placements;
            before_new = new_rounds;
            tap(mask[5:0]);
            if (mask & 16) begin
                check_cursor(4);
                check_counts(before_place + 1, before_new);
            end else begin
                if      (mask & 1) expected = 1;
                else if (mask & 2) expected = 7;
                else if (mask & 4) expected = 3;
                else              expected = 5;
                check_cursor(expected);
                check_counts(before_place, before_new);
            end
        end

        before_place = placements;
        before_new = new_rounds;
        buttons = 6'b010000;
        cycles(12);
        repeat (8) begin
            buttons = 0; cycles(2);
            buttons = 6'b010000; cycles(2);
        end
        cycles(1000);
        check_counts(before_place + 1, before_new);

        repeat (5) begin
            buttons = 0; cycles(7);
            buttons = 6'b010000; cycles(8);
        end
        check_counts(before_place + 1, before_new);
        buttons = 0;
        cycles(80);
        tap(6'b010000);
        check_counts(before_place + 2, before_new);

        centre_cursor;
        game_over = 1;
        before_place = placements;
        before_new = new_rounds;
        tap(6'b011111);
        check_cursor(4);
        check_counts(before_place, before_new);
        tap(6'b100000);
        check_counts(before_place, before_new + 1);

        buttons = 6'b010000;
        cycles(100);
        game_over = 0;
        cycles(100);
        check_counts(before_place, before_new + 1);
        buttons = 0;
        cycles(80);

        tap(6'b110000);
        check_counts(before_place + 1, before_new + 2);
        check_cursor(4);

        before_place = placements;
        before_new = new_rounds;
        buttons = 6'b110000;
        while (dut.key_pulses[4] !== 1'b1) cycles(1);
        round_start = 1;
        cycles(2);
        round_start = 0;
        buttons = 0;
        cycles(80);
        check_cursor(4);
        check_counts(before_place, before_new);

        go_to(8);
        centre_cursor;
        game_over = 1;
        reset_system; 
        game_over = 0;

        // Inputs held throughout reset cannot generate phantom presses.
        before_place = placements;
        before_new = new_rounds;
        buttons = 6'b111111;
        reset_system;
        cycles(100);
        check_cursor(4);
        check_counts(before_place, before_new);
        buttons = 0;
        cycles(80);
        tap(6'b010000);
        check_counts(before_place + 1, before_new);

        $display("PASS tb_input_controller: %0d checks; %0d monitored cycles",
                 checks, observed_cycles);
        $finish;
    end
endmodule