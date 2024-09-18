module memory_unit
import rv32i_types::*;
(  
    input logic             clk,
    input logic             rst,
    input logic             flush,
    input logic             lsq_cdb_sent,
    input logic     [31:0]  mem_ps1_v,
    input logic     [31:0]  mem_ps2_v,
    //input entry dequeued from the LSQ 
    input   rename_data_t   lsq_entry,
    //ports for cache 
    input   logic   [31:0]  dmem_rdata,
    input   logic           dmem_resp,
    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    output  logic   [31:0]  dmem_wdata,
    output  mem_entry_t   lsq_entry_out

);

    // rename_data_t   lsq_entry_temp; 

    logic [31:0] mem_addr;
    logic        sb_full; 
    logic        sb_empty; 
    logic        sb_match; 
    logic [31:0] sb_rdata; 
    
    always_comb begin
        mem_addr = '0; 
        if(lsq_entry.book_keeping.is_store)begin
            mem_addr = mem_ps1_v + lsq_entry.immediate; 
        end else if(lsq_entry.book_keeping.is_load)begin
            mem_addr = mem_ps1_v + lsq_entry.immediate; 
        end 
    end

    //add mask logic  
    //add same write addr  
    store_buffer buffy(
        .*, 
        .enqueue (lsq_entry.book_keeping.is_store && lsq_entry.valid && dmem_resp),
        .dequeue (lsq_entry.book_keeping.is_store && lsq_entry.valid && sb_full),
        .store_addr({mem_addr[31:2], 2'b00} & {{31{1'b0}},lsq_entry.book_keeping.is_store}),
        .wdata(dmem_wdata),
        .wmask(dmem_wmask), 
        .rmask(dmem_rmask), 
        .load_addr({mem_addr[31:2], 2'b00} & {{31{1'b0}},lsq_entry.book_keeping.is_load}), 
        .r_data(sb_rdata), 
        .is_empty(sb_empty), 
        .is_full(sb_full)
    );


    always_comb begin 
        
        //do i need to align??
        // dmem_addr = {mem_addr[31:2], 2'b00};
    
        //default values
        dmem_wdata = 32'd0; 
        dmem_rmask = 4'd0;
        dmem_wmask = 4'b0000;
        
        if(lsq_entry.book_keeping.is_load)begin
            if(mem_addr[1:0] >= 2'b0) begin
                unique case (lsq_entry.book_keeping.funct3)
                    // 2. set rmask   
                    lb, lbu: dmem_rmask = 4'b0001 << mem_addr[1:0];
                    lh, lhu: dmem_rmask = 4'b0011 << mem_addr[1:0];
                    lw:      dmem_rmask = 4'b1111;
                    default: dmem_rmask = 4'b0000;
                endcase
            end
        end else begin
            dmem_rmask = 4'b000; 
        end
        
        if (lsq_entry.book_keeping.is_store)begin
            unique case (lsq_entry.book_keeping.funct3)
                sb: dmem_wmask = 4'b0001 << mem_addr[1:0];
                sh: dmem_wmask = 4'b0011 << mem_addr[1:0];
                sw: dmem_wmask = 4'b1111;
                default: dmem_wmask = '0;
            endcase

            unique case (lsq_entry.book_keeping.funct3)
                sb: dmem_wdata[8 *mem_addr[1:0] +: 8 ] = mem_ps2_v[7 :0];
                sh: dmem_wdata[16*mem_addr[1]   +: 16] = mem_ps2_v[15:0];
                sw: dmem_wdata = mem_ps2_v;
                default: dmem_wdata = 'x;
            endcase   
        end else begin
            dmem_wmask = 4'b0000; 
        end

        // if(!sb_match) begin
        dmem_addr = !sb_match ? {mem_addr[31:2], 2'b00} : '0;
        // end
        //get at commit when we get dmem resp 
    end

    mod_mem_entry_t temp;
    

    always_ff @(posedge clk) begin
        if(rst) begin
            lsq_entry_out <= '0;
            temp <= '0;
        end else begin

            if(lsq_entry.book_keeping.is_store) begin
                if(dmem_resp) begin
                    lsq_entry_out.rename_data <= lsq_entry; 
                    lsq_entry_out.rename_data.rvfi_mon.dmem_addr <= dmem_addr;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_wmask <= dmem_wmask;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_rmask <= dmem_rmask;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_wdata <= dmem_wdata;
                    lsq_entry_out.rename_data.rvfi_mon.rs1_rdata <= mem_ps1_v;
                    lsq_entry_out.rename_data.rvfi_mon.rs2_rdata <= mem_ps2_v;
                    lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= dmem_rdata;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= dmem_rdata;
                    lsq_entry_out.result <= dmem_rdata;  
                end
            end else if(lsq_entry.book_keeping.is_load || temp.mem_entry.rename_data.valid)begin

                if(dmem_resp && !sb_match)begin 
                // if(dmem_resp)begin 


                    lsq_entry_out.rename_data <= temp.mem_entry.rename_data; 
                    unique case (temp.mem_entry.rename_data.book_keeping.funct3)
                        lb : begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{24{dmem_rdata[7 +8 *temp.mem_addr[1:0]]}}, dmem_rdata[8 *temp.mem_addr[1:0] +: 8 ]};

                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= dmem_rdata;
                            lsq_entry_out.result <= {{24{dmem_rdata[7 +8 *temp.mem_addr[1:0]]}}, dmem_rdata[8 *temp.mem_addr[1:0] +: 8 ]};    
         
                        end
                        lbu: begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{24{1'b0}}, dmem_rdata[8 *temp.mem_addr[1:0] +: 8 ]};
                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= dmem_rdata;
                            lsq_entry_out.result <= {{24{1'b0}}, dmem_rdata[8 *temp.mem_addr[1:0] +: 8 ]};
                        end
                        lh : begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{16{dmem_rdata[15+16*temp.mem_addr[1]  ]}}, dmem_rdata[16*temp.mem_addr[1] +: 16]};
                            
                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= dmem_rdata;
                            lsq_entry_out.result <= {{16{dmem_rdata[15+16*temp.mem_addr[1]]}}, dmem_rdata[16*temp.mem_addr[1] +: 16]};
                        end
                        lhu: begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{16{1'b0}}, dmem_rdata[16*temp.mem_addr[1] +: 16]};

                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= dmem_rdata;
                            lsq_entry_out.result <= {{16{1'b0}}, dmem_rdata[16*temp.mem_addr[1] +: 16]};
                        end
                        lw : begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= dmem_rdata;
                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <=  dmem_rdata;
                            lsq_entry_out.result <=  dmem_rdata;
                        end
                        default: lsq_entry_out.rename_data.rvfi_mon.rd_wdata  <= '0;
                    endcase

                    // // lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= dmem_rdata;
                    // lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= dmem_rdata;
                    // lsq_entry_out.result <= dmem_rdata;    
                    lsq_entry_out.rename_data.rvfi_mon.dmem_addr <= temp.mem_entry.rename_data.rvfi_mon.dmem_addr;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_wmask <= temp.mem_entry.rename_data.rvfi_mon.dmem_wmask;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_rmask <= temp.mem_entry.rename_data.rvfi_mon.dmem_rmask;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_wdata <= temp.mem_entry.rename_data.rvfi_mon.dmem_wdata;
                    lsq_entry_out.rename_data.rvfi_mon.rs1_rdata <= temp.mem_entry.rename_data.rvfi_mon.rs1_rdata;
                    lsq_entry_out.rename_data.rvfi_mon.rs2_rdata <= temp.mem_entry.rename_data.rvfi_mon.rs2_rdata;
                end 
                else if(sb_match && !dmem_resp)begin 
                    // lsq_entry_out.rename_data <= temp.mem_entry.rename_data; 
                    lsq_entry_out.rename_data <= lsq_entry; 
                    unique case (lsq_entry.book_keeping.funct3)
                        lb : begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{24{sb_rdata[7 +8 *mem_addr[1:0]]}}, sb_rdata[8 *mem_addr[1:0] +: 8 ]};

                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= sb_rdata;
                            lsq_entry_out.result <= {{24{sb_rdata[7 +8 *mem_addr[1:0]]}}, sb_rdata[8 *mem_addr[1:0] +: 8 ]};    
        
                        end
                        lbu: begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{24{1'b0}}, sb_rdata[8 *mem_addr[1:0] +: 8 ]};
                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= sb_rdata;
                            lsq_entry_out.result <= {{24{1'b0}}, sb_rdata[8 *mem_addr[1:0] +: 8 ]};
                        end
                        lh : begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{16{sb_rdata[15+16*mem_addr[1]  ]}}, sb_rdata[16*mem_addr[1] +: 16]};
                            
                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= sb_rdata;
                            lsq_entry_out.result <= {{16{sb_rdata[15+16*mem_addr[1]]}}, sb_rdata[16*mem_addr[1] +: 16]};
                        end
                        lhu: begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= {{16{1'b0}}, sb_rdata[16*mem_addr[1] +: 16]};

                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <= sb_rdata;
                            lsq_entry_out.result <= {{16{1'b0}}, sb_rdata[16*mem_addr[1] +: 16]};
                        end
                        lw : begin 
                            lsq_entry_out.rename_data.rvfi_mon.rd_wdata <= sb_rdata;
                            lsq_entry_out.rename_data.rvfi_mon.dmem_rdata <=  sb_rdata;
                            lsq_entry_out.result <=  sb_rdata;
                        end
                        default: lsq_entry_out.rename_data.rvfi_mon.rd_wdata  <= '0;
                    endcase


                    lsq_entry_out.rename_data.rvfi_mon.dmem_addr <= {mem_addr[31:2], 2'b00};
                    lsq_entry_out.rename_data.rvfi_mon.dmem_wmask <= dmem_wmask;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_rmask <= dmem_rmask;
                    lsq_entry_out.rename_data.rvfi_mon.dmem_wdata <= dmem_wdata;
                    lsq_entry_out.rename_data.rvfi_mon.rs1_rdata <= mem_ps1_v;
                    lsq_entry_out.rename_data.rvfi_mon.rs2_rdata <= mem_ps2_v;
                
            end 
            else begin
                    temp.mem_entry.rename_data <= lsq_entry; 
                    temp.mem_entry.rename_data.rvfi_mon.dmem_addr <= dmem_addr;
                    temp.mem_entry.rename_data.rvfi_mon.dmem_wmask <= dmem_wmask;
                    temp.mem_entry.rename_data.rvfi_mon.dmem_rmask <= dmem_rmask;
                    temp.mem_entry.rename_data.rvfi_mon.dmem_wdata <= dmem_wdata;
                    temp.mem_entry.rename_data.rvfi_mon.rs1_rdata <= mem_ps1_v;
                    temp.mem_entry.rename_data.rvfi_mon.rs2_rdata <= mem_ps2_v;
                    temp.mem_addr <= mem_addr;

                end
            end else begin
                if(lsq_cdb_sent) begin
                    lsq_entry_out <= '0;
                    temp <= '0;
                end
            end

        end

        if(flush) begin
            lsq_entry_out <= '0;
            temp <= '0;
        end

    end


endmodule