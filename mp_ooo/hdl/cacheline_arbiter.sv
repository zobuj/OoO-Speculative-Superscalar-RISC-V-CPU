module cacheline_arbiter(
    //I-CACHE PORTS
    input  logic            clk,
    input  logic            rst,
    input  logic            flush,
    input  logic    [31:0]  i_dfp_addr,
    input  logic            i_dfp_read,
    // input  logic            i_dfp_write,
    output logic    [255:0] i_dfp_rdata,
    // input  logic    [255:0] i_dfp_wdata,
    output logic            i_dfp_resp,
    //D-CACHE PORTS
    input  logic    [31:0]  d_dfp_addr,
    input  logic            d_dfp_read,
    input  logic            d_dfp_write,
    output logic    [255:0] d_dfp_rdata,
    input  logic    [255:0] d_dfp_wdata,
    output logic            d_dfp_resp,
    //CLA PORTS
    output  logic   [31:0]  cla_addr,
    output  logic           cla_read,
    output  logic           cla_write,
    input   logic   [255:0] cla_rdata,
    output  logic   [255:0] cla_wdata,
    input   logic   [31:0]  cla_raddr,
    input   logic           cla_resp,
    output  logic           invalid_cpu_request
    
);

    logic [31:0] dummy_cla_raddr;
    assign dummy_cla_raddr = cla_raddr;

    logic [1:0] cache_serviced;

    assign invalid_cpu_request = flush ? 1'b1 : 1'b0;

    always_ff @(posedge clk) begin
        if(rst) begin
            cache_serviced <= 2'b10;
        end else begin
            if(cache_serviced == 2'b10) begin
                unique case({i_dfp_read,(d_dfp_read | d_dfp_write)})
                    2'b00: cache_serviced <= 2'b10;
                    2'b01: cache_serviced <= 2'b01; // data cache
                    2'b10: cache_serviced <= 2'b00; // instruction cache
                    2'b11: cache_serviced <= 2'b01; // data cache
                endcase
            end else begin
                if(cla_resp) begin
                    cache_serviced <= 2'b10;
                end
            end


            if(flush) begin
                cache_serviced <= 2'b10;
            end
        end
    end

    
    always_comb begin
        i_dfp_rdata = 'x;
        i_dfp_resp = '0;
        d_dfp_rdata = 'x;
        d_dfp_resp = '0;
        cla_addr = '0;
        cla_read = '0;
        cla_write = '0;
        cla_wdata = 'x;

        if(!cache_serviced[1]) begin
            if(cache_serviced[0] == 1'b0) begin
                // Instruction cache
                cla_addr = i_dfp_addr;
                cla_read = i_dfp_read;
                if(cla_resp && cla_addr == cla_raddr) begin // dram mem resp
                    cla_read = 1'b0;
                    i_dfp_rdata = cla_rdata;
                    i_dfp_resp = cla_resp;
                end
            end else if(cache_serviced[0] == 1'b1) begin
                // Data Cache
                if(d_dfp_read) begin
                    cla_addr = d_dfp_addr;
                    cla_read = d_dfp_read;
                    if(cla_resp) begin
                        cla_read = 1'b0;
                        d_dfp_rdata = cla_rdata;
                        d_dfp_resp  = cla_resp;
                    end
                end else if(d_dfp_write) begin
                    cla_addr = d_dfp_addr;
                    cla_write = d_dfp_write;
                    cla_wdata = d_dfp_wdata; // if the cache is writing then it should be set before we respond?
                    if(cla_resp)begin
                        cla_write = 1'b0;
                        d_dfp_resp = cla_resp;
                    end
                end
            end
        end else begin
            i_dfp_rdata = 'x;
            i_dfp_resp = '0;
            d_dfp_rdata = 'x;
            d_dfp_resp = '0;
            cla_addr = '0;
            cla_read = '0;
            cla_write = '0;
            cla_wdata = 'x;
        end

    end

endmodule