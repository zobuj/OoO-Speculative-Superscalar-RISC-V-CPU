module cacheline_adaptor(
    //BURST PORTS
    input   logic               clk,
    input   logic               rst,
    input   logic               invalid_cpu_request,
    
    // CLA PORTS
    input   logic   [31:0]      cla_addr,
    input   logic               cla_read,
    input   logic               cla_write,
    output  logic   [255:0]     cla_rdata,
    input   logic   [255:0]     cla_wdata,
    output  logic               cla_resp,
    output  logic   [31:0]      cla_raddr,//from bmem to arbiter?
    

    input   logic               bmem_ready,
    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid,
    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata
    
);

// idle
// one for each burst
// one request at a time

    enum logic [3:0] {
        idle,
        write_1,
        write_2,
        write_3,
        read_1,
        read_2,
        read_3,
        read_4
    } state, state_next;

    logic cla_rdata_write;
    always_ff @(posedge clk) begin 
        if(rst) begin
            state <= idle;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        // cla_raddr = bmem_raddr;
        bmem_addr = '0;
        bmem_read = '0;
        bmem_write = '0;
        bmem_wdata = '0;
        state_next = state;
        // cla_resp = '0;
        // cla_raddr = 'x;
        cla_rdata_write = '0;
                
        
        case (state)
            idle: begin
                bmem_addr = '0;
                bmem_read = '0;
                bmem_write = '0;
                bmem_wdata = '0;
                state_next = idle;
                // cla_resp = '0;
                // cla_raddr = 'x;
                
                if(cla_read && bmem_ready && !invalid_cpu_request) begin
                    bmem_addr = cla_addr;
                    bmem_read = 1'b1;
                    state_next = read_1;
                end else if(cla_write && bmem_ready && !invalid_cpu_request) begin
                    bmem_addr = cla_addr;
                    bmem_write = 1'b1;
                    bmem_wdata = cla_wdata[63:0];
                    state_next = write_1;
                end else begin
                    state_next = idle;
                end
            end
            write_1: begin
                if(invalid_cpu_request) begin
                    bmem_write = '0;
                    bmem_addr = '0;
                    bmem_wdata = '0;
                    state_next = idle;
                end else begin
                    bmem_write = 1'b1;
                    bmem_addr = cla_addr;
                    bmem_wdata = cla_wdata[127:64];
                    if(bmem_ready) begin
                        state_next = write_2;
                    end
                end
            end
            write_2: begin
                // if(invalid_cpu_request) begin
                //     bmem_write = '0;
                //     bmem_addr = '0;
                //     bmem_wdata = '0;
                //     state_next = idle;
                // end else begin
                
                // end
                bmem_write = 1'b1;
                bmem_addr = cla_addr;
                bmem_wdata = cla_wdata[191:128];
                if(bmem_ready) begin
                    state_next = write_3;
                end
            end
            write_3: begin
                bmem_write = 1'b1;
                bmem_addr = cla_addr;
                bmem_wdata = cla_wdata[255:192];
                if(bmem_ready) begin
                    // cla_resp = 1'b1;
                    state_next = idle;
                end
            end
            read_1: begin
                bmem_read = 1'b0;
                bmem_addr = '0;
                if(bmem_rvalid) begin
                    state_next = read_2;
                    cla_rdata_write = 1'b1;
                end else begin
                    state_next = read_1;
                end 
            end
            read_2: begin
                state_next = read_3;
                cla_rdata_write = 1'b1;
            end
            read_3: begin   
                state_next = read_4;
                cla_rdata_write = 1'b1;
            end
            read_4: begin
                state_next = idle;
                cla_rdata_write = 1'b1;
                // cla_resp = 1'b1;
            end
        endcase
    end
    always_ff @ (posedge clk) begin
        if(cla_rdata_write) begin
            unique case(state) 
                read_1: cla_rdata[63:0] <= bmem_rdata;
                read_2: cla_rdata[127:64] <= bmem_rdata;
                read_3: cla_rdata[191:128] <= bmem_rdata;
                read_4: cla_rdata[255:192] <= bmem_rdata;
                default: cla_rdata <= '0;
            endcase
        end
    end


    always_ff @ (posedge clk) begin
        if(rst) begin
            cla_resp <= '0;
            cla_raddr <= '0;
        end else begin

        unique case(state)
            idle: begin
                cla_resp <= 1'b0;
                cla_raddr <= 'x;
            end
            write_3: begin
                cla_resp <= 1'b1;
                cla_raddr <= bmem_raddr;
            end
            read_4: begin
                cla_resp <= 1'b1;
                cla_raddr <= bmem_raddr;
            end
            default: begin
                cla_resp <= 1'b0;
                cla_raddr <= 'x;
            end
        endcase

        end
    end


endmodule