module alu
import rv32i_types::*;
(   
    input   logic   clk,
    input   logic   rst,
    input   logic   alu_en,
    input   logic   [4:0]   aluop,
    input   logic   [31:0]  a, 
    input   logic   [31:0]  b,
    input   logic   [31:0]  pc,
    output  logic   [31:0]  f
);

    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu;
    

    assign as =   signed'(a);
    assign bs =   signed'(b);
    assign au = unsigned'(a);
    assign bu = unsigned'(b);

    // always_comb begin
    //     unique case (aluop)
    //         alu_add: f = au +   bu;
    //         alu_sll: f = au <<  bu[4:0];
    //         alu_sra: f = unsigned'(as >>> bu[4:0]);
    //         alu_sub: f = au -   bu;
    //         alu_xor: f = au ^   bu;
    //         alu_srl: f = au >>  bu[4:0];
    //         alu_or:  f = au |   bu;
    //         alu_and: f = au &   bu;
    //         alu_lui: f =  bu;
    //         alu_auipc: f = bu + pc;
    //         alu_slt: f = as < bs ? 32'b1 : 32'b0;
    //         alu_sltu: f = au < bu ? 32'b1 : 32'b0;
    //         alu_slti: f = as < bs ? 32'b1 : 32'b0;
    //         alu_sltiu: f = au < bu ? 32'b1 : 32'b0;
    //         alu_jal: begin
    //             f = pc + 32'b100;
    //             // pc_jal = pc + bu;
    //         end
    //         alu_jalr: begin
    //             f = pc + 32'b100;
    //             // pc_jal =  (au + bu) & 32'hfffffffe;
    //         end   
    //         default: f = 'x;
    //     endcase
    // end

    always_ff @(posedge clk) begin
        if(rst) begin
            f <= 'x;
        end else begin
            if(alu_en) begin
                unique case (aluop)
                    alu_add: f <= au +   bu;
                    alu_sll: f <= au <<  bu[4:0];
                    alu_sra: f <= unsigned'(as >>> bu[4:0]);
                    alu_sub: f <= au -   bu;
                    alu_xor: f <= au ^   bu;
                    alu_srl: f <= au >>  bu[4:0];
                    alu_or:  f <= au |   bu;
                    alu_and: f <= au &   bu;
                    alu_lui: f <=  bu;
                    alu_auipc: f <= bu + pc;
                    alu_slt: f <= as < bs ? 32'b1 : 32'b0;
                    alu_sltu: f <= au < bu ? 32'b1 : 32'b0;
                    alu_slti: f <= as < bs ? 32'b1 : 32'b0;
                    alu_sltiu: f <= au < bu ? 32'b1 : 32'b0;
                    // alu_jal: begin
                    //     f <= pc + 32'b100;
                    //     // pc_jal <= pc + bu;
                    // end
                    // alu_jalr: begin
                    //     f <= pc + 32'b100;
                    //     // pc_jal <=  (au + bu) & 32'hfffffffe;
                    // end   
                    default: f <= 'x;
                endcase
            end else begin
                f <= f;
            end
        end
    end



endmodule : alu