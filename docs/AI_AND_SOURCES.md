# Member 4 AI and source record, repository adaptation

Owner: Zhao Zeyu, A0311891E. Date: 30 October 2026.

The team project manual and GPT6_S1_05 proposal define the assignment. The user supplied the actual My_Top_Module.v used by the GitHub team. ChatGPT inspected it and adapted the previously generated Member 4 code to its exact clock/render ports, 8-bit BCD scores, member-A reset ownership and seven scalar Pmod outputs.

ChatGPT assisted with the display implementation, testbenches, standalone test-project script, pin constraints, software verification and handoff instructions. It did not modify the supplied top, implement other members' logic, access or change the GitHub repository, or merge any branch.

The course Oled_Display.v is unchanged and retains its original copyright/license notice. Its header attributes adaptation to Joel Holdsworth's project: https://github.com/jhol/otl-icoboard-pmodoledrgb-demo/tree/master/fw/sim . This URL was taken from the provided source header.

Clock primitive documentation checked:
- AMD UG953 MMCME2_BASE: https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/MMCME2_BASE
- AMD UG953 BUFGCE: https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/BUFGCE

Actual checks: static elaboration, port/constraint checks and CXXRTL models compiled from delivered Verilog. 20,959 functional assertions passed. Other team modules were interface-only black boxes for the top contract check; their real functions were not tested. Vivado UNISIM clock simulation, implementation/timing/utilization, physical OLED tests and full team integration remain to be carried out and recorded by the team.

The assignment manual requires documenting AI assistance. Record only tests and hardware observations the team actually completes, and use actual OLED photographs where required.
