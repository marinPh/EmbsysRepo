`timescale 1ps/1ps

module counterTestBench;

  reg clock,reset, enable, s_direction;
  
  always #5 clock = ~clock;
  initial
    begin
      // Initialize inputs
      clock = 0;
      reset = 0;
      enable = 0;
      s_direction = 1;
      #5
      // Apply reset

      #10
      reset = 1;
      #10
      reset = 0;
      #10
      enable = 1;
      #30
      $finish;
      
    end
  

  wire [7:0] s_value;
  counter #(.WIDTH(8)) dut 
    ( .reset(reset),
      .clock(clock),
      .enable(enable),
      .direction(s_direction),
      .counterValue(s_value));

  
      
  
  initial
    begin
      $dumpfile("counterSignals.vcd");
      $dumpvars(1,dut);
    end
endmodule
