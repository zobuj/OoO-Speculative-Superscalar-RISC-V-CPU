module fetch
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           iq_is_full,
    input   logic           flush,
    input   logic   [31:0]  branch_pc,
    input   logic   [63:0]  branch_order,
    // input   logic           iq_is_almost_full,
    input   logic           imem_resp, // might need for new mem model
    output  logic   [3:0]   imem_rmask,
    output  logic   [31:0]  imem_addr,
    output  inst_info_t     inst_info,
    output  logic           iq_enqueue
);

    logic   [31:0]  pc;
    logic   [31:0]  pc_next;
    logic   [63:0]  order;
    logic   [63:0]  order_next;
    always_ff  @(posedge clk) begin
        if(rst) begin
            pc <= 32'h60000000; // Starting Address for Instruction Memory
            order <= '0;
        end else begin 
            if((!iq_is_full && imem_resp) || flush) begin // make sure that this works not sure yet but coremark works
                pc <= pc_next;
                order <= order_next;
            end 
        end 
        
    end


    always_comb begin
        // if(iq_is_full) begin
        //     pc_next = pc; // Stall PC while the IQ is full
        // end else begin
        // end

        unique case(flush)
            1'b0: order_next = order + 1'b1;
            1'b1: order_next = branch_order + 1'b1;
            default: ;
        endcase


        unique case(flush)
            1'b0: pc_next = pc + 'd4;
            1'b1: pc_next = branch_pc;
            default: ;
        endcase 

        if(iq_is_full) begin
            imem_addr = pc - 4;
        end else begin
            imem_addr = pc;
        end

        if(flush || iq_is_full) begin
            imem_rmask = 4'h0;
        end else begin
            imem_rmask = 4'hf;
        end


        // if(iq_is_full && imem_resp) begin
        //     // Queue is full, dont enqueue
        //     inst_info = 'x;
        //     iq_enqueue = 1'b0;
        // end else begin
            // Queue is empty, enqueue
            inst_info.pc = pc;
            inst_info.pc_next = pc_next;
            inst_info.order = order;
            iq_enqueue = 1'b1;
        

    end


endmodule