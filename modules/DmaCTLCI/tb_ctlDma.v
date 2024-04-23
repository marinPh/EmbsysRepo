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
    reg [7:0] ciN;
    wire [31:0] result;
    wire done;
    wire request;
    wire end_transaction;
    wire slave_busy;
    wire begin_transaction;
    reg bus_aquire =0;
    wire in_valid;

    // Instantiate the DMA Controller
    DmaCTLCI #(8'd12 ) DUT (
        .clock(clock),
        .reset(reset),
        .start(start),
        .bus_error(bus_error),
        .valueA(valueA),
        .valueB(valueB),
        .ciN(ciN),
        .result(result),
        .data_valid(done),
        .bus_request(request),
        .end_transaction(end_transaction),
        .slave_busy(slave_busy),
        .begin_transaction(begin_transaction),
        .bus_aquire(bus_aquire),
        .in_valid(in_valid)
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

        //test case 1 set burst size to 1
        start = 1;
        #10
        valueA = 32'hC00;
        valueB = 32'h3;
        ciN = 8'd12;

        #10
        start = 0;
        //set control_reg to 1
        valueA = 32'h1700;
        valueB = 32'h1;
        #10
        valueA = 32'h1600;
        valueB = 32'h0;
        bus_aquire = 1;
        #10

       

        // Finish simulation
        #100;
        $finish;
    end

endmodule
