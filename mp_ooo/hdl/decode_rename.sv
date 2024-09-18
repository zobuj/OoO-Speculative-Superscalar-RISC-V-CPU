
module decode_rename 
import rv32i_types::*;
(
    input   logic               rst,
    input   logic               iq_is_empty,
    input   logic               rs_open,
    input   logic               mult_rs_open,
    input   iq_dequeue_rdata_t  iq_dequeue_rdata,
    // input   logic               ps1_valid, 
    // input   logic               ps2_valid, 
    // input   logic   [5:0]       ps1_s,
    // input   logic   [5:0]       ps2_s,
    input   logic   [5:0]       pd,
    input   logic   [4:0]       rob_index,
    input   logic               rob_is_full,
    input   logic               freelist_empty,
    input   logic               lsq_is_full,
    output  rename_data_t       rename_data_out,
    output  logic               rs_dispatch,
    output  logic               mult_rs_dispatch,
    output  logic               lsq_dispatch,
    output  logic               br_dispatch
    // output  logic               freelist_dequeue
);
    logic   [31:0]  inst;
    logic   [31:0]  i_imm;
    logic   [31:0]  s_imm;
    logic   [31:0]  b_imm;
    logic   [31:0]  u_imm;
    logic   [31:0]  j_imm;
    logic   [2:0]   funct3;
    logic   [6:0]   funct7;
    logic   [6:0]   opcode;
    logic   [4:0]   rd_s;  
    logic   [4:0]   rs1_s;  
    logic   [4:0]   rs2_s;  

    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign opcode = inst[6:0];
    assign rd_s   = inst[11:7];
    assign rs1_s   = inst[19:15];
    assign rs2_s   = inst[24:20];

    assign i_imm  = {{21{inst[31]}}, inst[30:20]};
    assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign u_imm  = {inst[31:12], 12'h000};
    assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};    
    
    assign rs_dispatch = (!iq_is_empty && rs_open && !freelist_empty && !rob_is_full) ? 1'b1 : 1'b0; // Remove from instruction queue and send to the reservation station
    assign mult_rs_dispatch = (!iq_is_empty && mult_rs_open && !freelist_empty && !rob_is_full) ? 1'b1 : 1'b0; // Remove from instruction queue and send to the reservation station
    assign lsq_dispatch = (!iq_is_empty && !lsq_is_full && !freelist_empty && !rob_is_full) ? 1'b1 : 1'b0; // Remove from instruction queue and send to the reservation station
    assign br_dispatch = (!iq_is_empty && !lsq_is_full && !freelist_empty && !rob_is_full) ? 1'b1 : 1'b0;
    // MAY NEED TO CHANGE FOR INSTRUCTIONS THAT DO NOT HAVE A DESTINATION REGISTER
    // assign freelist_dequeue = ((rs_dispatch || mult_rs_dispatch) && rd_s != 5'd0) ? 1'b1 : 1'b0;

    // logic dummy;
    // logic [5:0] dummy2;
    // assign dummy2 = ps2_s;
    // assign dummy = ps2_valid;


    always_comb begin

        // RVFI Signals
        rename_data_out.rvfi_mon.valid = 1'b0;
        rename_data_out.rvfi_mon.order = iq_dequeue_rdata.inst_info.order;
        rename_data_out.rvfi_mon.inst = iq_dequeue_rdata.inst;
        rename_data_out.rvfi_mon.rs1_addr = rs1_s;
        rename_data_out.rvfi_mon.rs2_addr = rs2_s;
        rename_data_out.rvfi_mon.rs1_rdata = 'x;
        rename_data_out.rvfi_mon.rs2_rdata = 'x;
        rename_data_out.rvfi_mon.rd_addr = rd_s;
        rename_data_out.rvfi_mon.rd_wdata = 'x;
        rename_data_out.rvfi_mon.pc_rdata = iq_dequeue_rdata.inst_info.pc;
        rename_data_out.rvfi_mon.pc_wdata = iq_dequeue_rdata.inst_info.pc_next;
        rename_data_out.rvfi_mon.dmem_addr = '0;
        rename_data_out.rvfi_mon.dmem_rmask = '0;
        rename_data_out.rvfi_mon.dmem_wmask = '0;
        rename_data_out.rvfi_mon.dmem_rdata = '0;
        rename_data_out.rvfi_mon.dmem_wdata = '0;
        rename_data_out.rvfi_mon.regf_we = 1'b0; // Writes back to register file    
        
        // Bookkeeping Signals
        rename_data_out.book_keeping.aluop = 'x;
        rename_data_out.book_keeping.mult_type = 'x;
        rename_data_out.book_keeping.rs1_s = rs1_s;
        rename_data_out.book_keeping.rs2_s = rs2_s;
        rename_data_out.book_keeping.use_immediate = 'x;
        rename_data_out.book_keeping.res_type = 2'b00;
        rename_data_out.book_keeping.is_load = 2'b00;
        rename_data_out.book_keeping.is_store = 2'b00;
        rename_data_out.book_keeping.is_rem = 1'b0;
        rename_data_out.book_keeping.funct3 = 3'b000;
        rename_data_out.book_keeping.cmpop = 'x;
        rename_data_out.book_keeping.use_cmp = 'x;

        // Reservation Stations Signals
        rename_data_out.valid = '0;
        rename_data_out.ps1_v = '0;
        rename_data_out.ps1 = 'x;
        rename_data_out.ps2_v = '0;
        rename_data_out.immediate = 'x;
        rename_data_out.ps2 = 'x;
        rename_data_out.pd = '0;
        rename_data_out.rd = '0;
        rename_data_out.rob_entry = 'x;
        rename_data_out.read_rs1 = 1'b0;
        rename_data_out.read_rs2 = 1'b0;
        unique case(opcode)
            op_b_lui: begin
                // LUI
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = 1'b1; // Set the source ready as there is no source
                // rename_data_out.ps1 = 'x; // There is no other source register
                // rename_data_out.ps2_v = 1'b1; // Immediate is ready
                rename_data_out.immediate = u_imm;
                // rename_data_out.ps2 = 'x; // There is no other source register
                rename_data_out.rd = rd_s; // Architectural Destination Register
                rename_data_out.pd = (rd_s == 5'd0) ? '0 : pd; // Renamed Destination Register from RAT
                rename_data_out.rob_entry = rob_index;
                rename_data_out.read_rs1 = 1'b0;
                rename_data_out.read_rs2 = 1'b0;
                rename_data_out.book_keeping.rs1_s = '0;
                rename_data_out.book_keeping.rs2_s = '0;
                rename_data_out.rvfi_mon.rs1_addr = '0;
                rename_data_out.rvfi_mon.rs2_addr = '0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;
                // Bookkeeping Signals
                rename_data_out.book_keeping.aluop = alu_lui;
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 1'b1;
                rename_data_out.book_keeping.res_type = arith_res;
                rename_data_out.book_keeping.cmpop = 'x;
                

                // RVFI Signals
                rename_data_out.rvfi_mon.regf_we = 1'b1; // Writes back to register file                
            end
            op_b_auipc: begin
                // AUIPC
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = 1'b1; // Set the source ready as there is no source
                // rename_data_out.ps1 = 'x; // There is no other source register
                // rename_data_out.ps2_v = 1'b1; // Immediate is ready
                rename_data_out.immediate = u_imm;
                // rename_data_out.ps2 = 'x; // There is no other source register
                rename_data_out.rd = rd_s; // Architectural Destination Register
                rename_data_out.pd = (rd_s == 5'd0) ? '0 : pd; // Renamed Destination Register from RAT
                rename_data_out.rob_entry = rob_index;
                rename_data_out.read_rs1 = 1'b0;
                rename_data_out.read_rs2 = 1'b0;
                rename_data_out.book_keeping.rs1_s = '0;
                rename_data_out.book_keeping.rs2_s = '0;
                rename_data_out.rvfi_mon.rs1_addr = '0;
                rename_data_out.rvfi_mon.rs2_addr = '0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;

                // Bookkeeping Signals
                rename_data_out.book_keeping.aluop = alu_auipc;
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 1'b1;
                rename_data_out.book_keeping.res_type = arith_res;
                rename_data_out.book_keeping.cmpop = 'x;

                // RVFI Signals
                rename_data_out.rvfi_mon.regf_we = 1'b1; // Writes back to register file  
            end
            op_b_jal: begin
                // JAL
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = 1'b1; // Set the source ready as there is no source
                // rename_data_out.ps1 = 'x; // There is no other source register
                // rename_data_out.ps2_v = 1'b1; // Immediate is ready
                rename_data_out.immediate = j_imm;
                // rename_data_out.ps2 = 'x; // There is no other source register
                rename_data_out.rd = rd_s; // Architectural Destination Register
                rename_data_out.pd = (rd_s == 5'd0) ? '0 : pd; // Renamed Destination Register from RAT
                rename_data_out.rob_entry = rob_index;
                rename_data_out.read_rs1 = 1'b0;
                rename_data_out.read_rs2 = 1'b0;
                rename_data_out.book_keeping.rs1_s = '0;
                rename_data_out.book_keeping.rs2_s = '0;
                rename_data_out.rvfi_mon.rs1_addr = '0;
                rename_data_out.rvfi_mon.rs2_addr = '0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;
                rename_data_out.book_keeping.aluop = alu_jal;//used in branch unit


                // Bookkeeping Signals
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 'x;
                rename_data_out.book_keeping.res_type = branch_res;
                rename_data_out.book_keeping.cmpop = 'x;
                rename_data_out.book_keeping.use_cmp = 1'b0;

                // RVFI Signals
                rename_data_out.rvfi_mon.regf_we = 1'b1; // Writes back to register file  
            end
            op_b_jalr: begin
                // JALR
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = ps1_valid; // Set the source ready as there is no source
                // rename_data_out.ps1 = ps1_s; // There is no other source register
                // rename_data_out.ps2_v = 1'b1; // Immediate is ready
                rename_data_out.immediate = i_imm;
                // rename_data_out.ps2 = 'x; // There is no other source register
                rename_data_out.rd = rd_s; // Architectural Destination Register
                rename_data_out.pd = (rd_s == 5'd0) ? '0 : pd; // Renamed Destination Register from RAT
                rename_data_out.rob_entry = rob_index;
                rename_data_out.read_rs1 = 1'b1;
                rename_data_out.read_rs2 = 1'b0;
                rename_data_out.book_keeping.rs1_s = rs1_s;
                rename_data_out.book_keeping.rs2_s = '0;
                rename_data_out.rvfi_mon.rs1_addr = rs1_s;
                rename_data_out.rvfi_mon.rs2_addr = '0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;
                rename_data_out.book_keeping.aluop = alu_jalr;//used in branch unit

                // Bookkeeping Signals
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 'x;
                rename_data_out.book_keeping.res_type = branch_res;
                rename_data_out.book_keeping.cmpop = 'x;
                rename_data_out.book_keeping.use_cmp = 1'b0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;

                // RVFI Signals
                rename_data_out.rvfi_mon.regf_we = 1'b1; // Writes back to register file
            end
            op_b_br: begin
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = ps1_valid; // Set the source ready as there is no source
                // rename_data_out.ps1 = ps1_s; // There is no other source register
                // rename_data_out.ps2_v = 1'b1; // Immediate is ready
                rename_data_out.immediate = b_imm;
                // rename_data_out.ps2 = 'x; // There is no other source register
                rename_data_out.rd = '0; // Architectural Destination Register
                rename_data_out.pd = '0; // Renamed Destination Register from RAT
                rename_data_out.rob_entry = rob_index;
                rename_data_out.read_rs1 = 1'b1;
                rename_data_out.read_rs2 = 1'b1;
                rename_data_out.book_keeping.rs1_s = rs1_s;
                rename_data_out.book_keeping.rs2_s = rs2_s;
                rename_data_out.rvfi_mon.rs1_addr = rs1_s;
                rename_data_out.rvfi_mon.rs2_addr = rs2_s;
                rename_data_out.rvfi_mon.rd_addr = '0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;

                // Bookkeeping Signals
                rename_data_out.book_keeping.aluop = alu_branch; // not dont care
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 'x;
                rename_data_out.book_keeping.res_type = branch_res;
                rename_data_out.book_keeping.use_cmp = 1'b1;

                // RVFI Signals
                rename_data_out.rvfi_mon.regf_we = 1'b0; // Writes back to register file

                unique case(funct3)
                    beq: rename_data_out.book_keeping.cmpop = eq; // BEQ
                    bne: rename_data_out.book_keeping.cmpop = ne; // BNE
                    blt: rename_data_out.book_keeping.cmpop = lt; // BLT
                    bge: rename_data_out.book_keeping.cmpop = ge; // BGE
                    bltu: rename_data_out.book_keeping.cmpop = ltu; // BLTU
                    bgeu: rename_data_out.book_keeping.cmpop = geu; // BGEU
                    default: ;
                endcase
            end
            op_b_load: begin
                // LOAD 
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = ps1_valid; // Set the source ready as there is no source
                // rename_data_out.ps1 = ps1_s; // There is no other source register
                // rename_data_out.ps2_v = 1'b1; // Immediate is ready
                rename_data_out.immediate = i_imm;
                // rename_data_out.ps2 = 'x; // There is no other source register

                //CHECK// assume these are 0 since we dont used rd?
                rename_data_out.rd = rd_s; // Architectural Destination Register
                rename_data_out.pd = (rd_s == 5'd0) ? '0 : pd; // Renamed Destination Register from RAT
                rename_data_out.rob_entry = rob_index;
                rename_data_out.read_rs1 = 1'b1;
                rename_data_out.read_rs2 = 1'b0;
                rename_data_out.book_keeping.rs1_s = rs1_s;
                rename_data_out.book_keeping.rs2_s = '0;
                rename_data_out.rvfi_mon.rs1_addr = rs1_s;
                rename_data_out.rvfi_mon.rs2_addr = '0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;

                // Bookkeeping Signals
                rename_data_out.book_keeping.aluop = 'x;
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 'x;
                rename_data_out.book_keeping.res_type = mem_res;
                rename_data_out.book_keeping.funct3 = funct3;
                rename_data_out.book_keeping.cmpop = 'x;
                
                //ADDED 
                rename_data_out.book_keeping.is_store = 1'b0; 
                rename_data_out.book_keeping.is_load = 1'b1;

                // RVFI Signals
                rename_data_out.rvfi_mon.regf_we = 1'b1; // Writes back to register file


            end
            op_b_store: begin
                // STORE 
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = ps1_valid; // Set the source ready as there is no source
                // rename_data_out.ps1 = ps1_s; // There is no other source register
                // rename_data_out.ps2_v = 1'b1; // Immediate is ready
                rename_data_out.immediate = s_imm;
                // rename_data_out.ps2 = 'x; // There is no other source register

                //CHECK// assume these are 0 since we dont used rd?
                rename_data_out.rd = '0; // Architectural Destination Register
                rename_data_out.pd = '0; // Renamed Destination Register from RAT


                rename_data_out.rob_entry = rob_index;
                rename_data_out.read_rs1 = 1'b1;
                rename_data_out.read_rs2 = 1'b1;
                rename_data_out.book_keeping.rs1_s = rs1_s;
                rename_data_out.book_keeping.rs2_s = rs2_s;
                rename_data_out.rvfi_mon.rs1_addr = rs1_s;
                rename_data_out.rvfi_mon.rs2_addr = rs2_s;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;

                // Bookkeeping Signals
                rename_data_out.book_keeping.aluop = 'x;
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 'x;
                rename_data_out.book_keeping.res_type = mem_res;
                rename_data_out.book_keeping.cmpop = 'x;

                //ADDED
                rename_data_out.book_keeping.is_store = 1'b1; 
                rename_data_out.book_keeping.is_load = 1'b0;
                rename_data_out.book_keeping.funct3 = funct3;
                // RVFI Signals
                rename_data_out.rvfi_mon.regf_we = 1'b0; // Writes back to register file
            end

            op_b_imm: begin
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = ps1_valid;
                // rename_data_out.ps1 = ps1_s;
                // rename_data_out.ps2_v = 1'b1; // No Second Source Register
                // rename_data_out.ps2 = 'x; // No Second Source Register
                rename_data_out.immediate = i_imm; // Immediate Source Value
                rename_data_out.rd = rd_s; // Destination Register
                rename_data_out.rob_entry = rob_index;
                rename_data_out.pd = (rd_s == 5'd0) ? '0 : pd;// Renamed Destination Register from RAT
                rename_data_out.read_rs1 = 1'b1;
                rename_data_out.read_rs2 = 1'b0;
                rename_data_out.book_keeping.rs1_s = rs1_s;
                rename_data_out.book_keeping.rs2_s = '0;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;
                
                //RVFI
                rename_data_out.rvfi_mon.rs1_addr = rs1_s;
                rename_data_out.rvfi_mon.rs2_addr = '0;
                rename_data_out.rvfi_mon.regf_we = 1'b1; // Writes back to register file


                // Bookkeeping Signals
                rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 1'b1;
                rename_data_out.book_keeping.res_type = arith_res;
                rename_data_out.book_keeping.cmpop = 'x;

                unique case(funct3)
                    add: begin
                        // ADDI
                        rename_data_out.book_keeping.aluop =  alu_add;
                    end
                    slt: begin
                        // SLTI
                       rename_data_out.book_keeping.aluop =  alu_slti;
                    end
                    sltu: begin
                        // SLTIU
                       rename_data_out.book_keeping.aluop =  alu_sltiu;
                    end
                    axor: begin
                        // XORI
                       rename_data_out.book_keeping.aluop =  alu_xor;
                    end
                    aor: begin
                        // ORI
                        rename_data_out.book_keeping.aluop =  alu_or;
                    end
                    aand: begin
                        // ANDI
                        rename_data_out.book_keeping.aluop =  alu_and;
                    end
                    sll: begin
                        // SLLI
                        rename_data_out.book_keeping.aluop =  alu_sll;
                    end
                    sr: begin
                        if (funct7[5]) begin
                           rename_data_out.book_keeping.aluop =  alu_sra;
                        end else begin
                           rename_data_out.book_keeping.aluop =  alu_srl;
                        end  
                    end
                    default: begin
                       rename_data_out.book_keeping.aluop =  {1'b0, funct3};
                    end
                endcase
            end


            op_b_reg: begin
                // Reservation Station Signals
                rename_data_out.valid = 1'b1; // RS is written to
                // rename_data_out.ps1_v = ps1_valid;
                // rename_data_out.ps1 = ps1_s;
                // rename_data_out.ps2_v = ps2_valid;
                // rename_data_out.ps2 = ps2_s;
                rename_data_out.immediate = 'x; // Immediate Source Value
                rename_data_out.rd = rd_s; // Destination Register
                rename_data_out.rob_entry = rob_index;
                rename_data_out.pd = (rd_s == 5'd0) ? '0 : pd;// Renamed Destination Register from RAT
                rename_data_out.read_rs1 = 1'b1;
                rename_data_out.read_rs2 = 1'b1;
                rename_data_out.book_keeping.rs1_s = rs1_s;
                rename_data_out.book_keeping.rs2_s = rs2_s;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;
                rename_data_out.book_keeping.is_rem = 1'b0;
                

                //RVFI
                rename_data_out.rvfi_mon.rs1_addr = rs1_s;
                rename_data_out.rvfi_mon.rs2_addr = rs2_s;
                rename_data_out.rvfi_mon.regf_we = 1'b1; // Writes back to register file
                rename_data_out.book_keeping.cmpop = 'x;


                // Bookkeeping Signals
                // rename_data_out.book_keeping.mult_type = 'x; // Not a multiply instruction
                rename_data_out.book_keeping.use_immediate = 1'b0;
                rename_data_out.book_keeping.funct3 = funct3;
                

                unique case (funct3)
                    add: begin
                        if(funct7[0]) begin
                            // MUL
                           rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_mult;
                           rename_data_out.book_keeping.mult_type = 2'b01;
                        end else if (funct7[5]) begin
                            // SUB
                           rename_data_out.book_keeping.res_type = arith_res;
                           rename_data_out.book_keeping.aluop =  alu_sub;
                        end else if(!funct7[5]) begin
                            // ADD
                           rename_data_out.book_keeping.res_type = arith_res;
                           rename_data_out.book_keeping.aluop =  alu_add;
                        end 
                    end
                    sll: begin
                        if(funct7[0]) begin
                            // MULH
                           rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_mult;
                           rename_data_out.book_keeping.mult_type = 2'b01;
                        end else begin
                            // SLL
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_sll;
                        end
                    end
                    slt: begin
                        if(funct7[0]) begin
                            // MULHSU
                           rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_mult;
                           rename_data_out.book_keeping.mult_type = 2'b10;
                        end else begin
                            // SLT
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_slt;
                        end
                    end
                    sltu: begin
                        if(funct7[0]) begin
                            // MULHU
                           rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_mult;
                           rename_data_out.book_keeping.mult_type = 2'b11;
                        end else begin
                            // SLTU
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_sltu;
                        end
                    end
                    sr: begin
                        if (funct7[5]) begin
                            // SRA
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_sra;
                        end else if (funct7[0]) begin
                            //DIVU 
                            rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_div;
                           rename_data_out.book_keeping.mult_type = 2'b11;
                        
                        end else begin
                            // SRL
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_srl;
                        end
                    end

                    axor: begin
                        //func3 = 100
                        if(funct7[0])begin
                        // DIV
                           rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_div;
                           rename_data_out.book_keeping.mult_type = 2'b01;
                        end else begin
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_xor;
                        end
                    end

                    aor:begin
                        // 110
                        if(funct7[0])begin
                        // REM 
                           rename_data_out.book_keeping.is_rem = 1'b1; 
                           rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_div;
                           rename_data_out.book_keeping.mult_type = 2'b01;
                        end else begin
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_or;
                        end
                    end 

                    aand: begin
                        if(funct7[0])begin
                        // REMU
                           rename_data_out.book_keeping.is_rem = 1'b1; 
                           rename_data_out.book_keeping.res_type = mult_res;
                           rename_data_out.book_keeping.aluop =  alu_div;
                           rename_data_out.book_keeping.mult_type = 2'b01;
                        end else begin
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  alu_and;
                        end
                    end
                    default: begin
                        // XOR, OR, AND
                            rename_data_out.book_keeping.res_type = arith_res;
                            rename_data_out.book_keeping.aluop =  {2'b0, funct3};    
                    end
                endcase
            end
            default: begin
                // RVFI Signals
                rename_data_out.rvfi_mon.valid = 1'b0;
                rename_data_out.rvfi_mon.order = iq_dequeue_rdata.inst_info.order;
                rename_data_out.rvfi_mon.inst = iq_dequeue_rdata.inst;
                rename_data_out.rvfi_mon.rs1_addr = rs1_s;
                rename_data_out.rvfi_mon.rs2_addr = rs2_s;
                rename_data_out.rvfi_mon.rs1_rdata = 'x;
                rename_data_out.rvfi_mon.rs2_rdata = 'x;
                rename_data_out.rvfi_mon.rd_addr = rd_s;
                rename_data_out.rvfi_mon.rd_wdata = 'x;
                rename_data_out.rvfi_mon.pc_rdata = iq_dequeue_rdata.inst_info.pc;
                rename_data_out.rvfi_mon.pc_wdata = iq_dequeue_rdata.inst_info.pc_next;
                rename_data_out.rvfi_mon.dmem_addr = '0;
                rename_data_out.rvfi_mon.dmem_rmask = '0;
                rename_data_out.rvfi_mon.dmem_wmask = '0;
                rename_data_out.rvfi_mon.dmem_rdata = '0;
                rename_data_out.rvfi_mon.dmem_wdata = '0;
                
                // Bookkeeping Signals
                rename_data_out.book_keeping.aluop = 'x;
                rename_data_out.book_keeping.mult_type = 'x;
                rename_data_out.book_keeping.rs1_s = rs1_s;
                rename_data_out.book_keeping.rs2_s = rs2_s;
                rename_data_out.book_keeping.use_immediate = 'x;
                rename_data_out.book_keeping.res_type = 2'b00;
                rename_data_out.book_keeping.cmpop = 'x;
                rename_data_out.book_keeping.use_cmp = 'x;

                // Reservation Stations Signals
                rename_data_out.valid = '0;
                rename_data_out.ps1_v = '0;
                rename_data_out.ps1 = 'x;
                rename_data_out.ps2_v = '0;
                rename_data_out.immediate = 'x;
                rename_data_out.ps2 = 'x;
                rename_data_out.pd = '0;
                rename_data_out.rd = '0;
                rename_data_out.rob_entry = 'x;
                rename_data_out.pc = iq_dequeue_rdata.inst_info.pc;

            end
        endcase
    end

    always_comb begin
        if(rst) begin
            inst = '0;
        end else begin
            inst = iq_dequeue_rdata.inst; // Remove data from the instruction queue and decode/rename it
            // if(rs_dispatch) begin
            // end else begin
            //     inst = '0;
            // end
        end
    end


endmodule



