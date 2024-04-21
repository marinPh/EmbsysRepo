module rgb565GrayscaleIse #(parameter [7 : 0] customId = 8'h0)
    (input wire start,
    input wire [31:0] valueA,
    input wire [7:0] iseId,
    output wire done,
    output reg [31:0] result);

    //output = (54 * red + 183 * green + 19 * blue) / 256, or >> 8
    wire [31:0] s_result;

    wire s_isMyCi = (iseId == customId) ? start : 1'b0;
    
    wire [6:0] R = {valueA[15:11], 1'b0};
    wire [6:0] G = valueA[10:5];
    wire [6:0] B = {valueA[4:0], 1'b0};

    wire [15:0] Rmult;
    wire [15:0] Gmult;
    wire [15:0] Bmult;

    //54 = 110110 - 4 values
    //183 = 10110111 - 6 values
    //19 = 10011 - 3 values

    assign Rmult = (R << 1) + (R << 2) + (R << 4) + (R << 5);
    assign Gmult = (G << 1) + (G << 2) + (G << 4) + (G << 5);
    assign Bmult = B + (B << 1) + (B << 4) + G;
    assign s_result = Rmult + Gmult + (G<<7) + Bmult;
    
    always @*
    if (s_isMyCi == 1'b0) result <= 32'h0;
    else result <= s_result[15:6];
    
    //assign result = (s_isMyCi == 1'b1) ? s_result[15:8] : 32'h0;
        
    assign done = s_isMyCi;//(iseId == customId && start == 1'b1) ? 1'b1 : 1'b0;
endmodule