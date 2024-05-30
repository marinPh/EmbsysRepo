module sobel_mult #( parameter[7:0] customId = 8'h18 )
                  ( input wire        start,          
                    input wire [31:0] valueA,
                                      valueB,
                    input wire [7:0]  ciN,
                    output wire       done,
                    output reg [31:0] result );

                //result = valueA if valueB is 1, valueA<<1 if valueB is 2
                //TODO: IDK if i am supposed to wait for 1 cycle by adding a reg to start and in n always to verify
                result = (start & (ciN == customId)) ? (valueB == 8'h01) ? valueA : (valueB == 8'h02) ? valueA << 1 : 32'h00000000 : 32'h00000000;
                done = (ciN == customId) ? start : 1'b0;
  
endmodule
