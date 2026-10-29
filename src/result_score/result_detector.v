module result_detector(input [17:0] board, output [1:0] winner,
 output draw, output reg [8:0] winning_mask);


wire [1:0] b0=board[1:0];
wire [1:0] b1=board[3:2];
wire [1:0] b2=board[5:4];
wire [1:0] b3=board[7:6];
wire [1:0] b4=board[9:8];
wire [1:0] b5=board[11:10];
wire [1:0] b6=board[13:12];
wire [1:0] b7=board[15:14];
wire [1:0] b8=board[17:16];

wire [8:0] bX;
assign bX={(b8==2'b01), (b7==2'b01), (b6==2'b01), (b5==2'b01),
 (b4==2'b01), (b3==2'b01), (b2==2'b01), (b1==2'b01), (b0==2'b01)};
wire [8:0] bO;
assign bO={(b8==2'b10), (b7==2'b10), (b6==2'b10), (b5==2'b10),
 (b4==2'b10), (b3==2'b10), (b2==2'b10), (b1==2'b10), (b0==2'b10)};

wire Xwin =
    (bX[2:0] == 3'b111) || 
    (bX[5:3] == 3'b111) || 
    (bX[8:6] == 3'b111) || 
    ({bX[6], bX[3], bX[0]} == 3'b111) ||
    ({bX[7], bX[4], bX[1]} == 3'b111) ||
    ({bX[8], bX[5], bX[2]} == 3'b111) ||
    ({bX[8], bX[4], bX[0]} == 3'b111) ||
    ({bX[6], bX[4], bX[2]} == 3'b111);

wire Owin =
    (bO[2:0] == 3'b111) ||
    (bO[5:3] == 3'b111) ||
    (bO[8:6] == 3'b111) ||
    ({bO[6], bO[3], bO[0]} == 3'b111) ||
    ({bO[7], bO[4], bO[1]} == 3'b111) ||
    ({bO[8], bO[5], bO[2]} == 3'b111) ||
    ({bO[8], bO[4], bO[0]} == 3'b111) ||
    ({bO[6], bO[4], bO[2]} == 3'b111);

assign winner=Xwin? 2'b01 : Owin? 2'b10 : 2'b00;
assign draw = (winner == 2'b00) &&
              (b0 != 2'b00) && (b1 != 2'b00) && (b2 != 2'b00) &&
              (b3 != 2'b00) && (b4 != 2'b00) && (b5 != 2'b00) &&
              (b6 != 2'b00) && (b7 != 2'b00) && (b8 != 2'b00);


always @* begin
    winning_mask=9'b000000000;

    if (Xwin) begin
        if ((bX & 9'b000000111)==9'b000000111)
            winning_mask=winning_mask | 9'b000000111;
        if ((bX & 9'b000111000)==9'b000111000)
            winning_mask=winning_mask | 9'b000111000;
        if ((bX & 9'b111000000)==9'b111000000)
            winning_mask=winning_mask | 9'b111000000;
        if ((bX & 9'b001001001)==9'b001001001)
            winning_mask=winning_mask | 9'b001001001;
        if ((bX & 9'b010010010)==9'b010010010)
            winning_mask=winning_mask | 9'b010010010;
        if ((bX & 9'b100100100)==9'b100100100)
            winning_mask=winning_mask | 9'b100100100;
        if ((bX & 9'b100010001)==9'b100010001)
            winning_mask=winning_mask | 9'b100010001;
        if ((bX & 9'b001010100)==9'b001010100)
            winning_mask=winning_mask | 9'b001010100;
    end
    else if (Owin) begin
        if ((bO & 9'b000000111)==9'b000000111)
            winning_mask=winning_mask | 9'b000000111;
        if ((bO & 9'b000111000)==9'b000111000)
            winning_mask=winning_mask | 9'b000111000;
        if ((bO & 9'b111000000)==9'b111000000)
            winning_mask=winning_mask | 9'b111000000;
        if ((bO & 9'b001001001)==9'b001001001)
            winning_mask=winning_mask | 9'b001001001;
        if ((bO & 9'b010010010)==9'b010010010)
            winning_mask=winning_mask | 9'b010010010;
        if ((bO & 9'b100100100)==9'b100100100)
            winning_mask=winning_mask | 9'b100100100;
        if ((bO & 9'b100010001)==9'b100010001)
            winning_mask=winning_mask | 9'b100010001;
        if ((bO & 9'b001010100)==9'b001010100)
            winning_mask=winning_mask | 9'b001010100;
    end
end
endmodule

