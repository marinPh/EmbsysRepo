module profileCi #(parameter [7:0] customId = 8'h00) (
    input wire start,
    clock,
    reset,
    stall,
    input wire [31:0] valueA,
    valueB,
    input wire [7:0] ciN,
    output wire done,
    output wire [31:0] result
);


    reg[0:0] reg_done;
    reg[31:0] reg_result;


 

    