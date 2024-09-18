module mult_reservation_station
import rv32i_types::*;
(
    input   logic              clk,
    input   logic              rst,
    input   logic              flush,
    input   cdb_entry_t        cdb_entry,
    input   rename_data_t      rename_data_in,
    input   logic              rs_dispatch,
    input   logic              issue_mult,
    input   logic              clear_out,
    input   logic               mult_cdb_sent,
    output  logic              rs_open,
    output  rename_data_t      res_station_rename_data_out


);

    rename_data_t res_station_rename_data [4];
    logic [1:0]  open_station;
    logic [1:0]  issue_station;
    
    logic res_station_rename_data_valid_0;
    logic res_station_rename_data_valid_1;
    logic res_station_rename_data_valid_2;
    logic res_station_rename_data_valid_3;
    logic [3:0] valid_bits;
   
   
    assign res_station_rename_data_valid_0 = res_station_rename_data[0].valid && res_station_rename_data[0].ps1_v && res_station_rename_data[0].ps2_v;
    assign res_station_rename_data_valid_1 = res_station_rename_data[1].valid && res_station_rename_data[1].ps1_v && res_station_rename_data[1].ps2_v;
    assign res_station_rename_data_valid_2 = res_station_rename_data[2].valid && res_station_rename_data[2].ps1_v && res_station_rename_data[2].ps2_v;
    assign res_station_rename_data_valid_3 = res_station_rename_data[3].valid && res_station_rename_data[3].ps1_v && res_station_rename_data[3].ps2_v;

    // check for coremark
    assign valid_bits = {res_station_rename_data_valid_3,res_station_rename_data_valid_2,res_station_rename_data_valid_1,res_station_rename_data_valid_0} & {issue_mult & !clear_out,issue_mult & !clear_out,issue_mult & !clear_out,issue_mult & !clear_out};


    always_ff @(posedge clk) begin
        if(rst) begin
            res_station_rename_data <= '{default:0};
            res_station_rename_data_out <= '0;

        end else begin
            if(rs_open && rs_dispatch) begin
                res_station_rename_data[open_station] <= rename_data_in;
            end

            if(cdb_entry.pd == res_station_rename_data[0].ps1 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[0].ps1_v <= 1'b1;
            end
            if(cdb_entry.pd == res_station_rename_data[0].ps2 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[0].ps2_v <= 1'b1;
            end

            if(cdb_entry.pd == res_station_rename_data[1].ps1 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[1].ps1_v <= 1'b1;
            end
            if(cdb_entry.pd == res_station_rename_data[1].ps2 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[1].ps2_v <= 1'b1;
            end

            if(cdb_entry.pd == res_station_rename_data[2].ps1 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[2].ps1_v <= 1'b1;
            end
            if(cdb_entry.pd == res_station_rename_data[2].ps2 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[2].ps2_v <= 1'b1;
            end

            if(cdb_entry.pd == res_station_rename_data[3].ps1 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[3].ps1_v <= 1'b1;
            end
            if(cdb_entry.pd == res_station_rename_data[3].ps2 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                res_station_rename_data[3].ps2_v <= 1'b1;
            end


            unique case(issue_station)
                2'b00: begin
                    res_station_rename_data_out <= res_station_rename_data[0];
                    res_station_rename_data[0] <= '0;
                end
                2'b01: begin
                    res_station_rename_data_out <= res_station_rename_data[1];
                    res_station_rename_data[1] <= '0;
                end
                2'b10: begin
                    res_station_rename_data_out <= res_station_rename_data[2];
                    res_station_rename_data[2] <= '0;
                end
                2'b11: begin
                    res_station_rename_data_out <= res_station_rename_data[3];
                    res_station_rename_data[3] <= '0;
                end
                default: begin
                    if(clear_out && mult_cdb_sent) begin
                        res_station_rename_data_out <= '0;
                    end
                end
            endcase

            if(flush) begin
                res_station_rename_data <= '{default:0};
                res_station_rename_data_out <= '0;
            end

        end
    end



    always_comb begin
        issue_station = 'x;

        unique case(valid_bits)
            4'b0000: issue_station = 'x;
            4'b0001: issue_station = 2'b00;
            4'b0010: issue_station = 2'b01;
            4'b0011: begin
                if(res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[1].rvfi_mon.order) begin
                    issue_station = 2'b00;
                end else begin
                    issue_station = 2'b01;
                end
            end
            4'b0100: issue_station = 2'b10;
            4'b0101: begin
                if(res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order) begin
                    issue_station = 2'b00;
                end else begin
                    issue_station = 2'b10;
                end
            end
            4'b0110: begin
                if(res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order) begin
                    issue_station = 2'b01;
                end else begin
                    issue_station = 2'b10;
                end
            end
            4'b0111: begin
                if(res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[1].rvfi_mon.order 
                && res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order) begin
                    issue_station = 2'b00;
                end else if(res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[0].rvfi_mon.order 
                && res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order) begin
                    issue_station = 2'b01;
                end else begin
                    issue_station = 2'b10;
                end
            end
            4'b1000: issue_station = 2'b11;
            4'b1001: begin
                if(res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b00;
                end else begin
                    issue_station = 2'b11;
                end
            end
            4'b1010: begin
                if(res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b01;
                end else begin
                    issue_station = 2'b11;
                end
            end
            4'b1011: begin
                if(res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[1].rvfi_mon.order 
                && res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b00;
                end else if(res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[0].rvfi_mon.order 
                && res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b01;
                end else begin
                    issue_station = 2'b11;
                end
            end
            4'b1100: begin
                if(res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b10;
                end else begin
                    issue_station = 2'b11;
                end
            end
            4'b1101: begin
                if(res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order 
                && res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b00;
                end else if(res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[0].rvfi_mon.order 
                && res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b10;
                end else begin
                    issue_station = 2'b11;
                end
            end
            4'b1110: begin
                if(res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order 
                && res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b01;
                end else if(res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[1].rvfi_mon.order 
                && res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b10;
                end else begin
                    issue_station = 2'b11;
                end
            end
            4'b1111: begin
                if(res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[1].rvfi_mon.order 
                && res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order
                && res_station_rename_data[0].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b00;
                end else if(res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[0].rvfi_mon.order 
                && res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[2].rvfi_mon.order
                && res_station_rename_data[1].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b01;
                end else if(res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[0].rvfi_mon.order 
                && res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[1].rvfi_mon.order
                && res_station_rename_data[2].rvfi_mon.order < res_station_rename_data[3].rvfi_mon.order) begin
                    issue_station = 2'b10;
                end else begin
                    issue_station = 2'b11;
                end
            end
            default: issue_station = 'x;
        endcase




    end

    always_comb begin
        rs_open = 1'b0; // RS must be closed
        open_station = 2'b00;
        if(!res_station_rename_data[0].valid) begin
            rs_open = 1'b1;
            open_station = 2'b00;
        end else if(!res_station_rename_data[1].valid) begin
            rs_open = 1'b1;
            open_station = 2'b01;
        end else if(!res_station_rename_data[2].valid) begin
            rs_open = 1'b1;
            open_station = 2'b10;
        end else if(!res_station_rename_data[3].valid) begin
            rs_open = 1'b1;
            open_station = 2'b11;
        end
    end



endmodule