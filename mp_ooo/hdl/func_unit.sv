module func_unit
import rv32i_types::*;

(
    input   logic clk, 
    input   logic rst,
    input   logic flush,
    // input   rs_entry_t                  fu_res_station_in[4],
    input   rs_entry_t                  mult_fu_res_station_in,
    input   rs_entry_t                  fu_res_station_in,
    input   logic                       FU_en,
    input   logic                       arith_cdb_sent,
    input   logic                       lsq_cdb_sent,
    input   logic                       mult_cdb_sent,
    input   logic                       br_cdb_sent,
    // output  FU_entry_t                  FU_out[4]
    output  FU_entry_t                  FU_out,
    output  FU_entry_t                  mult_FU_out,
    output  logic                       mult_done,
    output  logic                       div_done,
    output  logic                       issue_mult,
    output  logic                       clear_out
    // output  logic       [3:0]   in_use

);
    // logic mult_done;
    // logic [31:0] ps1[4];
    // logic [31:0] ps2[4];
    logic [31:0] result;
    logic [31:0] div_result;
    logic [31:0] rem_result;
    logic [63:0] mult_result;
    // logic   [31:0] alu1_res;

    // logic   [31:0] alu1_res;
    // logic   [31:0] alu2_res;
    // logic   [31:0] alu3_res;
    // logic   [31:0] alu4_res;


    logic alu_en;
    assign alu_en =  (fu_res_station_in.rename_data.valid && !(!arith_cdb_sent && (lsq_cdb_sent || mult_cdb_sent || br_cdb_sent)));

    always_ff @(posedge clk) begin
        if(rst) begin

            FU_out.misc <= '0;
            FU_out.rvfi_mon <= '0;
            mult_FU_out.misc <= '0;
            mult_FU_out.rvfi_mon <= '0;

            // ps1 <= '{default: 'x};
            // ps2 <= '{default: 'x};
            // // in_use <= 4'b0;
            // FU_out[0].misc <= '0;
            // FU_out[1].misc <= '0;
            // FU_out[2].misc <= '0;
            // FU_out[3].misc <= '0;
            
            // FU_out[0].rvfi_mon <= '0;
            // FU_out[1].rvfi_mon <= '0;
            // FU_out[2].rvfi_mon <= '0;
            // FU_out[3].rvfi_mon <= '0;
        end else begin

            if (FU_en) begin // may remove to decrease area (not optimized)
                if(fu_res_station_in.rename_data.valid && !(!arith_cdb_sent && (lsq_cdb_sent || mult_cdb_sent || br_cdb_sent))) begin
                    // Search for open FUx
                    FU_out.misc.pd <= fu_res_station_in.rename_data.pd;
                    FU_out.misc.rd <= fu_res_station_in.rename_data.rd;
                    FU_out.misc.rob_index <= fu_res_station_in.rename_data.rob_entry;
                    FU_out.misc.valid <= 1'b1;
                    // FU_out.result <= alu1_res;
                    
                    // FU_out.misc.pc <= fu_res_station_in.rename_data.book_keeping.pc;  
                    FU_out.misc.ps1_value <= fu_res_station_in.ps1_value;
                    FU_out.misc.ps2_value <= fu_res_station_in.ps2_value;  

                    FU_out.rvfi_mon.valid <= fu_res_station_in.rename_data.rvfi_mon.valid;  
                    FU_out.rvfi_mon.order <= fu_res_station_in.rename_data.rvfi_mon.order;  
                    FU_out.rvfi_mon.inst <= fu_res_station_in.rename_data.rvfi_mon.inst;  
                    FU_out.rvfi_mon.rs1_addr <= fu_res_station_in.rename_data.rvfi_mon.rs1_addr;
                    FU_out.rvfi_mon.rs2_addr <= fu_res_station_in.rename_data.rvfi_mon.rs2_addr;
                    FU_out.rvfi_mon.rs1_rdata <= fu_res_station_in.ps1_value;
                    FU_out.rvfi_mon.rs2_rdata <= fu_res_station_in.ps2_value;
                    FU_out.rvfi_mon.rd_addr <= fu_res_station_in.rename_data.rvfi_mon.rd_addr;

                    FU_out.rvfi_mon.rd_wdata <= fu_res_station_in.rename_data.rvfi_mon.rd_wdata;
                    
                    FU_out.rvfi_mon.pc_wdata <= fu_res_station_in.rename_data.rvfi_mon.pc_wdata;  
                    FU_out.rvfi_mon.pc_rdata <= fu_res_station_in.rename_data.rvfi_mon.pc_rdata;
                    FU_out.rvfi_mon.regf_we <= fu_res_station_in.rename_data.rvfi_mon.regf_we;
                    FU_out.rvfi_mon.dmem_addr <= fu_res_station_in.rename_data.rvfi_mon.dmem_addr;
                    FU_out.rvfi_mon.dmem_rmask <= fu_res_station_in.rename_data.rvfi_mon.dmem_rmask;
                    FU_out.rvfi_mon.dmem_wmask <= fu_res_station_in.rename_data.rvfi_mon.dmem_wmask;
                    FU_out.rvfi_mon.dmem_rdata <= fu_res_station_in.rename_data.rvfi_mon.dmem_rdata;
                    FU_out.rvfi_mon.dmem_wdata <= fu_res_station_in.rename_data.rvfi_mon.dmem_wdata;
                    FU_out.rvfi_mon.rs1_rdata <= fu_res_station_in.ps1_value;
                    FU_out.rvfi_mon.rs2_rdata <= fu_res_station_in.ps2_value;

                end 
                else if(!fu_res_station_in.rename_data.valid && !(!arith_cdb_sent && (lsq_cdb_sent || mult_cdb_sent || br_cdb_sent))) begin
                    FU_out.rvfi_mon <= '0;
                    FU_out.misc <= '0;


                end
                // else if(arith_cdb_sent) begin

                // end 
            end

            if(mult_fu_res_station_in.rename_data.valid && mult_done || mult_fu_res_station_in.rename_data.valid && div_done) begin
                // Search for open FUx
                mult_FU_out.misc.pd <= mult_fu_res_station_in.rename_data.pd;
                mult_FU_out.misc.rd <= mult_fu_res_station_in.rename_data.rd;
                mult_FU_out.misc.rob_index <= mult_fu_res_station_in.rename_data.rob_entry;
                mult_FU_out.misc.valid <= 1'b1;
            
                // if(!mult_cdb_sent && !br_cdb_sent && !lsq_cdb_sent) begin
                    //MUL
                    if(mult_fu_res_station_in.rename_data.book_keeping.aluop == alu_mult)begin
                        if(mult_fu_res_station_in.rename_data.book_keeping.funct3 == 3'b000 ) begin
                            mult_FU_out.result <= mult_result[31:0];
                            mult_FU_out.rvfi_mon.rd_wdata <= mult_result[31:0];
                        
                        //MULH
                        end else if(mult_fu_res_station_in.rename_data.book_keeping.funct3 == 3'b001 ) begin
                            mult_FU_out.result <= mult_result[63:32];
                            mult_FU_out.rvfi_mon.rd_wdata <= mult_result[63:32];
                        
                        //MULHSU
                        end else if(mult_fu_res_station_in.rename_data.book_keeping.funct3 == 3'b010) begin
                            mult_FU_out.result <= mult_result[63:32];
                            mult_FU_out.rvfi_mon.rd_wdata <= mult_result[63:32];

                        //MULHU
                        end else if(mult_fu_res_station_in.rename_data.book_keeping.funct3 == 3'b011) begin
                            mult_FU_out.result <= mult_result[63:32];
                            mult_FU_out.rvfi_mon.rd_wdata <= mult_result[63:32];

                        //to prevent latch, default to just getting upper 32 bits 
                        end else begin
                            mult_FU_out.result <= mult_result[63:32];
                            mult_FU_out.rvfi_mon.rd_wdata <= mult_result[63:32];

                        end        
                    end else begin
                        //either divide or rem 
                        if(mult_fu_res_station_in.rename_data.book_keeping.is_rem)begin
                            mult_FU_out.result <= rem_result; 
                            mult_FU_out.rvfi_mon.rd_wdata <= rem_result;
                        end else begin
                            mult_FU_out.result <= div_result; 
                            mult_FU_out.rvfi_mon.rd_wdata <= div_result;
                        end
                    end
                // end
                
                
                // mult_FU_out.misc.pc <= mult_fu_res_station_in.rename_data.book_keeping.pc;  
                mult_FU_out.misc.ps1_value <= mult_fu_res_station_in.ps1_value;
                mult_FU_out.misc.ps2_value <= mult_fu_res_station_in.ps2_value;  

                mult_FU_out.rvfi_mon.valid <= mult_fu_res_station_in.rename_data.rvfi_mon.valid;  
                mult_FU_out.rvfi_mon.order <= mult_fu_res_station_in.rename_data.rvfi_mon.order;  
                mult_FU_out.rvfi_mon.inst <= mult_fu_res_station_in.rename_data.rvfi_mon.inst;  
                mult_FU_out.rvfi_mon.rs1_addr <= mult_fu_res_station_in.rename_data.rvfi_mon.rs1_addr;
                mult_FU_out.rvfi_mon.rs2_addr <= mult_fu_res_station_in.rename_data.rvfi_mon.rs2_addr;
                mult_FU_out.rvfi_mon.rs1_rdata <= mult_fu_res_station_in.ps1_value;
                mult_FU_out.rvfi_mon.rs2_rdata <= mult_fu_res_station_in.ps2_value;
                mult_FU_out.rvfi_mon.rd_addr <= mult_fu_res_station_in.rename_data.rvfi_mon.rd_addr;
                mult_FU_out.rvfi_mon.pc_wdata <= mult_fu_res_station_in.rename_data.rvfi_mon.pc_wdata;  
                mult_FU_out.rvfi_mon.pc_rdata <= mult_fu_res_station_in.rename_data.rvfi_mon.pc_rdata;
                mult_FU_out.rvfi_mon.regf_we <= mult_fu_res_station_in.rename_data.rvfi_mon.regf_we;
                mult_FU_out.rvfi_mon.dmem_addr <= mult_fu_res_station_in.rename_data.rvfi_mon.dmem_addr;
                mult_FU_out.rvfi_mon.dmem_rmask <= mult_fu_res_station_in.rename_data.rvfi_mon.dmem_rmask;
                mult_FU_out.rvfi_mon.dmem_wmask <= mult_fu_res_station_in.rename_data.rvfi_mon.dmem_wmask;
                mult_FU_out.rvfi_mon.dmem_rdata <= mult_fu_res_station_in.rename_data.rvfi_mon.dmem_rdata;
                mult_FU_out.rvfi_mon.dmem_wdata <= mult_fu_res_station_in.rename_data.rvfi_mon.dmem_wdata;
                mult_FU_out.rvfi_mon.rs1_rdata <= mult_fu_res_station_in.ps1_value;
                mult_FU_out.rvfi_mon.rs2_rdata <= mult_fu_res_station_in.ps2_value;



            end 
            else begin
                mult_FU_out.rvfi_mon <= '0;
                mult_FU_out.misc <= '0;

            end 
        

            if(flush) begin
                FU_out.misc <= '0;
                FU_out.rvfi_mon <= '0;
                mult_FU_out.misc <= '0;
                mult_FU_out.rvfi_mon <= '0;
            end




        end
    end



    alu alu1(.*,
            .a(fu_res_station_in.ps1_value), 
             .b(fu_res_station_in.rename_data.book_keeping.use_immediate ? fu_res_station_in.rename_data.immediate : fu_res_station_in.ps2_value), 
             .aluop(fu_res_station_in.rename_data.book_keeping.aluop), 
            //  .f(alu1_res), 
             .f(FU_out.result), 
             .pc(fu_res_station_in.rename_data.rvfi_mon.pc_rdata));

    // alu alu1(.a(fu_res_station_in[0].ps1_value), .b(fu_res_station_in[0].rename_data.book_keeping.use_immediate ? fu_res_station_in[0].rename_data.immediate : fu_res_station_in[0].ps2_value), .aluop(fu_res_station_in[0].rename_data.book_keeping.aluop), .f(alu1_res), .pc(fu_res_station_in[0].rename_data.rvfi_mon.pc_rdata)/*, .in_use(in_use[0])*/);
    // alu alu2(.a(fu_res_station_in[1].ps1_value), .b(fu_res_station_in[1].rename_data.book_keeping.use_immediate ? fu_res_station_in[1].rename_data.immediate : fu_res_station_in[1].ps2_value), .aluop(fu_res_station_in[1].rename_data.book_keeping.aluop), .f(alu2_res), .pc(fu_res_station_in[1].rename_data.rvfi_mon.pc_rdata)/*, .in_use(in_use[1])*/);
    // alu alu3(.a(fu_res_station_in[2].ps1_value), .b(fu_res_station_in[2].rename_data.book_keeping.use_immediate ? fu_res_station_in[2].rename_data.immediate : fu_res_station_in[2].ps2_value), .aluop(fu_res_station_in[2].rename_data.book_keeping.aluop), .f(alu3_res), .pc(fu_res_station_in[2].rename_data.rvfi_mon.pc_rdata)/*, .in_use(in_use[2])*/);
    // alu alu4(.a(fu_res_station_in[3].ps1_value), .b(fu_res_station_in[3].rename_data.book_keeping.use_immediate ? fu_res_station_in[3].rename_data.immediate : fu_res_station_in[3].ps2_value), .aluop(fu_res_station_in[3].rename_data.book_keeping.aluop), .f(alu4_res), .pc(fu_res_station_in[3].rename_data.rvfi_mon.pc_rdata)/*, .in_use(in_use[3])*/);



    shift_sub_divider ssd(.*,
                             .rst(rst || flush),
                             .start(mult_fu_res_station_in.rename_data.valid && mult_fu_res_station_in.rename_data.book_keeping.aluop == alu_div),
                             .div_type(mult_fu_res_station_in.rename_data.book_keeping.mult_type),
                             .a(mult_fu_res_station_in.ps1_value),
                             .b(mult_fu_res_station_in.ps2_value),
                             .q(div_result),
                             .rem(rem_result), 
                            //  .p(mult_FU_out.result),
                             .done(div_done)
                             );

                             
    // shift_add_multiplier sam(.*,
    //                          .rst(rst || flush),
    //                          .start(mult_fu_res_station_in.rename_data.valid && mult_fu_res_station_in.rename_data.book_keeping.aluop == alu_mult),
    //                          .mul_type(mult_fu_res_station_in.rename_data.book_keeping.mult_type),
    //                          .a(mult_fu_res_station_in.ps1_value),
    //                          .b(mult_fu_res_station_in.ps2_value),
    //                          .p(mult_result),
    //                         //  .p(mult_FU_out.result),
    //                          .done(mult_done)
    //                          );
    WallaceTreeMultiplier wallie(.*,
                             .rst(rst || flush),
                             .start(mult_fu_res_station_in.rename_data.valid && mult_fu_res_station_in.rename_data.book_keeping.aluop == alu_mult),
                             .mul_type(mult_fu_res_station_in.rename_data.book_keeping.mult_type),
                             .a(mult_fu_res_station_in.ps1_value),
                             .b(mult_fu_res_station_in.ps2_value),
                             .p(mult_result),
                            //  .p(mult_FU_out.result),
                             .done(mult_done)
                                );

    assign clear_out = (mult_fu_res_station_in.rename_data.valid && mult_done && ! div_done) || (mult_fu_res_station_in.rename_data.valid && div_done && !mult_done);


    assign issue_mult = (!mult_done && !mult_fu_res_station_in.rename_data.valid) ||  (mult_done && mult_fu_res_station_in.rename_data.valid) ||
                        (!div_done && !mult_fu_res_station_in.rename_data.valid) ||  (div_done && mult_fu_res_station_in.rename_data.valid);




endmodule