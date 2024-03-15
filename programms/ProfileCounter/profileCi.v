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

  wire reset_0, reset_1, reset_2, reset_3;
  // Outputs
  wire [31:0] counterValue_0, counterValue_1, counterValue_2, counterValue_3;
  reg pot_0, pot_1, pot_2, pot_3;
  wire enable_0, enable_1, enable_2, enable_3;

  assign reset_0 = (valueB[8] == 1'b1) | reset;
  assign reset_1 = (valueB[9] == 1'b1) | reset;
  assign reset_2 = (valueB[10] == 1'b1) | reset;
  assign reset_3 = (valueB[11] == 1'b1) | reset;

  reg started;

  @always (posedge clock) begin
    if (start == 1) begin
      started = 1;
    end
    if (reset == 1) begin
      started = 0;
      pot_0 = 0;
        pot_1 = 0;
        pot_2 = 0;
        pot_3 = 0;
    end

    //check for impulses of valueB[0-7]
    if (started == 1) begin
      //check if valueB[4-7]
        if (valueB[4] == 1'b1) begin
            pot_0 = 0;
        end else if (valueB[0] == 1'b1) begin
            pot_0 = 1;
        end
        if (valueB[5] == 1'b1) begin
            pot_1 = 0;
        end else if (valueB[1] == 1'b1) begin
            pot_1 = 1;
        end
        if (valueB[6] == 1'b1) begin
            pot_2 = 0;
        end else if (valueB[2] == 1'b1) begin
            pot_2 = 1;
        end
        if (valueB[7] == 1'b1) begin
            pot_3 = 0;
        end else if (valueB[3] == 1'b1) begin
            pot_3 = 1;
        end
    end
  end

  assign enable_0 = pot_0 & started;
    assign enable_1 = pot_1 & started & stall;
    assign enable_2 = pot_2 & started & busIdle;
    assign enable_3 = pot_3 & started;

    // Define the direction of the counter
    wire direction;
    assign direction = 1'b1;

    



  /*assign enable_0   = costumGood & (valueB[0] == 1'b1 && valueB[8] ==1'b0);
  assign enable_1   = costumGood & (valueB[1] == 1'b1 && valueB[9] ==1'b0) & stall;
  assign enable_2   = costumGood & (valueB[2] == 1'b1 && valueB[10]==1'b0) & busIdle;
  assign enable_3   = costumGood & (valueB[3] == 1'b1 && valueB[11]==1'b0);
  assign reset_0    = costumGood & (valueB[4] == 1'b1 && valueB[12]==1'b0) | reset;
  assign reset_1    = costumGood & (valueB[5] == 1'b1 && valueB[13]==1'b0) | reset;
  assign reset_2    = costumGood & (valueB[6] == 1'b1 && valueB[14]==1'b0) | reset;
  assign reset_3    = costumGood & (valueB[7] == 1'b1 && valueB[15]==1'b0) | reset;*/




  // Instantiate counters
  counter #(
      .WIDTH(32)
  ) counter_0 (
      .reset(reset_0),
      .clock(clock),
      .enable(enable_0),
      .direction(direction),
      .counterValue(counterValue_0)
  );

  counter #(
      .WIDTH(32)
  ) counter_1 (
      .reset(reset_0),
      .clock(clock),
      .enable(enable_1),
      .direction(direction),
      .counterValue(counterValue_1)
  );

  counter #(
      .WIDTH(32)
  ) counter_2 (
      .reset(reset_0),
      .clock(clock),
      .enable(enable_2),
      .direction(direction),
      .counterValue(counterValue_2)
  );

  counter #(
      .WIDTH(32)
  ) counter_3 (
      .reset(reset_0),
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




