`timescale 1ns / 1ps

module reset_sync (
    input clk,
    input async_reset,
    output reset
);

(* ASYNC_REG = "TRUE" *) reg [2:0] stages = 3'b111;

always @(posedge clk or posedge async_reset) begin
    if (async_reset)
        stages <= 3'b111;
    else
        stages <= {stages[1:0], 1'b0};
end

assign reset = stages[2];

endmodule
