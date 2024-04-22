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
    wire [31:0] dataOutA;
    wire [8:0] addressCPU = ciValueA[8:0];


    //dma related functionality
    reg [31:0] busStartAddress;
    reg [8:0] memoryStartAddress; //refers to the inner memory of this instruction, not the FPGA's ram
    reg [9:0] blockSize;
    reg [7:0] burstSize;
    reg [1:0] control;

    always @ (posedge clock) begin
      if (reset) begin
        busStartAddress <= 32'b0;
        memoryStartAddress = 9'b0;
        blockSize = 10'b0;
        burstSize = 8'b0;
        control = 2'b0;
      end
    end

    // instatiate the dualPortSSRAM module
    dualPortSSRAM #(.bitwidth(32), .nrOfEntries(512)) ssram 
                    (.clock(clock), .writeEnableA(writeEnableA), .writeEnableB(), 
                    .addressA(addressCPU), .addressB(), .dataInA(ciValueB), .dataInB(), 
                    .dataOutA(dataOutA), .dataOutB());
  /*
   *
   * Here we define the main counter, needed for multiple CC operation
   *
   */
    reg s_doneReg;
    reg [31:0] s_delayCountReg;
    wire s_delayCountZero = (s_delayCountReg == 32'd0) ? 1'd1 : 1'd0;
    wire s_delayCountOne  = (s_delayCountReg == 32'd1) ? 1'd1 : 1'd0;
    wire [31:0] s_delayCountNext = (reset == 1'b1) ? 32'd0 :
                                    (readEnableA) ? 32'd1: //{9'b0, addressCPU, 14'b0} :
                                    (s_delayCountZero == 1'b0) ? s_delayCountReg - 32'd1 : s_delayCountReg;

    //cpu interface
    localparam [21:0] OP_MEM = 22'b000, OP_BUS_SA = 22'b001, OP_MEM_SA = 22'b010, OP_BLOCK_SIZE = 4'b011, OP_BURST_SIZE = 4'b100, OP_CONTROL = 4'b101;

    wire [31:0] dataOutCPU;
    always @*
    case (memoryOp)
      OP_MEM: dataOutCPU = dataOutA;
      OP_BUS_SA: dataOutCPU = busStartAddress;
      OP_MEM_SA: dataOutCPU = memoryStartAddress;
      OP_BLOCK_SIZE: dataOutCPU = blockSize;
      OP_BURST_SIZE: dataOutCPU = burstSize;
      OP_CONTROL: dataOutCPU = control;
      default: dataOutCPU = 32'd0;
    endcase
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
