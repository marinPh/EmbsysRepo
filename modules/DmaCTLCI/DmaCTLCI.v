module ramDmaCi #(parameter[7:0] customId = 8'h00)
                (input wire start,
                            clock,
                            reset,
                            bus_error,
                            slave_dataValid,
                            bus_aquire,
                input wire [31:0] valueA,
                                    valueB,
                input wire [ 7 : 0 ] ciN,
                output wire [31:0] result,
                output wire data_valid);
               reg [31:0]delayed_valueB;
               reg [8:0]start_address_bus;
                reg [8:0]start_address_mem;
                reg [7:0]burst_size;
                reg [7:0]burst_counter;
                reg [1:0]control_reg;
                reg [1:0]status_reg;
                reg [9:0]block_size;
                reg started;
                reg r_result;
                reg r_done;
                reg writing;
                reg burst_reset;
                reg block_reset;
                reg data_valid;
                wire [31:0] newA;
                reg aquired;

                wire gtg;

initial begin
    start_address_bus = 0;
    start_address_mem = 0;
    burst_size = 0;
    burst_counter = 0;
    control_reg = 0;
    block_size = 0;
end

assign gtg = status_reg & aquired & (started == 1) & (ciN == customId);


always @(posedge clock) begin

//if bus error is 1, set burst_reset to 1
if (bus_error == 1'b1) begin
    burst_reset <= 1;
    status_reg = status_reg | 2;
    r_done <= 0;
end
else begin
    burst_reset <= 0;
    r_done <= 1;
end

//if reset is 1, reset all values
if (reset == 1'b1)
begin
    start_address_bus <= 0;
    start_address_mem <= 0;
    burst_size <= 0;
    burst_counter <= 0;
    control_reg <= 0;
    block_size <= 0;
    started <= 0;
    burst_reset <= 0;
end
else begin
if (start == 1'b1) begin
    started <= 1;
end

if (started == 1 && ciN == customId) begin
if(bus_aquire == 1) begin
    aquired <= 1;
end
    if(status_reg == 0 && control_reg ==1) begin
    status_reg <=1;
    burst_reset <=0;
    control_reg <= 0;
    writing <= control_reg[0];
    end
    if(status_reg ==1)begin
    if (burst_counter < block_size) begin
        r_result <= valueB;
        r_done <= 0;
    end
    else begin
        burst_reset <= 1;
    end
    end
    // check if 10th to 12th bit is equal to 1
    if (valueA[12:10] == 3'b001) begin
        //now check if 9th bit is 1 or 0  and status reg is 0
        if (valueA[9] == 1'b1 && status_reg == 0 ) begin
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
        if (valueA[9] == 1'b1 && status_reg == 0) begin
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
        if (valueA[9] == 1'b1 && status_reg == 0) begin
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
        if (valueA[9] == 1'b1 && status_reg == 0) begin
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
            control_reg = valueA[7:0];
            r_done = 1;
        end
        else begin
            //if 9th is 0 read from control_reg
            r_result = status_reg;
            r_done = 1;
        end
    end
end
end
end

always @(negedge clock)
begin
    delayed_valueB <= valueB;
end

//2 different valueAs 1 for reading one by one, 1 for burst reading
//9th bit is the reg writing bit
assign newA = (burst_counter == 0) ? valueA : (valueA[8:0] + burst_counter ) | writing << 9;
assign data_valid = r_done;
assign result = r_result;


// init ramModule
  ramDmaCi #( customId ) DUT
           (.clock(clock),
            .reset(reset),
            .start(start),
            .valueA(newA),
            .valueB(delayed_valueB),
            .ciN(ciN),
            .result(r_result),
            .done(r_done));

  counter #(8) BurstCounter
         (.reset(burst_reset),
          .clock(clock),
          .enable(gtg),
          .direction(1),
          .counterValue(burst_counter));
endmodule