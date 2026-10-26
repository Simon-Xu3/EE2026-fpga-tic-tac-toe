module sevenseg_driver(input clk, input rst,
 input [7:0] score_x, input [7:0] score_o,
 output reg [6:0] seg, output reg [3:0] an, output reg dp);

reg [12:0] scan_count;
reg [1:0] scan_digit;
reg [3:0] value;

// At 6.25 MHz, 6250 clock cycles are 1 ms.
always @(posedge clk) begin
    if (rst) begin
        scan_count<=13'd0;
        scan_digit<=2'd0;
    end
    else if (scan_count==13'd6249) begin
        scan_count<=13'd0;
        scan_digit<=scan_digit+2'd1;
    end
    else begin
        scan_count<=scan_count+13'd1;
    end
end

// Select one of the four score digits.
// an[3] is the leftmost digit; an[0] is the rightmost.
always @* begin
    an=4'b1111;
    value=4'd0;
    dp=1'b1;                 // Decimal point off (active low)

    if (!rst) begin
        case (scan_digit)
            2'd0: begin an=4'b0111; value=score_x[7:4]; end
            2'd1: begin an=4'b1011; value=score_x[3:0]; end
            2'd2: begin an=4'b1101; value=score_o[7:4]; end
            2'd3: begin an=4'b1110; value=score_o[3:0]; end
        endcase
    end
end

// Basys 3 segments are active low; seg[6:0] = gfedcba.
always @* begin
    if (rst) begin
        seg=7'b1111111;
    end
    else begin
        case (value)
            4'd0: seg=7'b1000000;
            4'd1: seg=7'b1111001;
            4'd2: seg=7'b0100100;
            4'd3: seg=7'b0110000;
            4'd4: seg=7'b0011001;
            4'd5: seg=7'b0010010;
            4'd6: seg=7'b0000010;
            4'd7: seg=7'b1111000;
            4'd8: seg=7'b0000000;
            4'd9: seg=7'b0010000;
            default: seg=7'b1111111;
        endcase
    end
end

endmodule