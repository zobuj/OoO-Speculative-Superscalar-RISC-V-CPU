module pregfile 
import rv32i_types::*;
#(parameter NUM_PHYS_REG = 64, PHYS_REG_IDX = 5 )
(
            //ASSUME WE HAVE 64 PHYSICAL REGISTERS FOR NOW

    input   logic           clk,
    input   logic           rst,
    // input   logic           flush,
    
    // write back result into reg file from CDB (4-way = 4 CBDs)
    input   logic           CDB_regf_we,
    input   logic   [31:0]  CDB_rd_v,
    input   logic   [PHYS_REG_IDX : 0]   CDB_rd_s, //64 physical registers 

    // read source operands from reservation station 
    // input   logic   [PHYS_REG_IDX : 0]   rs1_s[4], rs2_s[4], 
    input   logic   [PHYS_REG_IDX : 0]   rs1_s, rs2_s, 
    input   logic   [PHYS_REG_IDX : 0]   mult_rs1_s, mult_rs2_s, 
    input   logic   [PHYS_REG_IDX : 0]   mem_rs1_s, mem_rs2_s,
    input   logic   [PHYS_REG_IDX : 0]   br_rs1_s, br_rs2_s,
    // input   logic   [PHYS_REG_IDX : 0]   rs1_s_0, rs2_s_0, 
    // input   logic   [PHYS_REG_IDX : 0]   rs1_s_1, rs2_s_1, 
    // input   logic   [PHYS_REG_IDX : 0]   rs1_s_2, rs2_s_2, 
    // input   logic   [PHYS_REG_IDX : 0]   rs1_s_3, rs2_s_3, 
    input   logic   read_rs1, read_rs2, 
    input   logic   mult_read_rs1, mult_read_rs2, 
    input   logic   mem_read_rs1, mem_read_rs2,
    input   logic   br_read_rs1, br_read_rs2,

    // input   logic   read_rs1_0, read_rs2_0, 
    // input   logic   read_rs1_1, read_rs2_1, 
    // input   logic   read_rs1_2, read_rs2_2, 
    // input   logic   read_rs1_3, read_rs2_3, 
    //output source ops from reservation station for functional unit to use
    output   logic  [31 : 0]   rs1_v, rs2_v, // NEED TO SEPARATE INTO different ports need to read combinationally
    output   logic  [31 : 0]   mult_rs1_v, mult_rs2_v, // NEED TO SEPARATE INTO different ports need to read combinationally
    output   logic  [31 : 0]   mem_rs1_v, mem_rs2_v, // NEED TO SEPARATE INTO different ports need to read combinationally
    output   logic  [31 : 0]   br_rs1_v, br_rs2_v // NEED TO SEPARATE INTO different ports need to read combinationally

    // output   logic  [31 : 0]   rs1_v_0, rs2_v_0, // NEED TO SEPARATE INTO different ports need to read combinationally
    // output   logic  [31 : 0]   rs1_v_1, rs2_v_1, // NEED TO SEPARATE INTO different ports need to read combinationally
    // output   logic  [31 : 0]   rs1_v_2, rs2_v_2, // NEED TO SEPARATE INTO different ports need to read combinationally
    // output   logic  [31 : 0]   rs1_v_3, rs2_v_3  // NEED TO SEPARATE INTO different ports need to read combinationally
);

    logic   [31:0]  data [NUM_PHYS_REG];


    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < NUM_PHYS_REG; i++) begin
                data[i] <= '0;
            end
        end else if (CDB_regf_we && (CDB_rd_s != 6'd0)) begin
            data[CDB_rd_s] <= CDB_rd_v;
        end
    end


    always_comb begin


            if(read_rs1) begin
                // if(CDB_regf_we && (CDB_rd_s == rs1_s) && (CDB_rd_s != 0) && (rs1_s != 0))begin
                //     rs1_v = CDB_rd_v; 
                // end else begin
                // end
                rs1_v = (rs1_s != 6'd0) ? data[rs1_s] : '0;
            end else begin
                rs1_v = '0;
            end

            if(read_rs2) begin
                // if(CDB_regf_we && (CDB_rd_s == rs2_s) && (CDB_rd_s != 0) && (rs2_s != 0))begin
                //     rs2_v = CDB_rd_v; 
                // end else begin
                // end
                rs2_v = (rs2_s != 6'd0) ? data[rs2_s] : '0;
            end else begin
                rs2_v = '0;
            end



            if(mult_read_rs1) begin
                // if(CDB_regf_we && (CDB_rd_s == mult_rs1_s) && (CDB_rd_s != 0) && (mult_rs1_s != 0))begin
                //     mult_rs1_v = CDB_rd_v; 
                // end else begin
                    mult_rs1_v = (mult_rs1_s != 6'd0) ? data[mult_rs1_s] : '0;
                // end
            end else begin
                mult_rs1_v = '0;
            end

            if(mult_read_rs2) begin
                // if(CDB_regf_we && (CDB_rd_s == mult_rs2_s) && (CDB_rd_s != 0) && (mult_rs2_s != 0))begin
                    // mult_rs2_v = CDB_rd_v; 
                // end else begin
                    mult_rs2_v = (mult_rs2_s != 6'd0) ? data[mult_rs2_s] : '0;
                // end
            end else begin
                mult_rs2_v = '0;
            end

            if(mem_read_rs1)begin
                // if(CDB_regf_we && (CDB_rd_s == mem_rs1_s) && (CDB_rd_s != 0) && (mem_rs1_s != 0))begin
                //     mem_rs1_v = CDB_rd_v; 
                // end else begin
                    mem_rs1_v = (mem_rs1_s != 6'd0) ? data[mem_rs1_s] : '0;
                // end
            end else begin
                mem_rs1_v = '0;
            end

            if(mem_read_rs2)begin
                // if(CDB_regf_we && (CDB_rd_s == mem_rs2_s) && (CDB_rd_s != 0) && (mem_rs2_s != 0))begin
                //     mem_rs2_v = CDB_rd_v; 
                // end else begin
                    mem_rs2_v = (mem_rs2_s != 6'd0) ? data[mem_rs2_s] : '0;
                // end
            end else begin
                mem_rs2_v = '0;
            end

            if(br_read_rs1)begin
                // if(CDB_regf_we && (CDB_rd_s == br_rs1_s) && (CDB_rd_s != 0) && (br_rs1_s != 0))begin
                //     br_rs1_v = CDB_rd_v; 
                // end else begin
                    br_rs1_v = (br_rs1_s != 6'd0) ? data[br_rs1_s] : '0;
                // end
            end else begin
                br_rs1_v = '0;
            end

            if(br_read_rs2)begin
                // if(CDB_regf_we && (CDB_rd_s == br_rs2_s) && (CDB_rd_s != 0) && (br_rs2_s != 0))begin
                //     br_rs2_v = CDB_rd_v; 
                // end else begin
                    br_rs2_v = (br_rs2_s != 6'd0) ? data[br_rs2_s] : '0;
                // end
            end else begin
                br_rs2_v = '0;
            end

            // if(read_rs1_0) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs1_s_0) && (CDB_rd_s != 0) && (rs1_s_0 != 0))begin
            //         rs1_v_0 = CDB_rd_v; 
            //     end else begin
            //         rs1_v_0 = (rs1_s_0 != 6'd0) ? data[rs1_s_0] : '0;
            //     end
            // end else begin
            //     rs1_v_0 = '0;
            // end

            // if(read_rs1_1) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs1_s_1) && (CDB_rd_s != 0) && (rs1_s_1 != 0))begin
            //         rs1_v_1 = CDB_rd_v; 
            //     end else begin
            //         rs1_v_1 = (rs1_s_1 != 6'd0) ? data[rs1_s_1] : '0;
            //     end
            // end else begin
            //     rs1_v_1 = '0;
            // end

            // if(read_rs1_2) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs1_s_2) && (CDB_rd_s != 0) && (rs1_s_2 != 0))begin
            //         rs1_v_2 = CDB_rd_v; 
            //     end else begin
            //         rs1_v_2 = (rs1_s_2 != 6'd0) ? data[rs1_s_2] : '0;
            //     end
            // end else begin
            //     rs1_v_2 = '0;
            // end

            // if(read_rs1_3) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs1_s_3) && (CDB_rd_s != 0) && (rs1_s_3 != 0))begin
            //         rs1_v_3 = CDB_rd_v; 
            //     end else begin
            //         rs1_v_3 = (rs1_s_3 != 6'd0) ? data[rs1_s_3] : '0;
            //     end
            // end else begin
            //     rs1_v_3 = '0;
            // end

            // if(read_rs2_0) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs2_s_0) && (CDB_rd_s != 0) && (rs2_s_0 != 0))begin
            //         rs2_v_0 = CDB_rd_v; 
            //     end else begin
            //         rs2_v_0 = (rs2_s_0 != 6'd0) ? data[rs2_s_0] : '0;
            //     end
            // end else begin
            //     rs2_v_0 = '0;
            // end

            // if(read_rs2_1) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs2_s_1) && (CDB_rd_s != 0) && (rs2_s_1 != 0))begin
            //         rs2_v_1 = CDB_rd_v; 
            //     end else begin
            //         rs2_v_1 = (rs2_s_1 != 6'd0) ? data[rs2_s_1] : '0;
            //     end
            // end else begin
            //     rs2_v_1 = '0;
            // end

            // if(read_rs2_2) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs2_s_2) && (CDB_rd_s != 0) && (rs2_s_2 != 0))begin
            //         rs2_v_2 = CDB_rd_v; 
            //     end else begin
            //         rs2_v_2 = (rs2_s_2 != 6'd0) ? data[rs2_s_2] : '0;
            //     end
            // end else begin
            //     rs2_v_2 = '0;
            // end

            // if(read_rs2_3) begin
            //     if(CDB_regf_we && (CDB_rd_s == rs2_s_3) && (CDB_rd_s != 0) && (rs2_s_3 != 0))begin
            //         rs2_v_3 = CDB_rd_v; 
            //     end else begin
            //         rs2_v_3 = (rs2_s_3 != 6'd0) ? data[rs2_s_3] : '0;
            //     end
            // end else begin
            //     rs2_v_3 = '0;
            // end

    end


endmodule : pregfile
