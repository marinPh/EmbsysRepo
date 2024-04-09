
module ramDmaCi #(parameter[7:0] customId = 8'h00)
                (input wire start,
                            clock,
                            reset,
                input wire [31:0] valueA,
                                    valueB,
                input wire [ 7 : 0 ] ciN,
                output wire [31:0] result,
                output wire done);

 // declare an array of 32 bit words of depth 512

reg [31:0] ram [511:0];

reg started;
 reg almost_done;


reg [31:0] data_out;

always @(posedge clock)
begin
    done <= 0;
  if (reset)
  begin
    started <= 0;
    done <= 0;
    data_out <= 0;
    almost_done <= 0;
    for (int i = 0; i < 512; i++)
    begin
        ram[i] <= 0;
    end
  end
  else
    begin
        if (start)
        begin
        started = 1;
        end
        if (started & (ciN == customId) & (valueA[31:10] == 0))
        begin
           //we check if 9th bit is 1 or 0
            if (valueA[8] == 1'b1)
            begin
                //if 9th bit is 1, we write valueB to ram[valueA[31:10]]
                //address is from 31 to 10 including
                ram[valueA[9:0]] = valueB;
                almost_done = 0;
                done = 1;
            end
            else
            begin
                //if 9th bit is 0, we read value from ram and write it to result
                done = almost_done;
                almost_done = 1;
                
                result = data_out;
                data_out = ram[valueA[9:0]];
            end
        end
        
    end
  
end

endmodule



