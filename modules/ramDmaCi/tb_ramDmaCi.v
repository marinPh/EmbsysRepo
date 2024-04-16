`timescale 1ps/1ps
module ramDmaCiTestBench;

/* set the time-units for simulation */



  reg reset, clock;
  initial 
    begin
      reset = 1'b1;
      clock = 1'b0;                 /* set the initial values */
      repeat (4) #5 clock = ~clock; /* generate 2 clock periods */
      reset = 1'b0;                 /* de-activate the reset */
      forever #5 clock = ~clock;    /* generate a clock with a period of 10 time-units */
    end
  
 
    reg start;
    reg [31:0] valueA;
    reg [31:0] valueB;
    reg [7:0] customId;
    reg [7:0] ciN;

    ramDmaCi #(8'h01 ) DUT
         (.clock(clock),
          .reset(reset),
          .start(start),
          .valueA(valueA),
          .valueB(valueB),
          
          .ciN(ciN));
  
  initial
    begin
      $dumpfile("fifoSignals.vcd"); /* define the name of the .vcd file that can be viewed by GTKWAVE */
      $dumpvars(1,DUT);             /* dump all signals inside the DUT-component in the .vcd file */
    end

  initial
    begin

        start = 1'b0;
        valueA = 32'd0;
        valueB = 32'd0;

        @(negedge reset);            /* wait for the reset period to end */
        repeat(2) @(negedge clock);  /* wait for 2 clock cycles */
        start = 1'b1;
        valueA = 32'h100;
        valueB = 32'hFF;
        ciN = 8'd1;
        repeat(1) @(negedge clock);

        valueA = 32'h000;
        valueB = 32'h00;
        ciN = 8'd0;

        repeat(1) @(negedge clock);

        ciN = 8'd1;

        valueA = 32'h000;
        valueB = 32'h00;
        repeat(1) @(negedge clock);

        ciN = 8'd0;

        valueA = 32'h000;
        valueB = 32'h00;

        repeat(1) @(negedge clock);
        








      
      $finish;                     /* finish the simulation */
    end

endmodule

