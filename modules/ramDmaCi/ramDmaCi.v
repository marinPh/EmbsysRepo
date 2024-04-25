// code adapted using trial and error from modules/delay/verilog/delayIse.v
module ramDmaCi #(  parameter [7:0] customInstructionId = 8'd0 )
                ( input wire         clock,
                                     reset,
                                     ciStart,
                  input wire [7:0]   ciN,
                  input wire [31:0]  ciValueA,
                                     ciValueB,
                  output wire        ciDone,
                  output wire [31:0] ciResult,
                  
                  // here the bus interface is defined
                  output wire        requestTransaction,
                  input wire         transactionGranted,

                  //we still need to read some of the signals
                  input wire         beginTransactionIn,
                                     endTransactionIn,
                                     readNotWriteIn,
                                     dataValidIn,
                                     busErrorIn,
                  input wire [31:0]  addressDataIn,
                  input wire [3:0]   byteEnablesIn,
                  input wire [7:0]   burstSizeIn,

                  //we are the masters, we set the signals
                  output wire        beginTransactionOut,
                                     endTransactionOut,
                                     dataValidOut,
                  output reg         readNotWriteOut,
                  output reg [3:0]   byteEnablesOut,
                  output reg [7:0]   burstSizeOut,
                  output wire [31:0] addressDataOut);

    //cpu interface
    localparam [21:0] OP_MEM = 22'b000, OP_BUS_SA = 22'b001, OP_MEM_SA = 22'b010, OP_BLOCK_SIZE = 22'b011, OP_BURST_SIZE = 22'b100, OP_CONTROL = 22'b101;

    wire isMyCi = (ciN == customInstructionId) ? ciStart : 1'b0;

    //memory and operation
    wire [21:0] memoryOp = ciValueA[31:10];
    wire writeEnableCPU = ciValueA[9];
    wire writeEnableA = writeEnableCPU & isMyCi & (memoryOp == 22'b000);
    wire [31:0] dataOutA;
    wire [8:0] addressCPU = ciValueA[8:0];


    //dma related functionality
    reg [31:0] busStartAddress;
    reg [8:0] memoryStartAddress; //refers to the inner memory of this instruction, not the FPGA's ram
    reg [9:0] blockSize;
    reg [7:0] burstSize;
    reg [1:0] status;

    //write values to operation registers
    always @ (posedge clock) begin
      if (reset) begin
        busStartAddress <= 32'b0;
        memoryStartAddress = 9'b0;
        blockSize = 10'b0;
        burstSize = 8'b0;
      end else if (isMyCi & writeEnableCPU) begin
        busStartAddress <= (memoryOp == OP_BUS_SA) ? ciValueB : busStartAddress;
        memoryStartAddress <= (memoryOp == OP_MEM_SA) ? ciValueB[8:0] : memoryStartAddress;
        blockSize <= (memoryOp == OP_BLOCK_SIZE) ? ciValueB[9:0] : blockSize;
        burstSize <= (memoryOp == OP_BURST_SIZE) ? ciValueB[7:0] : burstSize;
      end
    end

    wire        bufferWe;
    wire [8:0]  bufferAddress;
    wire [31:0] bufferDataIn;
    wire [31:0] bufferDataOut;

    // instatiate the dualPortSSRAM module
    dualPortSSRAM #(.bitwidth(32), .nrOfEntries(512)) ssram 
                    (.clock(clock), .writeEnableA(writeEnableA), .writeEnableB(bufferWe), 
                    .addressA(addressCPU), .addressB(bufferAddress), .dataInA(ciValueB), .dataInB(bufferDataIn), 
                    .dataOutA(dataOutA), .dataOutB(bufferDataOut));
    

    //read values from operation registers
    reg [31:0] dataOutCPU;
    always @*
    case (memoryOp)
      OP_MEM: dataOutCPU = dataOutA;
      OP_BUS_SA: dataOutCPU = busStartAddress;
      OP_MEM_SA: dataOutCPU = memoryStartAddress;
      OP_BLOCK_SIZE: dataOutCPU = blockSize;
      OP_BURST_SIZE: dataOutCPU = burstSize;
      OP_CONTROL: dataOutCPU = status;
      default: dataOutCPU = 32'hEEEEEEEE;
    endcase
    
    wire validReadOp = (memoryOp == OP_MEM || memoryOp == OP_BUS_SA || memoryOp == OP_MEM_SA || memoryOp == OP_BLOCK_SIZE || memoryOp == OP_BURST_SIZE || memoryOp == OP_CONTROL) & ~writeEnableCPU & isMyCi;
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
                                    (validReadOp) ? 32'd1:
                                    (s_delayCountZero == 1'b0) ? s_delayCountReg - 32'd1 : s_delayCountReg;

  /*
   *
   * Here we define the done signal
   *
   */

    assign ciResult = (s_doneReg == 1'b1) ? dataOutCPU : 32'd0;
    wire s_doneNext = ((isMyCi == 1'b1 && ciValueA == 32'd0) || //this valueA here won't be 0 like ever,
                                                                //but if you remove the line it stalls the cpu
                       (s_delayCountOne == 1'b1)) ? 1'b1 : 1'b0;
  
    assign ciDone = s_doneReg | (isMyCi == 1'b1 && writeEnableCPU);
  
    always @(posedge clock)
    begin
      s_delayCountReg <= s_delayCountNext;
      s_doneReg <= s_doneNext;
    end

  /*
   *
   * Here the bus interface is defined
   *
   */
    localparam [3:0] IDLE = 4'd0, REQUEST = 4'd1, INIT = 4'd2, COMPUTE_BURSTSIZE = 4'd3, READ = 4'd4, WRITE = 4'd5, ERROR = 4'd6, TRANSFER_DONE = 4'd7;
    reg [31:0] s_busAddressInReg, s_addressDataOutReg;
    reg [31:0] s_busAddressReg;
    reg [31:0] s_busDataInReg, s_busDataOutReg;
    reg s_dataValidReg;
    reg s_startTransactionReg, s_transactionActiveReg, s_busDataInValidReg, s_readNotWriteReg;
    reg s_endTransactionReg, s_dataValidOutReg, s_startTransactionOutReg, s_writeRegisterReg, s_endTransactionInReg;

    reg [3:0] s_dmaState, s_dmaStateNext;
    reg [8:0] s_burstCountReg;

    always @ (posedge clock)
    begin
        s_busDataInReg          <= (dataValidIn == 1'b1) ? addressDataIn : s_busDataInReg;
        s_busDataInValidReg     <= dataValidIn;
        s_endTransactionInReg   <= endTransactionIn & ~reset;

    end
  /*
   *
   * Here the dma-controller is defined, adapted from modules/hdmi_720p/verilog/graphicsController.v
   *
   */

  reg [8:0] s_bufferAddressReg, nextBufferAddress;
  reg [7:0] nextBurstSize;
  reg [9:0] remainingBlockSize;
  reg [32:0] nextBusAddress;

  wire s_startTransfer = isMyCi & writeEnableCPU & (memoryOp == OP_CONTROL) & (s_dmaState == IDLE);
  
  //assign endTransactionOut   = s_endTransactionReg;
  //assign dataValidOut        = s_dataValidOutReg;
  assign addressDataOut      = s_busDataOutReg;
  assign beginTransactionOut = s_startTransactionOutReg;
  assign requestTransaction = (s_dmaState == REQUEST) ? 1'd1 : 1'd0;
  assign bufferDataIn       = s_busDataInReg;
  assign bufferAddress      = s_bufferAddressReg;
  assign bufferWe           = (s_dmaState == READ) ? s_busDataInValidReg : 1'd0;
  //assign writeIndex         = s_writeIndexReg;

  //state machine description
  always @*
    case (s_dmaState)
      IDLE             : s_dmaStateNext <= (s_startTransfer == 1'b1) ? COMPUTE_BURSTSIZE : IDLE;
      COMPUTE_BURSTSIZE: s_dmaStateNext <= (remainingBlockSize != 9'b0) ? REQUEST : TRANSFER_DONE;
      REQUEST          : s_dmaStateNext <= (transactionGranted == 1'b1) ? INIT : REQUEST;
      INIT             : s_dmaStateNext <= READ;  //todo ad write
      READ             : s_dmaStateNext <= (busErrorIn == 1'b1 && endTransactionIn == 1'b0) ? ERROR :
                                           (busErrorIn == 1'b1) ? IDLE : 
                                           (s_endTransactionInReg == 1'b1) ? COMPUTE_BURSTSIZE : READ;
      ERROR            : s_dmaStateNext <= (s_endTransactionInReg == 1'b1) ? IDLE : ERROR;
      default          : s_dmaStateNext <= IDLE;
    endcase
  
  //advance state machine
  always @(posedge clock)
    begin
      //s_writeIndexReg          <= (reset == 1'd1) ? 1'b0 : (s_dmaState == READ_DONE || (s_dmaState == WRITE_BLACK && s_writeAddressReg[9] == 1'b1)) ? ~s_writeIndexReg : s_writeIndexReg;
      s_dmaState               <= (reset == 1'd1) ? IDLE : s_dmaStateNext;
      remainingBlockSize       <= (reset == 1'd1) ? 10'd0 :
                                  (s_startTransfer == 1'd1) ? blockSize :
                                  (s_dmaState != COMPUTE_BURSTSIZE) ? remainingBlockSize :
                                  (remainingBlockSize > burstSize) ? remainingBlockSize - burstSize - 1 : 10'd0;
      nextBurstSize            <= (reset == 1'd1) ? 8'd0 :
                                  (s_dmaState != COMPUTE_BURSTSIZE) ? nextBurstSize :
                                  (remainingBlockSize > burstSize) ? burstSize : remainingBlockSize[7:0];
      s_bufferAddressReg       <= (reset == 1'd1) ? 9'd0 :
                                  (s_startTransfer == 1'b1) ? memoryStartAddress :
                                  ((s_dmaState == READ) && s_busDataInValidReg == 1'd1) ? s_bufferAddressReg + 9'd1 : s_bufferAddressReg;
      s_busAddressReg          <= (reset == 1'b1) ? 32'd0 :
                                  (s_startTransfer == 1'b1) ? busStartAddress :
                                  (s_busDataInValidReg == 1'b1 && (s_dmaState == READ)) ? s_busAddressReg + 32'd4 : s_busAddressReg;
      s_busDataOutReg          <= (s_dmaState == INIT) ? s_busAddressReg : 32'd0;
      byteEnablesOut           <= (s_dmaState == INIT) ? 4'hF : 4'd0;
      readNotWriteOut          <= (s_dmaState == INIT) ? 1'b1 : 1'b0;
      burstSizeOut             <= (s_dmaState == INIT) ? nextBurstSize : 8'd0;
      s_startTransactionOutReg <= (s_dmaState == INIT) ? 1'b1 : 1'b0;
      status[0]                <= ((s_dmaState == INIT) || (s_dmaState == READ) || (s_dmaState == COMPUTE_BURSTSIZE)) ? 1'b1 : 1'b0;
      status[1]                <= (s_dmaState == INIT) ? 1'b0 :
                                  (s_dmaState == ERROR) ? 1'b1 : status[1];
    end
endmodule
