module rgb565GrayscaleIse #(parameter [7 : 0] customId = 8'h0)
    (input wire start,
    input wire [31 : 0] valueA,
    input wire [7 : 0] iseId,
    output wire done,
    output wire [31 : 0] result);

    //output = (54 * red + 183 * green + 19 * blue) / 256, or >> 8
    reg [31 : 0] s_result;

    always @(posedge start) begin
        if (iseId == customId) begin
            s_result = (valueA[15:11] * 54 + valueA[10:5] * 183 + valueA[4:0] * 19) >> 8;
        end
    end

    
    assign result = (iseId == customId && ( start)) ? s_result : 32'b0;
        
    assign done = (iseId == customId && start == 1'b1) ? 1'b1 : 1'b0;
endmodule