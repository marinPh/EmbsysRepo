module dualPortSSRAM #( parameter bitwidth = 8,
                        parameter nrOfEntries = 512)
                      ( input wire                             clock,
                                                               writeEnableA, writeEnableB,
                        input wire [$clog2(nrOfEntries)-1 : 0] addressA, addressB,
                        input wire [bitwidth-1 : 0]            dataInA, dataInB,
                        output reg [bitwidth-1 : 0]            dataOutA, dataOutB);
  
  reg [bitwidth-1 : 0] memoryContent [nrOfEntries-1 : 0];
  
  always @(posedge clock)
    begin
      if (writeEnableA == 1'b1) memoryContent[addressA] = dataInA;
      dataOutA = memoryContent[addressA];
    end

  always @(negedge clock)
    begin
      if (writeEnableB == 1'b1) memoryContent[addressB] = dataInB;
      dataOutB = memoryContent[addressB];
    end

endmodule