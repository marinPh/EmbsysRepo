module ramDmaCi #(parameter[7:0] customId = 8'h00)
                (input wire start,
                            clock,
                            reset,
                input wire [31:0] valueA,
                                    valueB,
                input wire [ 7 : 0 ] ciN,
                output wire [31:0] result,
                output wire done);


               reg [31:0]delayed_valueB;
               reg [8:0]start_address_bus;
                reg [8:0]start_address_mem;
                reg [7:0]burst_size;
                reg [7:0]burst_counter;
                //control reg
                reg [1:0]control_reg;
                reg [1:0]status_reg;
                reg [9:0]block_size;
                reg started;
                reg r_result;
                reg r_done;

                reg data_valid;
                reg wanted_data;

initial begin
    start_address_bus = 0;
    start_address_mem = 0;
    burst_size = 0;
    burst_counter = 0;
    control_reg = 0;
    block_size = 0;
end


always @(posedge clock) begin
if (reset == 1'b1)
begin

    start_address_bus <= 0;
    start_address_mem <= 0;
    burst_size <= 0;
    burst_counter <= 0;
    control_reg <= 0;
    block_size <= 0;
    started <= 0;
end
else begin
if (start == 1'b1) begin
    started <= 1;
end
if (started == 1 && ciN == customId) begin

    // check if 10th to 12th bit is equal to 1
    if (valueA[12:10] == 3'b001) begin
        //now check if 9th bit is 1 or 0
        if (valueA[9] == 1'b1) begin
          //if 9th is 1 write valueB to start_address_bus
            start_address_bus <= valueA[31:10];
            r_done <= 1;
        end
        else begin
            //if 9th is 0 read from start_address_bus
            r_result <= start_address_bus;
            r_done <= 1;
        end
    end
    //check if 10th to 12th bit is equal to 2
    else if (valueA[12:10] == 3'b010) begin
        //check if 9th bit is 1 or 0
        if (valueA[9] == 1'b1) begin
            //if 9th is 1 write valueB to start_address_mem
            start_address_mem <= valueA[8:10];
            r_done <= 1;
        end
        else begin
            //if 9th is 0 read from start_address_mem
            r_result <= start_address_mem;
            r_done <= 1;
        end
    end

    //check if 10th to 12th bit is equal to 3
    else if (valueA[12:10] == 3'b011) begin
        //check if 9th bit is 1 or 0
        if (valueA[9] == 1'b1) begin
            //if 9th is 1 write valueB to block_size
            block_size <= valueA[9:0];
            r_done <= 1;
        end
        else begin
            //if 9th is 0 read from burst_size
            r_result <= block_size;
            r_done <= 1;
        end
    end

    //check if 10th to 12th bit is equal to 4
    else if (valueA[12:10] == 3'b100) begin
        //check if 9th bit is 1 or 0
        if (valueA[9] == 1'b1) begin
            //if 9th is 1 write valueB to burst_size
            burst_size <= valueA[7:0];
            r_done <= 1;
        end
        else begin
            //if 9th is 0 read from burst_size
            r_result <= burst_size;
            r_done <= 1;
        end
    end

    //check if 10th to 12th bit is equal to 5
    else if (valueA[12:10] == 3'b101) begin
        //check if 9th bit is 1 or 0
        if (valueA[9] == 1'b1) begin
         // if 9th is 1 write valueB to control_reg
            control_reg <= valueA[7:0];
            r_done <= 1;
        end
        else begin
            //if 9th is 0 read from control_reg
            r_result <= status_reg;
            r_done <= 1;

        end
    end
end
end
end

always @(negedge clock)
begin
    delayed_valueB <= valueB;
end
// init ramModule
  ramDmaCi #( customId ) DUT
           (.clock(clock),
            .reset(reset),
            .start(start),
            .valueA(valueA),
            .valueB(delayed_valueB),
            .ciN(ciN),
            .result(wanted_data),
            .done(wanted_data));

  counter #(8) counterBurstCounter
         (.reset(reset),
          .clock(clock),
          .enable(started),
          .direction(control_reg[0]),
          .counterValue(burst_counter));


    counter #(8) counterBlockCounter
            (.reset(reset),
            .clock(clock),
            .enable(started),
            .direction(control_reg[1]),
            .counterValue(block_size));


// init


endmodule