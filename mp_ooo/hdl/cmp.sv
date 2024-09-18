module cmp
import rv32i_types::*;
(
    input   logic           valid,
    input   logic   [2:0]   cmpop,
    input   logic   [31:0]  a, b,
    output  logic           br_en
);

    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu;

    assign as =   signed'(a);
    assign bs =   signed'(b);
    assign au = unsigned'(a);
    assign bu = unsigned'(b);

    // logic dum;
    // assign dum = valid;


    always_comb begin
        br_en = 1'b0;
        if(valid) begin
            unique case (cmpop)
                eq:  br_en = (au == bu);
                ne:  br_en = (au != bu);
                lt:  br_en = (as <  bs);
                ge:  br_en = (as >=  bs);
                ltu: br_en = (au <  bu);
                geu: br_en = (au >=  bu);
                default: br_en = 1'b0;
            endcase
        end
    end

endmodule: cmp
