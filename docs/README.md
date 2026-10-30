# Member D display handoff — Zhao Zeyu (A0311891E)

This version matches the uploaded My_Top_Module.v contract, SHA256:
`7e2dd8aded3b796443bb9071671cdcb5680aeec61d80e2e19f2b8f51df87113c`.
The uploaded top was not modified. Review again if the team changes its ports later.

## Final design sources

- src/display/clock_gen.v: ports clk100mhz and clk; MMCM ×8 /128 generates 6.25 MHz, BUFG feedback and BUFGCE output enabled on MMCM lock. No SW15 clock reset.
- src/display/oled_renderer.v: exact ports instantiated by the top; includes the internal oled_pixel_drawer module. Do not separately instantiate that helper.
- src/display/Oled_Display.v: original course driver, unchanged.
- constraints/Basys3_Master.xdc: JA mapping for the top's seven pmodoledrgb_* scalar outputs; clk100mhz at W5. All 57 declared physical port bits have unique pin assignments.

No change is required to My_Top_Module for Member D's public ports. Member A owns rst. Member B owns board/current player/game_over. Member C owns result, BCD scores, LEDs and seven-segment outputs.

## Renderer format

| Input | Format |
| --- | --- |
| clk | Common 6.25 MHz clock |
| rst | Active-high synchronous game reset from member A |
| pixel_index | 13-bit course-driver index |
| cursor_cell | 0–8; outside values hide cursor |
| board | 18 bits; cell i at [2*i +: 2], 00 empty, 01 X, 10 O |
| current_player | 0 X, 1 O |
| game_over | Hides cursor and enables result display |
| move_error_pulse | One-cycle pulse stretched internally to 0.5 s |
| winner / draw / winning_mask | Top contract, unchanged |
| score_x / score_o | 8-bit packed BCD: [7:4] tens, [3:0] ones |

Example: 8'h12 → 12, 8'h34 → 34. Invalid BCD digits defensively display 99; score counting and saturation remain member C's job.

Because the existing top intentionally leaves frame_begin unconnected, the renderer refreshes its read-only snapshot while pixel_index==0 (idle interval and first pixel). Pixel (0,0) is permanently black. It freezes snapshots for the nonzero-index active frame. Both complete serial frame streams and a mid-frame state change were tested. The error timer clears on rst, game_over, or an empty board at a new round.

## Remove superseded files if present

The old oled_controller.v, member4_display_system.v, reset_sync.v and tb_oled_controller.v supplied in the earlier standalone package are superseded for this top. Their responsibilities have been consolidated or remain with member A. Do not mix the old clock/renderer interfaces with these files.

## Testing

Two updated testbenches are in sim/: tb_oled_renderer and tb_clock_gen. The renderer test covers BCD, cursor, win highlights, frame snapshots, invalid-event stretching and reset. The clock test uses real Vivado UNISIM models and waits for lock before measuring 20 periods of 160 ns.

scripts/member4_create_test_project.tcl builds an independent display-only project. It deliberately adds sim/Display_Test_Top.v and sim/display_test_pattern.v as test design sources. They are not the final game top; final synthesis still uses My_Top_Module.

Static and Yosys CXXRTL checks passed (20,959 functional assertions). Interface-only black boxes represented other members in the top contract check; their implementations were not available. No claim is made that full team integration, real clock-primitive simulation or board testing has passed. Complete Vivado simulation, implementation/timing/resource checks and JA OLED hardware validation before final sign-off.

The unchanged course OLED driver transmits indices 0–6142 each frame. Index 6143 is reserved black by the renderer; confirm the physical last pixel after panel clear-screen initialization.
