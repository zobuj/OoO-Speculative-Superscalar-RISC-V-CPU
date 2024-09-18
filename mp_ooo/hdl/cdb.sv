module cdb
import rv32i_types::*;
// #(parameter P_REG_DEPTH = 5, R_REG_DEPTH = , ROB_BIT_DEPTH = 6)
(  
    // input   FU_entry_t                  FU_in[4],
    input   logic                       flush,
    input   logic                       mult_done,
    input   logic                       div_done,
    input   FU_entry_t                  FU_in,
    input   FU_entry_t                  mult_FU_in,
    input   mem_entry_t                 lsq_in,
    // input   logic                       issue_mult,
    // output  cdb_entry_t                 cdb_out[4],
    input   branch_entry_t              br_in,
    output  cdb_entry_t                 cdb_out,
    output  logic                       FU_en,
    output  logic                       arith_cdb_sent,
    output  logic                       lsq_cdb_sent,
    output  logic                       mult_cdb_sent,
    output  logic                       br_cdb_sent
    // output  logic       [3:0]           check

);

    always_comb begin
        FU_en = 1'b1;
        // cdb_out = 'x;
        // cdb_out[0] = 'x;
        // cdb_out[1] = 'x;
        // cdb_out[2] = 'x;
        // cdb_out[3] = 'x;

        cdb_out.pd = '0;
        cdb_out.rd = '0;
        cdb_out.result = 'x;
        cdb_out.RAT_we = '0;
        cdb_out.RRAT_we = 'x;
        cdb_out.rob_index = 'x;
        cdb_out.CDB_regf_we = '0;
        cdb_out.valid = '0;

        mult_cdb_sent = 1'b0;
        lsq_cdb_sent = 1'b0;
        br_cdb_sent = 1'b0;
        cdb_out.rvfi_mon = '0;
        arith_cdb_sent = 1'b0;
        cdb_out.jump = 1'b0;
        cdb_out.flush = 1'b0;

        if(flush) begin
            cdb_out.pd = '0;
            cdb_out.rd = '0;
            cdb_out.result = 'x;
            cdb_out.RAT_we = '0;
            cdb_out.RRAT_we = 'x;
            cdb_out.rob_index = 'x;
            cdb_out.CDB_regf_we = '0;
            cdb_out.valid = '0;

            mult_cdb_sent = 1'b0;
            lsq_cdb_sent = 1'b0;
            br_cdb_sent = 1'b0;
            cdb_out.rvfi_mon = '0;
            arith_cdb_sent = 1'b0;
            cdb_out.jump = 1'b0;
            cdb_out.flush = 1'b0;            

        end else if(br_in.rename_data.valid) begin
            br_cdb_sent = 1'b1;
            arith_cdb_sent = 1'b0;
            mult_cdb_sent = 1'b0;
            lsq_cdb_sent = 1'b0;
            cdb_out.pd = br_in.rename_data.pd;
            cdb_out.rd = br_in.rename_data.rd;
            cdb_out.result = br_in.result;
            cdb_out.flush = br_in.flush;
            cdb_out.jump = 1'b1;
            cdb_out.RAT_we = 1'b1;
            cdb_out.RRAT_we = 1'b1;
            cdb_out.rob_index = br_in.rename_data.rob_entry;
            cdb_out.CDB_regf_we = (br_in.rename_data.book_keeping.aluop == alu_jal || br_in.rename_data.book_keeping.aluop == alu_jalr) ? 1'b1 : 1'b0;
            cdb_out.valid = br_in.rename_data.valid;
            cdb_out.rvfi_mon = br_in.rename_data.rvfi_mon;
        end
        else if(lsq_in.rename_data.valid) begin
            arith_cdb_sent = 1'b0;
            mult_cdb_sent = 1'b0;
            lsq_cdb_sent = 1'b1;
            cdb_out.pd = lsq_in.rename_data.pd;
            cdb_out.rd = lsq_in.rename_data.rd;
            cdb_out.result = lsq_in.result;
            cdb_out.jump = 1'b0;
            cdb_out.RAT_we = 1'b1;
            cdb_out.RRAT_we = 1'b1;
            cdb_out.rob_index = lsq_in.rename_data.rob_entry;
            cdb_out.CDB_regf_we = lsq_in.rename_data.book_keeping.is_load ? 1'b1 : 1'b0;
            cdb_out.valid = lsq_in.rename_data.valid;
            cdb_out.rvfi_mon = lsq_in.rename_data.rvfi_mon;

        end else if(mult_FU_in.misc.valid && mult_done || mult_FU_in.misc.valid && div_done) begin
            mult_cdb_sent = 1'b1;
            arith_cdb_sent = 1'b0;
            cdb_out.pd = mult_FU_in.misc.pd;
            cdb_out.rd = mult_FU_in.misc.rd;
            cdb_out.result = mult_FU_in.result;
            cdb_out.jump = 1'b0;
            cdb_out.RAT_we = 1'b1;
            cdb_out.RRAT_we = 1'b1;
            cdb_out.rob_index = mult_FU_in.misc.rob_index;
            cdb_out.CDB_regf_we = 1'b1;
            cdb_out.valid = mult_FU_in.misc.valid;
            cdb_out.rvfi_mon = mult_FU_in.rvfi_mon;
        end else if(FU_in.misc.valid) begin
            mult_cdb_sent = 1'b0;
            arith_cdb_sent = 1'b1;
            cdb_out.pd = FU_in.misc.pd;
            cdb_out.rd = FU_in.misc.rd;
            cdb_out.result = FU_in.result;
            cdb_out.RAT_we = 1'b1;
            cdb_out.jump = 1'b0;
            cdb_out.RRAT_we = 1'b1;
            cdb_out.rob_index = FU_in.misc.rob_index;
            cdb_out.CDB_regf_we = 1'b1;
            cdb_out.valid = FU_in.misc.valid;
            cdb_out.rvfi_mon = FU_in.rvfi_mon;
        end

        // if((mult_FU_in.misc.valid && mult_done) && FU_in.misc.valid && lsq_in.rename_data.valid) begin
        //     arith_cdb_sent = 1'b0;
        //     mult_cdb_sent = 1'b0;
        //     lsq_cdb_sent = 1'b1;

        //     cdb_out.pd = lsq_in.rename_data.pd;
        //     cdb_out.rd = lsq_in.rename_data.rd;
        //     cdb_out.result = lsq_in.result;
        //     cdb_out.RAT_we = 1'b1;
        //     cdb_out.RRAT_we = 1'b1;
        //     cdb_out.rob_index = lsq_in.rename_data.rob_entry;
        //     cdb_out.CDB_regf_we = lsq_in.rename_data.book_keeping.is_load ? 1'b1 : 1'b0;
        //     cdb_out.valid = lsq_in.rename_data.valid;
        //     // cdb_out.ps1_value = lsq_in.rename_data.
        //     // cdb_out.ps2_value = lsq_in.rename_data.
        //     cdb_out.rvfi_mon = lsq_in.rename_data.rvfi_mon;

        // end 
        // else if(!(mult_FU_in.misc.valid && mult_done) && FU_in.misc.valid && lsq_in.rename_data.valid) begin
        //     mult_cdb_sent = 1'b0;
        //     arith_cdb_sent = 1'b0;
        //     lsq_cdb_sent = 1'b1;
        //     cdb_out.pd = lsq_in.rename_data.pd;
        //     cdb_out.rd = lsq_in.rename_data.rd;
        //     cdb_out.result = lsq_in.result;
        //     cdb_out.RAT_we = 1'b1;
        //     cdb_out.RRAT_we = 1'b1;
        //     cdb_out.rob_index = lsq_in.rename_data.rob_entry;
        //     cdb_out.CDB_regf_we = lsq_in.rename_data.book_keeping.is_load ? 1'b1 : 1'b0;
        //     cdb_out.valid = lsq_in.rename_data.valid;
        //     // cdb_out.ps1_value = lsq_in.rename_data.
        //     // cdb_out.ps2_value = lsq_in.rename_data.
        //     cdb_out.rvfi_mon = lsq_in.rename_data.rvfi_mon;

        // end
        // else if((mult_FU_in.misc.valid && mult_done) && !FU_in.misc.valid && lsq_in.rename_data.valid) begin
        //     mult_cdb_sent = 1'b0;
        //     arith_cdb_sent = 1'b0;
        //     lsq_cdb_sent = 1'b1;
        //     cdb_out.pd = lsq_in.rename_data.pd;
        //     cdb_out.rd = lsq_in.rename_data.rd;
        //     cdb_out.result = lsq_in.result;
        //     cdb_out.RAT_we = 1'b1;
        //     cdb_out.RRAT_we = 1'b1;
        //     cdb_out.rob_index = lsq_in.rename_data.rob_entry;
        //     cdb_out.CDB_regf_we = lsq_in.rename_data.book_keeping.is_load ? 1'b1 : 1'b0;
        //     cdb_out.valid = lsq_in.rename_data.valid;
        //     // cdb_out.ps1_value = lsq_in.rename_data.
        //     // cdb_out.ps2_value = lsq_in.rename_data.
        //     cdb_out.rvfi_mon = lsq_in.rename_data.rvfi_mon;

        // end
        // else if(!(mult_FU_in.misc.valid && mult_done) && !FU_in.misc.valid && lsq_in.rename_data.valid) begin
        //     mult_cdb_sent = 1'b0;
        //     arith_cdb_sent = 1'b0;
        //     lsq_cdb_sent = 1'b1;
        //     cdb_out.pd = lsq_in.rename_data.pd;
        //     cdb_out.rd = lsq_in.rename_data.rd;
        //     cdb_out.result = lsq_in.result;
        //     cdb_out.RAT_we = 1'b1;
        //     cdb_out.RRAT_we = 1'b1;
        //     cdb_out.rob_index = lsq_in.rename_data.rob_entry;
        //     cdb_out.CDB_regf_we = lsq_in.rename_data.book_keeping.is_load ? 1'b1 : 1'b0;
        //     cdb_out.valid = lsq_in.rename_data.valid;
        //     // cdb_out.ps1_value = lsq_in.rename_data.
        //     // cdb_out.ps2_value = lsq_in.rename_data.
        //     cdb_out.rvfi_mon = lsq_in.rename_data.rvfi_mon;

        // end
        // else if((mult_FU_in.misc.valid && mult_done) && FU_in.misc.valid && !lsq_in.rename_data.valid) begin
        //     mult_cdb_sent = 1'b1;
        //     arith_cdb_sent = 1'b0;
        //     cdb_out.pd = mult_FU_in.misc.pd;
        //     cdb_out.rd = mult_FU_in.misc.rd;
        //     cdb_out.result = mult_FU_in.result;
        //     cdb_out.RAT_we = 1'b1;
        //     cdb_out.RRAT_we = 1'b1;
        //     cdb_out.rob_index = mult_FU_in.misc.rob_index;
        //     cdb_out.CDB_regf_we = 1'b1;
        //     cdb_out.valid = mult_FU_in.misc.valid;
        //     // cdb_out.ps1_value =mult_FU_in.misc.ps1_value; 
        //     // cdb_out.ps2_value =mult_FU_in.misc.ps2_value; 
        //     cdb_out.rvfi_mon = mult_FU_in.rvfi_mon;

        // end else if((mult_FU_in.misc.valid && mult_done) && !FU_in.misc.valid && !lsq_in.rename_data.valid) begin
        //     mult_cdb_sent = 1'b1;
        //     arith_cdb_sent = 1'b0;
        //     cdb_out.pd = mult_FU_in.misc.pd;
        //     cdb_out.rd = mult_FU_in.misc.rd;
        //     cdb_out.result = mult_FU_in.result;
        //     cdb_out.RAT_we = 1'b1;
        //     cdb_out.RRAT_we = 1'b1;
        //     cdb_out.rob_index = mult_FU_in.misc.rob_index;
        //     cdb_out.CDB_regf_we = 1'b1;
        //     cdb_out.valid = mult_FU_in.misc.valid;
        //     // cdb_out.ps1_value =mult_FU_in.misc.ps1_value; 
        //     // cdb_out.ps2_value =mult_FU_in.misc.ps2_value; 
        //     cdb_out.rvfi_mon = mult_FU_in.rvfi_mon;
            
        // end else if(!(mult_FU_in.misc.valid && mult_done) && FU_in.misc.valid && !lsq_in.rename_data.valid) begin
        //     mult_cdb_sent = 1'b0;
        //     arith_cdb_sent = 1'b1;
        //     cdb_out.pd = FU_in.misc.pd;
        //     cdb_out.rd = FU_in.misc.rd;
        //     cdb_out.result = FU_in.result;
        //     cdb_out.RAT_we = 1'b1;
        //     cdb_out.RRAT_we = 1'b1;
        //     cdb_out.rob_index = FU_in.misc.rob_index;
        //     cdb_out.CDB_regf_we = 1'b1;
        //     cdb_out.valid = FU_in.misc.valid;
        //     // cdb_out.ps1_value =FU_in.misc.ps1_value; 
        //     // cdb_out.ps2_value =FU_in.misc.ps2_value; 
        //     cdb_out.rvfi_mon = FU_in.rvfi_mon;
        // end




    end




endmodule