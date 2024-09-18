module branch_unit
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           flush,
    input   rename_data_t   branch_rename_data_in,
    input   logic   [31:0]  br_ps1_val,
    input   logic   [31:0]  br_ps2_val,    
    output  branch_entry_t  branch_entry_out                             
    // output  logic           flush
);

    logic br_en;

    cmp compare_unit(
        .valid(branch_rename_data_in.valid && branch_rename_data_in.book_keeping.use_cmp),
        .cmpop(branch_rename_data_in.book_keeping.cmpop),
        .a(br_ps1_val), 
        .b(br_ps2_val),
        .br_en(br_en)
    );

    always_ff @(posedge clk) begin
        if(rst) begin
            branch_entry_out <= '0;
        end else begin
            branch_entry_out.rename_data <= branch_rename_data_in;
            branch_entry_out.rename_data.rvfi_mon.rs1_rdata <= br_ps1_val; 
            branch_entry_out.rename_data.rvfi_mon.rs2_rdata <= br_ps2_val; 
            if(branch_rename_data_in.book_keeping.use_cmp) begin
                if(br_en) begin
                    branch_entry_out.pc <= branch_rename_data_in.pc + branch_rename_data_in.immediate;
                    // need to change later for more sophisticated branch predictors
                    branch_entry_out.flush <= 1'b1;
                end else begin
                    branch_entry_out.pc <= '0;
                    branch_entry_out.flush <= 1'b0;
                end
            end else begin
                    if(branch_rename_data_in.book_keeping.aluop == alu_jal) begin
                        // branch_entry_out.pc <= branch_rename_data_in.pc + br_ps2_val;
                        branch_entry_out.pc <= branch_rename_data_in.pc + branch_rename_data_in.immediate;
                        branch_entry_out.result <=  branch_rename_data_in.pc + 32'b100;
                        branch_entry_out.rename_data.rvfi_mon.rd_wdata <= branch_rename_data_in.pc + 32'b100;
                        branch_entry_out.flush <= 1'b1;
                    end
                    else if(branch_rename_data_in.book_keeping.aluop == alu_jalr) begin
                        // branch_entry_out.pc <= (br_ps1_val + br_ps2_val) & 32'hfffffffe;
                        branch_entry_out.pc <= (br_ps1_val + branch_rename_data_in.immediate) & 32'hfffffffe;
                        branch_entry_out.result <=  branch_rename_data_in.pc + 32'b100;
                        branch_entry_out.rename_data.rvfi_mon.rd_wdata <= branch_rename_data_in.pc + 32'b100;
                        branch_entry_out.flush <= 1'b1;
                    end
            end

            if(flush) begin
                branch_entry_out <= '0;
            end
        end
    end

endmodule