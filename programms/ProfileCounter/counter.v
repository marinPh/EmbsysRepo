module counter #( parameter WIDTH = 32)
                ( input wire reset,
                             clock,
                             enable,
                             direction, /* a 1 is counting up, a 0 is counting down */
                  output reg [WIDTH-1:0] counterValue);

  always @(posedge clock)begin

    /*counterValue = (reset == 1'b1) ? {WIDTH{1'b0}} : 
                    (enable == 1'b0) ? counterValue :
                    (direction == 1'b1) ? counterValue + 1 : counterValue - 1;*/

    if (reset == 1) begin
      counterValue = {WIDTH{1'b0}};
    end else if (enable == 1) begin
      if (direction == 1) begin
        counterValue = counterValue + 1;
      end else begin
        counterValue = counterValue - 1;
      end
    end
  end
endmodule
