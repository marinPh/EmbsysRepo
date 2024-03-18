module profileCi #(
    parameter [7:0] customId = 8'h17
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

  //wire reset_0, reset_1, reset_2, reset_3;
  // Outputs
  wire [31:0] counterValue_0, counterValue_1, counterValue_2, counterValue_3;
  reg pot_0, pot_1, pot_2, pot_3;
  //wire enable_0, enable_1, enable_2, enable_3;

  wire reset_0 = ((ciN == customId) & (valueB[8])) | reset;
  wire reset_1 = ((ciN == customId) & (valueB[9])) | reset;
  wire reset_2 = ((ciN == customId) & (valueB[10])) | reset;
  wire reset_3 = ((ciN == customId) & (valueB[11])) | reset;

  reg started;
  /*always @(posedge start) begin
    
    started <= 1'b1;
  end*/

  always @(posedge clock) begin
    if (start) begin
      started = 1'b1;
    end
    
    if (reset == 1'b1) begin
      started = 0;
        pot_0 = 0;
        pot_1 = 0;
        pot_2 = 0;
        pot_3 = 0;
    end

    //check for impulses of valueB[0-7]
    if ((ciN == customId) && (started | start)) begin
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

    wire enable_0 = pot_0;
    wire enable_1 = pot_1 & stall;
    wire enable_2 = pot_2 & busIdle;
    wire enable_3 = pot_3;

    // Define the direction of the counter
    
    wire direction = 1'b1;
  
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
      .reset(reset_1),
      .clock(clock),
      .enable(enable_1),
      .direction(direction),
      .counterValue(counterValue_1)
  );

  counter #(
      .WIDTH(32)
  ) counter_2 (
      .reset(reset_2),
      .clock(clock),
      .enable(enable_2),
      .direction(direction),
      .counterValue(counterValue_2)
  );

  counter #(
      .WIDTH(32)
  ) counter_3 (
      .reset(reset_3),
      .clock(clock),
      .enable(enable_3),
      .direction(direction),
      .counterValue(counterValue_3)
  );
  // Output we use a multiplexer to select the correct counter value to assign to result
  // The counter to be selected is based on the value of valueA[1:0] and costumGood
  // if costumGood is 0, the result is 0
  // if costumGood is 1, the result is the value of the counter selected by valueA[1:0]
  assign result = (ciN == customId && ((started == 1'b1)|| start)) ? 
                    (valueA[1:0] == 2'b00) ? counterValue_0 :
                    (valueA[1:0] == 2'b01) ? counterValue_1 :
                    (valueA[1:0] == 2'b10) ? counterValue_2 :
                    (valueA[1:0] == 2'b11) ? counterValue_3 :
                    32'h0 : 32'h0;

assign done = (ciN == customId && started == 1'b1) ? 1'b1 : 1'b0;

endmodule




