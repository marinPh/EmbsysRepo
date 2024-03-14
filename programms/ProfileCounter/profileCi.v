module profileCi #(
    parameter [7:0] customId = 8'h00
) (
    input wire start,
    clock,
    reset,
    stall,
    busIdle,
    input wire [31:0] valueA,
    valueB,
    input wire [7:0] ciN,
    output wire done,
    output wire [31:0] result
);


  // Define enabling inputs
  //TODO: IDK if start is an impulse or a level signal

  wire enable_0, enable_1, enable_2, enable_3, customGood,reset_0,reset_1,reset_2,reset_3;
  assign direction = 1'b1;

  assign done = costumGood;

  // Outputs
  reg [31:0] counterValue_0, counterValue_1, counterValue_2, counterValue_3;

  assign costumGood = ((ciN == customId) ? 1'b1 : 1'b0) & start;

  assign enable_0   = costumGood & (valueB[0] == 1'b0 && valueB[8]==0'b0);
  assign enable_1   = costumGood & (valueB[1] == 1'b0 && valueB[9]==0'b0) & stall;
  assign enable_2   = costumGood & (valueB[2] == 1'b0 && valueB[10]==0'b0) & busIdle;
  assign enable_3   = costumGood & (valueB[3] == 1'b0 && valueB[11]==0'b0);

    assign reset_0    = costumGood & (valueB[4] == 1'b0 && valueB[12]==0'b0);

  ;








  // Instantiate counters
  counter #(
      .WIDTH(32)
  ) counter_0 (
      .reset(reset),
      .clock(clock),
      .enable(enable_0),
      .direction(direction),
      .counterValue(counterValue_0)
  );

  counter #(
      .WIDTH(32)
  ) counter_1 (
      .reset(reset),
      .clock(clock),
      .enable(enable_1),
      .direction(direction),
      .counterValue(counterValue_1)
  );

  counter #(
      .WIDTH(32)
  ) counter_2 (
      .reset(reset),
      .clock(clock),
      .enable(enable_2),
      .direction(direction),
      .counterValue(counterValue_2)
  );

  counter #(
      .WIDTH(32)
  ) counter_3 (
      .reset(reset),
      .clock(clock),
      .enable(enable_3),
      .direction(direction),
      .counterValue(counterValue_3)
  );

    // Output we use a multiplexer to select the correct counter value to assign to result
    // The counter to be selected is based on the value of valueA[1:0] and costumGood
    // if costumGood is 0, the result is 0
    // if costumGood is 1, the result is the value of the counter selected by valueA[1:0]
    assign result = (costumGood == 1'b1) ? 
                    (valueA[1:0] == 2'b00) ? counterValue_0 :
                    (valueA[1:0] == 2'b01) ? counterValue_1 :
                    (valueA[1:0] == 2'b10) ? counterValue_2 :
                    (valueA[1:0] == 2'b11) ? counterValue_3 :
                    32'b0 : 32'b0;
endmodule




