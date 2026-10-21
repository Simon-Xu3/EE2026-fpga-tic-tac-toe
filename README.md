# EE2026 FPGA Tic Tac Toe

A local two-player Tic Tac Toe game for one Basys 3 board and a 96×64 Pmod OLEDrgb. The directional buttons move the cursor; the centre button places the current player's mark. SW0 requests the next round after a result, and SW15 resets the game and scores.

## Repository layout

| Path | Purpose | Owner |
| --- | --- | --- |
| `src/top/My_Top_Module.v` | Shared top-level wiring and module interface contract | Member B; reviewed by all |
| `src/input/` | Button events, reset and cursor | Member A |
| `src/game/` | Board and turn controller | Member B |
| `src/result_score/` | Result detection, scores, LEDs and seven-segment display | Member C |
| `src/display/` | Clock, OLED renderer and course-supplied OLED driver | Member D |
| `sim/` | Testbenches and display test patterns; simulation only | Each module owner |
| `constraints/` | Basys 3 pin and clock constraints | Member D |
| `docs/` | [Team plan](docs/EE2026_TicTacToe_TeamPlan.md), [project manual](<docs/EE2026 - Project Manual.pdf>) and images | Team |

The top module is present. The component modules, testbenches, course `Oled_Display.v`, and `Basys3_Master.xdc` still need to be added by their owners. This repository does not yet contain a complete bitstream or a buildable Vivado project.

## Before implementing a module

Use the named ports and signal widths in [`src/top/My_Top_Module.v`](src/top/My_Top_Module.v) as the integration contract. The team plan defines cell encoding, reset behaviour, one-cycle events and module responsibilities. Agree on any interface change before editing the top module or dependent modules.

When the sources are ready, add the files in `src/` as Vivado design sources, add `constraints/Basys3_Master.xdc` as a constraint source, and add `sim/` files as simulation sources. Set `My_Top_Module` as the synthesis top. Member D should check the exact ports of the supplied OLED driver and map the chosen Pmod socket in the XDC.

Each member can develop and test their component in parallel. Keep generated Vivado output out of Git; `.gitignore` covers the common generated directories and logs.
