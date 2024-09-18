module rat
import rv32i_types::*;
// #(parameter NUM_PHYS_REG = 64, PHYS_REG_IDX = 5)
(
    //ASSUME WE HAVE 64 PHYSICAL REGISTERS FOR NOW
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we,
    input   logic   [4:0]   rs1_s, 
    input   logic   [4:0]   rs2_s,
    input   logic   [4:0]   rd_s, 
    input   logic   [4:0]   rob_rd, 
    input   logic   [5:0]   pd_s,
    input   logic   [5:0]   rob_pd,
    input   logic           update_rat,
    input   cdb_entry_t     cdb_entry,
    input   logic   [5:0]   rrat_mapping [32],
    input   logic           flush, 
    output  logic   [5:0]   ps1_s, 
    output  logic   [5:0]   ps2_s,
    output  logic           ps1_valid, 
    output  logic           ps2_valid
);
    logic   [5:0]   arc_reg       [32];
    logic           arc_reg_valid [32];
    logic           CDB_signal; 
    
    always_ff @(posedge clk) begin
        if (rst) begin
            // for (logic  [5:0] i = 6'b0; i < 6'd32; i = i + 1'b1)  begin
            //     arc_reg[i] <=  i; //initially map 1:1 to physical index 
            //     arc_reg_valid[i] <= '1; //RAT initially valid/available 
            // end

            arc_reg[0] <= 6'd0;
            arc_reg[1] <= 6'd1;
            arc_reg[2] <= 6'd2;
            arc_reg[3] <= 6'd3;
            arc_reg[4] <= 6'd4;
            arc_reg[5] <= 6'd5;
            arc_reg[6] <= 6'd6;
            arc_reg[7] <= 6'd7;
            arc_reg[8] <= 6'd8;
            arc_reg[9] <= 6'd9;
            arc_reg[10] <= 6'd10;
            arc_reg[11] <= 6'd11;
            arc_reg[12] <= 6'd12;
            arc_reg[13] <= 6'd13;
            arc_reg[14] <= 6'd14;
            arc_reg[15] <= 6'd15;
            arc_reg[16] <= 6'd16;
            arc_reg[17] <= 6'd17;
            arc_reg[18] <= 6'd18;
            arc_reg[19] <= 6'd19;
            arc_reg[20] <= 6'd20;
            arc_reg[21] <= 6'd21;
            arc_reg[22] <= 6'd22;
            arc_reg[23] <= 6'd23;
            arc_reg[24] <= 6'd24;
            arc_reg[25] <= 6'd25;
            arc_reg[26] <= 6'd26;
            arc_reg[27] <= 6'd27;
            arc_reg[28] <= 6'd28;
            arc_reg[29] <= 6'd29;
            arc_reg[30] <= 6'd30;
            arc_reg[31] <= 6'd31;

            arc_reg_valid[0] <= 1'b1;
            arc_reg_valid[1] <= 1'b1;
            arc_reg_valid[2] <= 1'b1;
            arc_reg_valid[3] <= 1'b1;
            arc_reg_valid[4] <= 1'b1;
            arc_reg_valid[5] <= 1'b1;
            arc_reg_valid[6] <= 1'b1;
            arc_reg_valid[7] <= 1'b1;
            arc_reg_valid[8] <= 1'b1;
            arc_reg_valid[9] <= 1'b1;
            arc_reg_valid[10] <= 1'b1;
            arc_reg_valid[11] <= 1'b1;
            arc_reg_valid[12] <= 1'b1;
            arc_reg_valid[13] <= 1'b1;
            arc_reg_valid[14] <= 1'b1;
            arc_reg_valid[15] <= 1'b1;
            arc_reg_valid[16] <= 1'b1;
            arc_reg_valid[17] <= 1'b1;
            arc_reg_valid[18] <= 1'b1;
            arc_reg_valid[19] <= 1'b1;
            arc_reg_valid[20] <= 1'b1;
            arc_reg_valid[21] <= 1'b1;
            arc_reg_valid[22] <= 1'b1;
            arc_reg_valid[23] <= 1'b1;
            arc_reg_valid[24] <= 1'b1;
            arc_reg_valid[25] <= 1'b1;
            arc_reg_valid[26] <= 1'b1;
            arc_reg_valid[27] <= 1'b1;
            arc_reg_valid[28] <= 1'b1;
            arc_reg_valid[29] <= 1'b1;
            arc_reg_valid[30] <= 1'b1;
            arc_reg_valid[31] <= 1'b1;

        end else begin
            // Can we read from both CDB and Dispatch/rename at the same time? 
            //if CDB writes - check if rd == pd (CBD_signal)
            // and set as valid 
            if((cdb_entry.RAT_we && CDB_signal)) begin
                arc_reg_valid[cdb_entry.rd] <= '1; 
            end 
            
            if(regf_we && rd_s != 5'b0) begin // check this
            // if dispatch writes - map arch-reg to phys-reg from rename/dispatch unit 
            // set valid to 0
                arc_reg[rd_s] <= pd_s;
                arc_reg_valid[rd_s] <= '0;
            end 

            if(flush)begin
            arc_reg[0] <= rrat_mapping[0];
            arc_reg[1] <= rrat_mapping[1];
            arc_reg[2] <= rrat_mapping[2];
            arc_reg[3] <= rrat_mapping[3];
            arc_reg[4] <= rrat_mapping[4];
            arc_reg[5] <= rrat_mapping[5];
            arc_reg[6] <= rrat_mapping[6];
            arc_reg[7] <= rrat_mapping[7];
            arc_reg[8] <= rrat_mapping[8];
            arc_reg[9] <= rrat_mapping[9];
            arc_reg[10] <= rrat_mapping[10];
            arc_reg[11] <= rrat_mapping[11];
            arc_reg[12] <= rrat_mapping[12];
            arc_reg[13] <= rrat_mapping[13];
            arc_reg[14] <= rrat_mapping[14];
            arc_reg[15] <= rrat_mapping[15];
            arc_reg[16] <= rrat_mapping[16];
            arc_reg[17] <= rrat_mapping[17];
            arc_reg[18] <= rrat_mapping[18];
            arc_reg[19] <= rrat_mapping[19];
            arc_reg[20] <= rrat_mapping[20];
            arc_reg[21] <= rrat_mapping[21];
            arc_reg[22] <= rrat_mapping[22];
            arc_reg[23] <= rrat_mapping[23];
            arc_reg[24] <= rrat_mapping[24];
            arc_reg[25] <= rrat_mapping[25];
            arc_reg[26] <= rrat_mapping[26];
            arc_reg[27] <= rrat_mapping[27];
            arc_reg[28] <= rrat_mapping[28];
            arc_reg[29] <= rrat_mapping[29];
            arc_reg[30] <= rrat_mapping[30];
            arc_reg[31] <= rrat_mapping[31];

            if(update_rat && rob_rd != 5'd0) begin
                arc_reg[rob_rd] <= rob_pd;
            end

            arc_reg_valid[0] <= 1'b1;
            arc_reg_valid[1] <= 1'b1;
            arc_reg_valid[2] <= 1'b1;
            arc_reg_valid[3] <= 1'b1;
            arc_reg_valid[4] <= 1'b1;
            arc_reg_valid[5] <= 1'b1;
            arc_reg_valid[6] <= 1'b1;
            arc_reg_valid[7] <= 1'b1;
            arc_reg_valid[8] <= 1'b1;
            arc_reg_valid[9] <= 1'b1;
            arc_reg_valid[10] <= 1'b1;
            arc_reg_valid[11] <= 1'b1;
            arc_reg_valid[12] <= 1'b1;
            arc_reg_valid[13] <= 1'b1;
            arc_reg_valid[14] <= 1'b1;
            arc_reg_valid[15] <= 1'b1;
            arc_reg_valid[16] <= 1'b1;
            arc_reg_valid[17] <= 1'b1;
            arc_reg_valid[18] <= 1'b1;
            arc_reg_valid[19] <= 1'b1;
            arc_reg_valid[20] <= 1'b1;
            arc_reg_valid[21] <= 1'b1;
            arc_reg_valid[22] <= 1'b1;
            arc_reg_valid[23] <= 1'b1;
            arc_reg_valid[24] <= 1'b1;
            arc_reg_valid[25] <= 1'b1;
            arc_reg_valid[26] <= 1'b1;
            arc_reg_valid[27] <= 1'b1;
            arc_reg_valid[28] <= 1'b1;
            arc_reg_valid[29] <= 1'b1;
            arc_reg_valid[30] <= 1'b1;
            arc_reg_valid[31] <= 1'b1;

            end

        end
    end

    always_comb begin
        CDB_signal = '0; 
        if (rst) begin
            ps1_s = 'x;
            ps2_s = 'x;
            ps1_valid = 'x;
            ps2_valid = 'x;
        end else begin
            CDB_signal = (cdb_entry.pd == arc_reg[cdb_entry.rd]); 
            
            // ps1_s = (rs1_s != 5'd0) ? arc_reg[rs1_s] : '0;
            // ps2_s = (rs2_s != 5'd0) ? arc_reg[rs2_s] : '0;

            // ps1_valid = (rs1_s != 5'd0) ? arc_reg_valid[rs1_s] : '0;
            // ps2_valid = (rs2_s != 5'd0) ? arc_reg_valid[rs2_s] : '0;
            

            ps1_s = arc_reg[rs1_s];
            ps2_s = arc_reg[rs2_s];

            ps1_valid = (cdb_entry.RAT_we && CDB_signal && cdb_entry.rd == rs1_s) ? 1'b1 : arc_reg_valid[rs1_s];
            ps2_valid = (cdb_entry.RAT_we && CDB_signal && cdb_entry.rd == rs2_s) ? 1'b1 : arc_reg_valid[rs2_s];
            
        end
    end


endmodule