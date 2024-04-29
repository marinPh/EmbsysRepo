module DmaCTLCI #(parameter[7:0] customId = 8'h00)
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
                wire [31:0] newA;
                reg aquired;
                wire gtg;
initial begin
    start_address_bus = 0;
    start_address_mem = 0;
    burst_size = 0;
    control_reg = 0;
    block_size = 0;
end
assign gtg = status_reg & aquired & (started == 1) & (ciN == customId);
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
        
        if(bus_aquire == 1) begin
            aquired <= 1;
        end
        if(status_reg == 0 && control_reg ==1 && aquired == 1) begin
            $display("status reg set");
            status_reg =1;
            writing = control_reg[0];
            control_reg = 0;
        end
        if(status_reg == 1)begin
            if (burst_counter < block_size) begin
                r_done = 0;
            end
            else begin
                aquired = 0;
                status_reg = 0;
                r_done = 1;
            end
        end
        $display("valueA[12:10] %b", valueA[12:10]);
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
            // check if 10th to 12th bit is equal to 
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
assign bus_request = (status_reg == 0 && control_reg == 1 ) ? 1 : 0;
assign end_transaction = (bus_error == 1) ? 1 : 0;
assign burst_reset = ((status_reg == 1 && burst_counter == block_size)|| reset == 1) ? 1 : 0;

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

  counter #(8) BurstCounter
         (.reset(burst_reset),
          .clock(clock),
          .enable(gtg & in_valid & !slave_busy),
          .direction(1'b1),
          .counterValue(burst_counter));
endmodule