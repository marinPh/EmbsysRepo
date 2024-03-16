
`timescale 1ps / 1ps

module proTestBench;

  // Parameters
  parameter [7:0] customId = 8'h00;

  // Signals
  reg start, clock, reset, stall, busIdle;
  reg [31:0] valueA;
  reg [31:0] valueB;
  reg [7:0] ciN;
  wire done;
  wire [31:0] result;

  // Instantiate the module
  profileCi #(
      .customId(customId)
  ) dut (
      .start(start),
      .clock(clock),
      .reset(reset),
      .stall(stall),
      .busIdle(busIdle),
      .valueA(valueA),
      .valueB(valueB),
      .ciN(ciN),
      .done(done),
      .result(result)
  );

  // Clock generation
  always #5 clock = ~clock;

  // Initial values
  initial begin
    // Initialize inputs
    start = 0;
    clock = 0;
    reset = 0;
    stall = 0;
    busIdle = 0;
    valueA = 0;
    valueB = 12'b0;
    ciN = 8'h02;

    // Apply reset
    reset = 1;
    #10 reset = 0;

    // Apply some test vectors
    // Set start signal and custom instruction ID
    #5
    start = 1;
    #10
    start = 0;
    valueB = 12'b000000001111;
    #10
    valueB = 12'b000000000000;
    stall = 1;
    busIdle = 1;
    #30
    valueA = 2'b00;
    #10
    valueA = 2'b01;
    #10
    valueA = 2'b10;
    #10
    valueA = 2'b11;
    #10
    valueA = 2'b00;
    #10
    ciN = 8'h00;
    #30

    


    // Add more test vectors as needed

    // End simulation
    $finish;
  end

  initial
    begin
      $dumpfile("counterSignals.vcd");
      $dumpvars(1,dut);
    end


endmodule
