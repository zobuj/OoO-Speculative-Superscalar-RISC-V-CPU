module agu
import rv32i_types::*;
(
    input   logic           is_mem_op,
    input   logic   [31:0]  a, 
    input   logic   [31:0]  b,
    output  logic   [31:0]  f
);

    // logic signed   [31:0] as;
    // logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu;
    

    // assign as =   signed'(a);
    // assign bs =   signed'(b);
    assign au = unsigned'(a);
    assign bu = unsigned'(b);

    always_comb begin
        if(is_mem_op)begin
            f = au +  bu;
        end else begin
            f = 'x;
        end
       
    end

endmodule : agu