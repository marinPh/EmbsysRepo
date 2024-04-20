//ram module adapted from course and CS-476 forum
module dualPortSSRAM #( parameter bitwidth = 32,
                        parameter nrOfEntries = 512)
                      ( input wire                             clockA, clockB,
                                                               writeEnableA, writeEnableB,
                        input wire [$clog2(nrOfEntries)-1 : 0] addressA, addressB,
                        input wire [bitwidth-1 : 0]            dataInA, dataInB,
                        output reg [bitwidth-1 : 0]            dataOutA, dataOutB);
  
  reg [bitwidth-1 : 0] memoryContent [nrOfEntries-1 : 0];
  
  always @(posedge clockA)
    begin
      if (writeEnableA == 1'b1) memoryContent[addressA] = dataInA;
      dataOutA = memoryContent[addressA];
    end

  always @(posedge clockB)
    begin
      if (writeEnableB == 1'b1) memoryContent[addressB] = dataInB;
      dataOutB = memoryContent[addressB];
    end

endmodule


module ramDmaCi #(parameter[7:0] customInstructionId = 8'h00)
                (input wire start,
                            clock,
                            reset,
                input wire [31:0]   valueA,
                                    valueB,
                input wire [7:0]    iseId,
                output wire [31:0]  result,
                output wire done);

wire s_isMyIse = (iseId == customInstructionId) ? start : 1'b0;
wire writeEnableCPU = valueA[9];
wire [8:0] addressCPU = valueA[8:0];
wire [31:0] dataOutCPU;

dualPortSSRAM #(16'd32, 16'd512 ) ram
        (.clockA(clock),
        .writeEnableA(writeEnableCPU),
        .addressA(addressCPU),
        .dataInA(valueB),
        .dataOutA(dataOutCPU));
//cpu interface

reg started;
reg finish_next_cc;

integer i;

/*always @(posedge clock)
begin
    if (reset)
    begin
        //started <= 0;
        reading <= 0;
        data_out <= 32'hFFFFFFFF;
        finish_next_cc <= 0;
        for (i = 0; i < 512; i = i + 1)
        begin
            ram[i] <= 32'hDEADBEEF;
        end
    end
    else if(s_isMyIse && start) //&& valueA[31:9] == 0)
    begin
        if (writeEnable == 1'b1)
            ram[address] = valueB;

    end
    //we "always" read
    data_out = ram[address];

    //if (almost_done == 1'b1 && (start == 1'b0 || s_isMyIse == 1'b0))
    //    almost_done <= 1'b0;
end

always @(negedge clock)
begin
    finish_next_cc = s_isMyIse & started;
end*/


assign done = (s_isMyIse & writeEnableCPU) | finish_next_cc;//(s_isMyIse == 1'b1) ? writeEnableCPU : finish_next_cc;
//we don't output the read value to result if it's a write
assign result = finish_next_cc ? dataOutCPU : 32'd0;

always @(posedge clock)
begin
  if(s_isMyIse)
  begin
    if(!writeEnableCPU)
      finish_next_cc <= 1'b1;
  end
  else
    finish_next_cc <= 1'b0;
end
endmodule



