module retired_rat
import rv32i_types::*;
(
        //ASSUME WE HAVE 64 PHYSICAL REGISTERS FOR NOW
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we,
    input   logic           freelist_full,
    input   logic   [4:0]   rd, 
    input   logic   [5:0]   pd, 
    output  logic   [5:0]   old_ps_idx,
    output  logic           enqueue,
    output  logic   [5:0]   arc_reg_out [32]
);
    logic   [5:0]  arc_reg       [32];
    
    assign arc_reg_out = arc_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            // for (logic  [5:0] i = 6'b0; i < 6'd32; i = i + 1'b1) begin
            //     arc_reg[i] <=  i; // initially map 1:1 to physical index 
            //     old_ps_idx <= '0; // might need to be 'x instead
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

            //  old_ps_idx <= '0; // might need to be 'x instead
        end else begin
            if(regf_we && rd != 5'd0) begin 
                // old_ps_idx <= arc_reg[rd];
                arc_reg[rd] <= pd;
            end else begin
                arc_reg[rd] <= arc_reg[rd]; 
            end
        end
    end

    always_comb begin
        // if (rst) begin
        //    enqueue = '0;  
        // end else begin
        //     // if we get a regf_we and rd isnt 0, we need to save evicted PRI and flag 
        //     // enqueue signal for freelist 
        // end
        enqueue = (regf_we && (rd != 5'd0) && !freelist_full);
        old_ps_idx  = enqueue ? arc_reg[rd] : 'x;
    end


endmodule