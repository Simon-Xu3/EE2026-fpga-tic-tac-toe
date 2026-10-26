module score_counter(input clk, input rst, input round_done,
 input [1:0] winner, output reg [7:0] score_x,
 output reg [7:0] score_o);

always@(posedge clk) begin
    if(rst) begin
        score_x<=8'h00;
        score_o<=8'h00;
    end
    else if(round_done) begin
        if(winner==2'b01) begin
            if(score_x==8'h99)
            score_x<=8'h99;
            else if(score_x[3:0]==4'd9) begin
                score_x[3:0]<=4'd0;
                score_x[7:4]<=score_x[7:4]+4'd1;
            end
            else begin
                score_x[3:0]<=score_x[3:0]+4'd1;
            end
        end
        else if(winner==2'b10) begin
            if(score_o==8'h99)
            score_o<=8'h99;
            else if(score_o[3:0]==4'd9) begin
                score_o[3:0]<=4'd0;
                score_o[7:4]<=score_o[7:4]+4'd1;
            end
            else begin
                score_o[3:0]<=score_o[3:0]+4'd1;
            end
        end else begin
        end
    end

end

endmodule