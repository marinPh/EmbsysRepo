module tb_dmaController;

    // Parameters
    localparam CLOCK_PERIOD = 10; // Clock period in simulation time units

    // Signals
    reg clock = 0;
    reg reset = 0;
    reg start = 0;

    reg bus_error = 0;
    reg [31:0] valueA;
    reg [31:0] valueB;
    reg [7:0] ciN = 0;
    wire [31:0] result;
    wire done;
    wire request;
    wire end_transaction;
    reg slave_busy =0;
    wire begin_transaction;
    reg bus_aquire =0;
    wire in_valid;
    reg end_transaction_reg =0;
    reg data_valid =1;

    // Instantiate the DMA Controller
    ramDmaCi #(8'd12 ) DUT  (.clock(clock),
          .reset(reset),
          .ciStart(start),
          .ciN(ciN),
          .ciValueA(valueA),
          .ciValueB(valueB),
          .ciDone(done),
          .ciResult(),
          .requestTransaction(request),
          .transactionGranted(bus_aquire),
          .beginTransactionIn(),
          .endTransactionIn(end_transaction_reg),
          .readNotWriteIn(),
          .dataValidIn(data_valid),
          .addressDataIn(),
          .busyIn(1'b0),
          .byteEnablesIn(),
          .burstSizeIn(),
          .readNotWriteOut(),
          .busErrorIn(bus_error),
          .startTransactionOutReg(),
          .burstSizeOut(),
          .addressDataOut(),
          .byteEnablesOut(),
          .endTransactionReg(),
          .burstSizeOut()
          );


    initial
        begin
          $dumpfile("fifoSignals.vcd"); /* define the name of the .vcd file that can be viewed by GTKWAVE */
          $dumpvars(1,DUT);             /* dump all signals inside the DUT-component in the .vcd file */
        end

    // Clock generation
    always #((CLOCK_PERIOD / 2)) clock = ~clock;

    // Test stimulus
    initial begin
        // Reset the DMA controller
        reset = 1;
        #10;
        reset = 0;

        //test case 1 set block size to 1
        start = 1;
        ciN = 8'd12;
        #10


        valueA = 32'hE00;
        valueB = 32'h15;

        #10
        //burst size 5

        valueA = 32'h1200;
        valueB = 32'h5;


        
        $display("memOp: %d", valueA[31:10]);

        #10
        //set control_reg to 2
        valueA = 32'h1700;
        valueB = 32'h2;
        #10
        valueA = 32'h000;
        valueB = 32'h0;
        bus_aquire = 1;
        #10
        start = 0;

       

        // Finish simulation
        #300;
        $finish;
    end

endmodule