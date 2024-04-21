// code adapted using trial and error from modules/delay/verilog/delayIse.v
module ramDmaCi #(  parameter [7:0] customInstructionId = 8'd0 )
                ( input wire         clock,
                                     reset,
                                     ciStart,
                  input wire [7:0]   ciN,
                  input wire [31:0]  ciValueA,
                                     ciValueB,
                  output wire        ciDone,
                  output wire [31:0] ciResult);

    wire isMyCi = (ciN == customInstructionId) ? ciStart : 1'b0;

    //memory and operation
    wire [21:0] memoryOp = ciValueA[31:10];
    wire writeEnableCPU = ciValueA[9];
    wire writeEnableA = writeEnableCPU & isMyCi & (memoryOp == 22'b000);
    wire readEnableA = ~writeEnableCPU & isMyCi & (memoryOp == 22'b000);
    wire [8:0] addressCPU = ciValueA[8:0];

    //cpu interface
    wire [31:0] dataOutCPU;

    // instatiate the dualPortSSRAM module
    dualPortSSRAM #(.bitwidth(32), .nrOfEntries(512)) ssram 
                    (.clockA(clock), .clockB(clock), .writeEnableA(writeEnableA), .writeEnableB(), 
                    .addressA(addressCPU), .addressB(), .dataInA(ciValueB), .dataInB(), 
                    .dataOutA(dataOutCPU), .dataOutB());
  /*
   *
   * Here we define the main counter
   *
   */
    reg s_doneReg;
    reg [31:0] s_delayCountReg;
    wire s_delayCountZero = (s_delayCountReg == 32'd0) ? 1'd1 : 1'd0;
    wire s_delayCountOne  = (s_delayCountReg == 32'd1) ? 1'd1 : 1'd0;
    wire [31:0] s_delayCountNext = (reset == 1'b1) ? 32'd0 :
                                    (readEnableA) ? 32'd1: //{9'b0, addressCPU, 14'b0} :
                                    (s_delayCountZero == 1'b0) ? s_delayCountReg - 32'd1 : s_delayCountReg;

    assign ciResult = (s_doneReg == 1'b1) ? dataOutCPU : 32'd0;
  
  /*
   *
   * Here we define the done signal
   *
   */


    wire s_doneNext = ((isMyCi == 1'b1 && ciValueA == 32'd0) || //this valueA here won't be 0 like ever,
                                                                //but if you remove the line it stalls the cpu
                       (s_delayCountOne == 1'b1)) ? 1'b1 : 1'b0;
  
    assign ciDone = s_doneReg | (isMyCi == 1'b1 && writeEnableCPU);
  
    always @(posedge clock)
    begin
      s_delayCountReg <= s_delayCountNext;
      s_doneReg <= s_doneNext;
    end
endmodule
