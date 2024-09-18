/////////////////////////////////////////////////////////////
//  Maybe use some of your types from mp_pipeline here?    //
//    Note you may not need to use your stage structs      //
/////////////////////////////////////////////////////////////

package rv32i_types;

   typedef enum bit [2:0] {
        lb  = 3'b000,
        lh  = 3'b001,
        lw  = 3'b010,
        lbu = 3'b100,
        lhu = 3'b101
    } load_funct3_t;

    typedef enum bit [2:0] {
        sb = 3'b000,
        sh = 3'b001,
        sw = 3'b010
    } store_funct3_t;

    typedef enum bit [1:0]{
        arith_res = 2'b00,
        mult_res  = 2'b01,
        mem_res   = 2'b10,
        branch_res   = 2'b11
    }res_station_type_t;

    typedef enum bit [2:0] {
        add  = 3'b000, //check bit 30 for sub if op_reg opcode
        sll  = 3'b001,
        slt  = 3'b010,
        sltu = 3'b011,
        axor = 3'b100,
        sr   = 3'b101, //check bit 30 for logical/arithmetic
        aor  = 3'b110,
        aand = 3'b111
    } arith_funct3_t;

    typedef enum bit [2:0] {
        beq  = 3'b000, //check bit 30 for sub if op_reg opcode
        bne  = 3'b001,
        blt = 3'b100,
        bge = 3'b101,
        bltu  = 3'b110,
        bgeu   = 3'b111 //check bit 30 for logical/arithmetic
    } branch_funct3_t;

    typedef enum bit [1:0]{
        mul = 2'b00,
        mulh = 2'b01,
        mulhsu = 2'b10,
        mulhu = 2'b11
    }mult_type;

    typedef enum bit [4:0] {
        alu_add =   5'b00000,
        alu_sll =   5'b00001,
        alu_sra =   5'b00010,
        alu_sub =   5'b00011,
        alu_xor =   5'b00100,
        alu_srl =   5'b00101,
        alu_or  =   5'b00110,
        alu_and =   5'b00111,
        alu_lui =   5'b01000,
        alu_auipc = 5'b01001,
        alu_slt =   5'b01010,
        alu_sltu =  5'b01011,
        alu_slti =  5'b01100,
        alu_sltiu = 5'b01101,
        alu_jal =   5'b01110,
        alu_jalr =  5'b01111,
        alu_mult =  5'b10000,
        alu_branch =  5'b10001,
        alu_div = 5'b10010
    } alu_ops;

    typedef enum bit [2:0] {
        eq = 3'b000,
        ne = 3'b001,
        lt = 3'b010,
        ge = 3'b100,
        ltu = 3'b101,
        geu = 3'b110
    } cmp_ops;

    typedef enum logic [6:0] {
        op_b_lui   = 7'b0110111, // U load upper immediate 
        op_b_auipc = 7'b0010111, // U add upper immediate PC 
        op_b_jal   = 7'b1101111, // J jump and link 
        op_b_jalr  = 7'b1100111, // I jump and link register 
        op_b_br    = 7'b1100011, // B branch 
        op_b_load  = 7'b0000011, // I load 
        op_b_store = 7'b0100011, // S store 
        op_b_imm   = 7'b0010011, // I arith ops with register/immediate operands 
        op_b_reg   = 7'b0110011, // R arith ops with register operands 
        op_b_csr   = 7'b1110011  // I control and status register 
        // op_mult    = 7'b0110011
    } rv32i_op_b_t;

    // Add more things here . . .

    // RVFI Structure
    typedef struct packed{
        logic           valid;
        logic   [63:0]  order;
        logic   [31:0]  inst;
        logic   [4:0]   rs1_addr;
        logic   [4:0]   rs2_addr;
        logic   [31:0]  rs1_rdata;
        logic   [31:0]  rs2_rdata;
        logic   [4:0]   rd_addr;
        logic   [31:0]  rd_wdata;
        logic   [31:0]  pc_rdata;
        logic   [31:0]  pc_wdata;
        logic           regf_we;
        logic   [31:0]  dmem_addr;
        logic   [3:0]   dmem_rmask;
        logic   [3:0]   dmem_wmask;
        logic   [31:0]  dmem_rdata;
        logic   [31:0]  dmem_wdata;
    } rvfi_mon_t;

    // Fetch Register Structure
    typedef struct packed {
        logic [31:0]    pc;
        logic [31:0]    pc_next;
        logic [63:0]    order;
    } inst_info_t;

    typedef struct packed {
        inst_info_t        inst_info;
        logic              iq_enqueue; 
    } fetch_iqbuf_reg_t;

    // Dequeue Structure
    typedef struct packed {
        inst_info_t inst_info;
        logic   [31:0] inst;
    } iq_dequeue_rdata_t;

    // Reservation Station Entry Structures
    typedef struct packed {
        logic   [4:0]   aluop;
        logic   [1:0]   mult_type;
        logic   [4:0]   rs1_s;
        logic   [4:0]   rs2_s;
        logic           use_immediate;
        logic   [1:0]   res_type;

        //ADDDED FOR MEM OPS 
        logic           is_store; 
        logic           is_load;
        logic   [2:0]   funct3; 

        // //FOR M EXTENSION 
        logic           is_rem; 
        // ADDED FOR Branches
        logic           use_cmp;
        logic    [2:0]  cmpop;
    } book_keeping_t;

    typedef struct packed {
        logic           valid; // 1
        logic           ps1_v; // 1
        logic   [5:0]   ps1;   // 6
        logic           ps2_v; // 1
        logic   [31:0]  immediate;
        logic   [5:0]   ps2;   // 6
        logic   [5:0]   pd;    // 6
        logic   [4:0]   rd;    // 5
        logic   [3:0]   rob_entry; // 4 - need to confirm
        logic           read_rs1; // 1
        logic           read_rs2; // 1
        logic   [31:0]  pc;
        book_keeping_t  book_keeping;

        rvfi_mon_t      rvfi_mon;
    } rename_data_t;

    typedef struct packed {
        logic   [31:0]  ps1_value;
        logic   [31:0]  ps2_value;
        rename_data_t   rename_data;
    } rs_entry_t;
    
    // Functional Unit Entry Structures
    typedef struct packed{
        logic   [5:0]   pd;
        logic   [4:0]   rd;
        logic   [3:0]   rob_index;
        logic           valid;
        logic   [31:0]  pc;
        logic   [31:0]  ps1_value;
        logic   [31:0]  ps2_value;
    }FU_misc_t;

    typedef struct packed{
        rvfi_mon_t      rvfi_mon;
        FU_misc_t       misc;
        logic   [31:0]  result;
    } FU_entry_t;


    // CDB Entry Structure
    typedef struct packed{
        logic   [5:0]       pd;
        logic   [4:0]       rd;
        logic   [31:0]      result;   
        logic               RAT_we;
        logic               RRAT_we;
        logic   [3:0]       rob_index;
        // logic               valid_data;
        logic               CDB_regf_we;
        // logic   [31:0]      CDB_rd_v;
        // logic   [5:0]       CDB_rd_s; // Parameter
        logic               valid;
        rvfi_mon_t          rvfi_mon;
        logic               flush;
        logic               jump;

    }cdb_entry_t;

    // ROB Entry Structure
    typedef struct packed {
        logic           commit;
        logic   [4:0]   rd;
        logic   [5:0]   pd;
        // logic   [63:0]  order;
        // logic   [31:0]  inst;
        // logic   [4:0]   rs1_addr;
        // logic   [4:0]   rs2_addr;
        // logic   [31:0]   rs1_data;
        // logic   [31:0]   rs2_data;
        // logic   [31:0]   rd_wdata;
        // logic   [31:0]   pc_rdata;
        // logic   [31:0]   pc_wdata;
        // logic            regf_we;
        logic           update_rat;
        logic   [31:0]  result;
        rvfi_mon_t       rvfi_mon; // RVFI Monitor Signals
        logic           flush;
        logic           jump;
        // logic           invalid;
    } rob_entry_t;

    typedef struct packed{
        rename_data_t   rename_data;
        logic   [31:0]  result;
    } mem_entry_t;
    
    typedef struct packed{
        mem_entry_t mem_entry;
        logic [31:0] mem_addr;
    } mod_mem_entry_t;
    typedef struct packed{
        rename_data_t   rename_data;
        logic   [31:0]  pc;//for JALR?
        logic   [31:0]  result;
        logic           flush;
    } branch_entry_t;

    typedef struct packed {
    logic [31:0]             store_addr;
    logic [31:0]             wdata; 
    logic [3:0]              wmask; 
    } store_buff_t;
    
endpackage