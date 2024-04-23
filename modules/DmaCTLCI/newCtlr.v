module newDMA #(parameter[7:0] customId = 8'h00)
                (input wire start,
                            clock,
                            reset,
                            bus_error,
                            bus_aquire,
                            in_valid,
                            slave_busy,
                input wire [31:0] valueA,
                                    valueB,
                input wire [ 7 : 0 ] ciN,
                output wire [31:0] result,
                output wire bus_request,
                begin_transaction,
                 data_valid,
                 end_transaction);
               reg [31:0]delayed_valueB;
               reg [8:0]start_address_bus;
                reg [8:0]start_address_mem;
                reg [7:0]burst_size;
                wire [7:0]burst_counter;
                reg [1:0]control_reg;
                reg [1:0]status_reg;
                reg [9:0]block_size;
                reg started;
                reg [31:0]r_result;
                reg r_done;
                wire w_done;
                wire [31:0] w_result;
                reg writing;
                wire burst_reset;
                reg [2:0]state;
                reg r_request;
                wire [31:0] newA;
                reg aquired;
                wire gtg;
initial begin
    start_address_bus = 0;
    start_address_mem = 0;
    burst_size = 0;
    control_reg = 0;
    block_size = 0;
    state = 0;
end
assign gtg = (state == 2) & (started == 1) & (ciN == customId) & (!slave_busy);
always @(posedge clock) begin
//if bus error is 1, set burst_reset to 1
if (bus_error == 1'b1) begin
$display("bus error");
    aquired <= 0;
    status_reg = status_reg | 2;
    r_done <= 0;
end
//if reset is 1, reset all values
if (reset == 1'b1)begin
$display("reset");
    start_address_bus <= 0;
    start_address_mem <= 0;
    burst_size <= 0;
    control_reg <= 0;
    block_size <= 0;
    started <= 0;

    status_reg <= 0;
    aquired <= 0;
    r_result <= 0;
    r_done <= 0;
    writing <= 0;
    delayed_valueB <= 0;
    aquired <= 0;
end
    else begin
    if (start == 1'b1) begin
    $display("start");
        started <= 1;
    end
    if (started == 1 && ciN == customId) begin
        //states, Idle = 0, asking =1, transaction =2, if we are writing and where is done by combination
        //idle is the first state where we are waiting for control>0
        //asking is the state where we are asking for the bus
        //transaction is the state where we are reading or writing

        case(state)
        0: begin
            if (control_reg > 0) begin
                state <= 1;
                writing <= control_reg[0];
                block_reset <= 1;
                
            end
            else begin
            case(valueA[12:10])
                3'b001 :begin 
                    $display("case 1");
                    if (valueA[9] == 1'b1 && status_reg == 0 ) begin
                      //if 9th is 1 write valueB to start_address_bus
                        start_address_bus <= valueB[31:0];
                        r_done = 1;
                    end
                    else begin
                        //if 9th is 0 read from start_address_bus
                        r_result <= start_address_bus;
                        r_done = 1;
                    end
                end

                3'b010: begin
                    $display("case 2");
                    //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1 && status_reg == 0) begin
                        //if 9th is 1 write valueB to start_address_mem
                        start_address_mem <= valueB[8:0];
                        r_done = 1;
                    end
                    else begin
                        //if 9th is 0 read from start_address_mem
                        r_result <= start_address_mem;
                        r_done = 1;
                    end
                end
                3'b011: begin
                    $display("case 3");
                 //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1 && status_reg == 0) begin
                        //if 9th is 1 write valueB to block_size
                        block_size <= valueB[9:0];
                        r_done = 1;
                    end
                    else begin
                    
                        //if 9th is 0 read from burst_size
                        r_result <= block_size;
                        r_done = 1;
                    end

                end
                3'b100: begin
                    $display("case 4");
                    //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1 && status_reg == 2'b0) begin
                
                        //if 9th is 1 write valueB to burst_size
                        burst_size <= valueA[7:0];
                        r_done = 1;
                    end
                    else begin
                        //if 9th is 0 read from burst_size
                        r_result <= burst_size;
                        r_done = 1;
                    end
                end
                3'b101: begin
                    $display("case 5");
                    //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1 && status_reg == 0) begin
                        //if 9th is 1 write valueB to control_reg
                        control_reg <= valueB[1:0];
                        r_done = 1;
                    end
                    else begin
                        //if 9th is 0 read from control_reg
                        r_result <= status_reg;
                        r_done = 1;
                    end
                end
            endcase
            end
        end
        //now we are in asking state we have already requested
        1: begin
            if (bus_aquire == 1) begin
                state <= 2;
                aquired <= 1;
                burst_reset <=0;
            end
        end
        //now we are in transaction state
        //transaction state is where we are reading or writing to the bus
        2: begin
            if (writing == 1) begin
                //if we are writing, we write ram[start_bus_address+blockcounter] = valueB so
                //newA = start_bus_addres + block_counter
                newA = start_address_bus + burst_counter;
            end
            else begin
                //if we are reading, we read from the bus and write to ram[start_mem_address+block_counter]
                //newA = start_mem_address + block_counter
                newA = start_address_mem + burst_counter;
            end
            //if burst_counter is equal to block_size, we reset the burst_counter and go to idle
            if (block_counter == block_size) begin
                state <= 0;
                burst_reset <= 1;
                block_reset <= 1;
                end_transaction <= 1;
            end
            else if(burst_counter == burst_size+1) begin
                state = 1;
                burst_reset <= 1;
                end_transaction <=1;
            end
        end
        endcase
        end
    end
end

always @(negedge clock)
    delayed_valueB <= valueB;
//2 different valueAs 1 for reading one by one, 1 for burst reading
//9th bit is the reg writing bit
assign newA = (burst_counter == 0) ? valueA : (valueA[8:0] + burst_counter ) | writing << 9;
//if status reg is 1 or valueA[12:10] is 0, set data_valid to w_done, rest is r_done

assign data_valid = (status_reg == 1 || valueA[12:10] == 3'b000) ? w_done : r_done;
assign result = (status_reg == 1 || valueA[12:10] == 3'b000) ? w_result : r_result;
assign bus_request = (state == 1 ) ? 1 : 0;

//TODO: find a combination for end_transaction and start transaction





// init ramModule
  ramDmaCi #( customId ) DUT
           (.clock(clock),
            .reset(reset),
            .start(start),
            .valueA(newA),
            .valueB(delayed_valueB),
            .ciN(ciN),
            .result(w_result),
            .done(w_done));


    counter #(8) BlockCounter
         (.reset(block_reset),
          .clock(clock),
          .enable(),
          .direction(1'b1),
          .counterValue(block_counter));

  counter #(8) BurstCounter
         (.reset(burst_reset),
          .clock(clock),
          .enable(),
          .direction(1'b1),
          .counterValue(burst_counter));
endmodule