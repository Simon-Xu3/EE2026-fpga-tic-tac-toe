`default_nettype none

// EE2026 two-player Tic Tac Toe -- integration and interface contract.
//
// Ownership: Member B maintains this file; Members A, C and D review the
// connections to their modules. Keep game, cursor, score and drawing logic
// inside the modules below. Do not add a second copy of their state here.
//
// Common conventions (see EE2026_TicTacToe_TeamPlan.md, section 4):
//   clk_6p25m        : one 6.25 MHz clock for all game and OLED modules
//   rst              : active-high, synchronous game reset from Member A
//   board[2*i +: 2] : cell i, 00 empty / 01 X / 10 O; i = 0..8
//   current_player   : 0 X / 1 O
//   winner           : 00 none / 01 X / 10 O; draw is separate
//   score_x/score_o  : two-digit BCD, [7:4] tens and [3:0] ones
//   *_req, *_pulse,
//   round_start/done : one clk_6p25m cycle each
//
module My_Top_Module (
    // Basys 3 inputs. Only SW0 and SW15 are used.
    input  wire        clk100mhz,
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnC,
    input  wire [15:0] sw,

    // Basys 3 LEDs and four-digit seven-segment display.
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp,

    // Pmod OLEDrgb. Map these seven ports to the chosen Pmod socket in XDC.
    output wire        pmodoledrgb_cs,
    output wire        pmodoledrgb_sdin,
    output wire        pmodoledrgb_sclk,
    output wire        pmodoledrgb_d_cn,
    output wire        pmodoledrgb_resn,
    output wire        pmodoledrgb_vccen,
    output wire        pmodoledrgb_pmoden
);

    // Member D: clock generation and OLED display.
    wire        clk_6p25m;
    wire [12:0] pixel_index;
    wire [15:0] oled_data;

    // Member A: reset, cursor and input events.
    wire        rst;
    wire [3:0]  cursor_cell;
    wire        place_req;
    wire        new_round_req;

    // Member B: the only owner of board and round state.
    wire [17:0] board;
    wire        current_player;
    wire        game_over;
    wire        move_ok_pulse;     // Available for simulation/debug.
    wire        move_error_pulse;
    wire        round_start;
    wire        round_done;

    // Member C: combinational result and registered cumulative scores.
    wire [1:0]  winner;
    wire        draw;
    wire [8:0]  winning_mask;
    wire [7:0]  score_x;
    wire [7:0]  score_o;

    // The 100 MHz board clock enters only the clock generator. Member D must
    // implement this using appropriate FPGA clock resources and constraints.
    clock_gen u_clock_gen (
        .clk100mhz (clk100mhz),
        .clk       (clk_6p25m)
    );

    // SW15 is synchronised by Member A. It must assert rst at startup and
    // whenever SW15 is ON; the clock generator must keep running during reset.
    input_controller u_input_controller (
        .clk           (clk_6p25m),
        .btnU          (btnU),
        .btnD          (btnD),
        .btnL          (btnL),
        .btnR          (btnR),
        .btnC          (btnC),
        .sw0_async     (sw[0]),
        .sw15_async    (sw[15]),
        .game_over     (game_over),
        .round_start   (round_start),
        .rst           (rst),
        .cursor_cell   (cursor_cell),
        .place_req     (place_req),
        .new_round_req (new_round_req)
    );

    // Member B writes the board on a valid move. On the following clock edge,
    // B reads Member C's result for the updated board and decides whether to
    // switch players or issue one round_done pulse.
    game_core u_game_core (
        .clk              (clk_6p25m),
        .rst              (rst),
        .cursor_cell      (cursor_cell),
        .place_req        (place_req),
        .new_round_req    (new_round_req),
        .winner           (winner),
        .draw             (draw),
        .board            (board),
        .current_player   (current_player),
        .game_over        (game_over),
        .move_ok_pulse    (move_ok_pulse),
        .move_error_pulse (move_error_pulse),
        .round_start      (round_start),
        .round_done       (round_done)
    );

    // Member C reads the board, reports the result to B and D, and increments
    // the winning score only on B's one-cycle round_done event.
    result_score_controller u_result_score_controller (
        .clk            (clk_6p25m),
        .rst            (rst),
        .board          (board),
        .current_player (current_player),
        .game_over      (game_over),
        .round_done     (round_done),
        .winner         (winner),
        .draw           (draw),
        .winning_mask   (winning_mask),
        .score_x        (score_x),
        .score_o        (score_o),
        .led            (led),
        .seg            (seg),
        .an             (an),
        .dp             (dp)
    );

    // Member D converts the current pixel index and read-only game state into
    // one RGB565 pixel. It does not alter the board, cursor or score.
    oled_renderer u_oled_renderer (
        .clk              (clk_6p25m),
        .rst              (rst),
        .pixel_index      (pixel_index),
        .cursor_cell      (cursor_cell),
        .board            (board),
        .current_player   (current_player),
        .game_over        (game_over),
        .move_error_pulse (move_error_pulse),
        .winner           (winner),
        .draw             (draw),
        .winning_mask     (winning_mask),
        .score_x          (score_x),
        .score_o          (score_o),
        .oled_data        (oled_data)
    );

    // Course-supplied OLED driver. Member D must add Oled_Display.v to Vivado
    // and verify these port names against that exact supplied source file.
    // The status outputs are intentionally unused by this design.
    Oled_Display u_oled_display (
        .clk                 (clk_6p25m),
        .reset               (rst),
        .pixel_data          (oled_data),
        .pixel_index         (pixel_index),
        .frame_begin         (),
        .sending_pixels      (),
        .sample_pixel        (),
        .pmodoledrgb_cs      (pmodoledrgb_cs),
        .pmodoledrgb_sdin    (pmodoledrgb_sdin),
        .pmodoledrgb_sclk    (pmodoledrgb_sclk),
        .pmodoledrgb_d_cn    (pmodoledrgb_d_cn),
        .pmodoledrgb_resn    (pmodoledrgb_resn),
        .pmodoledrgb_vccen   (pmodoledrgb_vccen),
        .pmodoledrgb_pmoden  (pmodoledrgb_pmoden)
    );

endmodule

`default_nettype wire
