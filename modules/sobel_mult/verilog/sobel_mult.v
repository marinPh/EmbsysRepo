module sobel_mult #( parameter[7:0] customId = 8'h18 )
                  ( input wire        start,          
                    input wire [31:0] valueA,
                                      valueB,
                    input wire [7:0]  ciN,
                    output wire       done,
                    output reg [31:0] result );

                    wire [31:0] comp_neg;
                    wire [31:0] comp_shifted;
                    assign comp_neg = ~valueA + 1;
                    assign comp_shifted = comp << 1;

                //TODO: IDK if i am supposed to wait for 1 cycle by adding a reg to start and in n always to verify
               

                    assign result = (factor == 3'd2) ? comp_shifted :
                                    (factor == 3'd1) ? comp :
                                    (factor == 3'd0) ? 32'd0 :
                                    (factor == -3'd1) ? comp_neg :
                                    (factor == -3'd2) ? ~comp_shifted + 1 : // -(comp << 1)
                                    32'd0; // default case
                                    
                    done = (ciN == customId) ? start : 1'b0;
  
endmodule
