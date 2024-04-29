module newDMA #(parameter[7:0] customId = 8'h00)
                (input wire start,
                            clock,
                            reset,
                            bus_error,
                            bus_aquire,
                            in_valid,
                            slave_busy,
                            in_end,
                            in_begin,
                input wire [31:0] valueA,
                                    valueB,
                                    in_data,
                input wire [ 7 : 0 ] ciN,
                output wire [31:0] address_data,
                output wire [7:0] w_burst_size,
                output wire [3:0] BE,
                output wire bus_request,
                begin_transaction,
                 data_valid,busy,
                 end_transaction);
                 reg [31:0] r_result;
               reg [31:0]delayed_valueB;
               reg [8:0]start_address_bus;
                reg [8:0]start_address_mem;
                reg [7:0]burst_size;
                wire [7:0]burst_counter;
                wire [7:0]block_counter;
                reg [1:0]control_reg;
                reg [1:0]status_reg;
                reg [9:0]block_size;
                reg started;
                reg r_done;
                wire w_done;
                wire [31:0] w_result;
                reg writing;
                wire burst_reset;
                reg [2:0]state;
                reg r_request;
                wire [31:0] newA;
                reg aquired;
                wire enable_counters;
initial begin
    start_address_bus = 0;
    start_address_mem = 0;
    burst_size = 0;
    control_reg = 0;
    block_size = 0;
    state = 0;
end

always @(posedge clock) begin
//if bus error is 1, set burst_reset to 1

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
                $display("control_reg > 0");
                state <= 1;
                writing <= control_reg[0];
    
                
            end
            else begin
            case(valueA[12:10])
                3'b001 :begin 
                    
                    if (valueA[9] == 1'b1 ) begin
                      //if 9th is 1 write valueB to start_address_bus
                      $display("writing to start_address_bus %d", valueB);


                        start_address_bus <= valueB[8:0];
                        r_done = 1;
                    end
                    else begin
                        $display("reading from start_address_bus %d", start_address_bus);
                        //if 9th is 0 read from start_address_bus
                        r_result <= start_address_bus;
                        r_done = 1;
                    end
                end

                3'b010: begin
                    //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1 ) begin
                        $display("writing to start_address_mem %d", valueB);
                        //if 9th is 1 write valueB to start_address_mem
                        start_address_mem <= valueB[8:0];
                        r_done = 1;
                    end
                    else begin
                        $display("reading from start_address_mem %d", start_address_mem);
                        //if 9th is 0 read from start_address_mem
                        r_result <= start_address_mem;
                        r_done = 1;
                    end
                end
                3'b011: begin
              
                 //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1) begin
                        //if 9th is 1 write valueB to block_size
                        $display("writing to block_size %d", valueB);
                        block_size <= valueB[9:0];
                        r_done = 1;
                    end
                    else begin
                    
                        //if 9th is 0 read from burst_size
                        $display("reading from block_size %d", block_size);
                        r_result <= block_size;
                        r_done = 1;
                    end

                end
                3'b100: begin
                    //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1 ) begin
                        $display("writing to burst_size %d", valueB);
                        //if 9th is 1 write valueB to burst_size
                        burst_size <= valueB[7:0];
                        r_done = 1;
                    end
                    else begin
                        $display("reading from burst_size %d", burst_size);
                        //if 9th is 0 read from burst_size
                        r_result <= burst_size;
                        r_done = 1;
                    end
                end
                3'b101: begin
                  
                    //check if 9th bit is 1 or 0
                    if (valueA[9] == 1'b1 ) begin
                        $display("writing to control_reg %d", valueB);
                        //if 9th is 1 write valueB to control_reg
                        control_reg <= valueB[1:0];
                        r_done = 1;
                    end
                    else begin
                        $display("reading from status_reg %d", control_reg);
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
                state <= 3;
                aquired <= 1;
     
            end
        end
        //now we are in transaction state
        //transaction state is where we are reading or writing to the bus
        2: begin
            //TODO: need to understand better bus error and how to handle it
           
            //if burst_counter is equal to block_size, we reset the burst_counter and go to idle
            if(bus_error ==1) begin
                //TODO: handle bus error
                status_reg <= 2;
                state <= 0;
            end
            else if (block_counter == block_size ) begin
                $display("block_counter == block_size, %d %d", block_counter, block_size);

                state <= 0;
                control_reg <= 0;
                status_reg <= 0;
            end
            else if(burst_counter == burst_size+1 || in_end==1) begin
                state = 1;
                status_reg <= 0;
        
            end
        end
        3: begin
            state <= 2;
        end
        endcase
        end
    end
end

always @(negedge clock)
    delayed_valueB <= dividedB;
//2 different valueAs 1 for reading one by one, 1 for burst reading
//9th bit is the reg writing bit
//if state = 0 then valueB else in_data
assign dividedB = (state == 0) ? valueB : in_data;
assign block_reset = (state == 0) ? 1 : 0;
assign burst_reset = (state != 2) ? 1 : 0;
assign newA = (state == 0) ? valueA : (state == 2) ? (writing == 1) ? start_address_bus + block_counter : start_address_mem + block_counter: 0;
//if status reg is 1 or valueA[12:10] is 0, set data_valid to w_done, rest is r_done
assign data_valid = (state == 2  && writing==0)? 1'b1 : 1'b0;
//enable counters if we are state 2 and writing is 1 and slave_busy ==0 or state2 writing is 0 and data_valid is 1
assign enable_counters = ((state == 2 && writing && !slave_busy ) || (state == 2 && !writing && in_valid==1))? 1 : 0;
// if state == 3 address, if state == 2 w_result else 0
assign address_data =  (state == 3) ? (writing==1) ? start_address_bus:start_address_mem : (state == 2) ? w_result :(state == 0) ? r_result : 0;
assign bus_request = (state == 1 ) ? 1 : 0;
assign end_transaction = (state == 2 && (burst_counter == burst_size +1 || block_counter == block_size || bus_error ==1)) ? 1 : 0;
assign begin_transaction = (state == 3) ? 1 : 0;
//w_burst_size is burst_size when begin transaction is 1 else 0
assign w_burst_size = (state ==3) ? burst_size : 0;
assign read_n_write = (state == 3 && writing == 0) ? 1 : 0;
assign BE = 4'hF;
assign busy = 0;

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
          .enable(enable_counters),
          .direction(1'b1),
          .counterValue(block_counter));

  counter #(8) BurstCounter
         (.reset(burst_reset),
          .clock(clock),
          .enable(enable_counters),
          .direction(1'b1),
          .counterValue(burst_counter));
endmodule