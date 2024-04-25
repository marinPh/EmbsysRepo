module tb_new;

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
    wire [31:0] address_data;
    wire [3:0] BE;
    wire bus_request;
    wire begin_transaction;
    wire data_valid;
    wire busy;
    wire end_transaction;
    wire slave_busy;
    wire in_valid;
    reg bus_aquire =0;
    reg [31:0] in_data;

  
  
  newDMA #(8'd12 ) DUT (
        .start(start),
        .clock(clock),
        .reset(reset),
        .bus_error(bus_error),
        .bus_aquire(bus_aquire),
        .in_valid(in_valid),
        .slave_busy(slave_busy),
        .in_end(end_transaction),
        .in_begin(begin_transaction),
        .valueA(valueA),
        .valueB(valueB),
        .in_data(in_data),
        .ciN(ciN),
        .address_data(address_data),
        .BE(BE),
        .bus_request(bus_request),
        .begin_transaction(begin_transaction),
        .data_valid(data_valid),
        .busy(busy),
        .end_transaction(end_transaction)
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
        #100;
        $finish;
    end

endmodule
