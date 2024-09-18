module control
#(parameter NUM_SETS = 16, SET_BITS = 4, TAG_BITS = 23)(
    input   logic           clk,
    input   logic           rst,
    input   logic   [4:0]   req_addr_offset,
    input   logic   [(TAG_BITS-1):0]  req_addr_tag,
    input   logic   [(SET_BITS-1):0]   req_addr_set, //change 3 to log2(num of sets) 
    input   logic           valid_cpu_request,
    input   logic           hit,
    input   logic   [1:0]   plru_replace_index[NUM_SETS], // change 16 to num of sets parameter 
    input   logic   [1:0]   way,
    input   logic   [3:0]   ufp_wmask,
    input   logic   [31:0]  padded_ufp_wmask,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [255:0] padded_ufp_wdata,
    input   logic   [31:0]  ufp_addr,
    input   logic           dfp_resp,
    input   logic   [23:0]  tag_out[4],
    input   logic   [255:0] data_out[4],
    input   logic           valid_out[4],
    input   logic   [255:0] dfp_rdata,
    output  logic   [TAG_BITS:0]  tag_in[4], //no need for -1 since extra bit is for dirty bit 
    output  logic           tag_we[4],
    output  logic   [255:0] data_in[4],
    output  logic           data_we[4],
    output  logic           valid_in[4],
    output  logic           valid_we[4],
    output  logic           update_rdata,
    output  logic   [31:0]  data_wmask,
    output  logic           update_tree,
    output  logic           ufp_resp,
    output  logic           dfp_read,
    output  logic           dfp_write,
    output  logic   [255:0] dfp_wdata,
    output  logic   [31:0]  dfp_addr
);


    enum logic [1:0]{
        idle,
        compare_tag,
        allocate,
        write_back
    } state, next_state;


    always_ff @(posedge clk) begin 
        if(rst) begin
            state <= idle;
        end else begin 
            state <= next_state;
        end
    end


    always_comb begin
        ufp_resp = 1'b0;
        next_state = idle;
        tag_in[0] = '0;
        tag_in[1] = '0;
        tag_in[2] = '0;
        tag_in[3] = '0;

        data_in[0] = '0;
        data_in[1] = '0;
        data_in[2] = '0;
        data_in[3] = '0;

        valid_in[0] = '0;
        valid_in[1] = '0;
        valid_in[2] = '0;
        valid_in[3] = '0;

        update_rdata = 1'b0;
        data_wmask = '0;

        // Set Write Enable to Low
        valid_we[0] = 1'b1;
        valid_we[1] = 1'b1;
        valid_we[2] = 1'b1;
        valid_we[3] = 1'b1;

        data_we[0] = 1'b1;
        data_we[1] = 1'b1;
        data_we[2] = 1'b1;
        data_we[3] = 1'b1;

        tag_we[0] = 1'b1;
        tag_we[1] = 1'b1;
        tag_we[2] = 1'b1;
        tag_we[3] = 1'b1;

        dfp_addr = '0;
        dfp_read = 1'b0;
        dfp_write = 1'b0;
        dfp_wdata = '0;

        update_tree = 1'b0;

        case(state)
            idle: begin
                // Waiting for request
                if(valid_cpu_request) begin
                    next_state = compare_tag; // recived valid read or write request from CPU
                end else begin
                    next_state = idle; // maintain state while waiting
                end
            end
            compare_tag: begin 
                if(!valid_cpu_request) begin
                    next_state = idle;
                end else begin
                    if(hit) begin
                        update_tree = 1'b1;
                        if(ufp_wmask != 4'b0000) begin
                            tag_we[way] = 1'b0;
                            valid_we[way] = 1'b0;
                            data_we[way] = 1'b0;

                            tag_in[way][TAG_BITS] = 1'b1; // dirty bit is set
                            tag_in[way][(TAG_BITS-1):0] = req_addr_tag;
                            valid_in[way] = 1'b1; // valid bit is set
                            data_wmask = padded_ufp_wmask << (req_addr_offset); // set the write mask
                            data_in[way] = padded_ufp_wdata << ((req_addr_offset) * 8); // Shifting write data to correct location (offset (byte) * sizeof(byte))
                        end else if(ufp_rmask != 4'b0000) begin
                            update_rdata = 1'b1;
                        end
                        next_state = idle;
                        ufp_resp = 1'b1;
                    end else begin
                        // Miss
                        if(valid_out[plru_replace_index[req_addr_set]]) begin
                            if(tag_out[plru_replace_index[req_addr_set]][23] == 1'b1) begin
                                // Dirty bit is on
                                next_state = write_back;
                            end else begin
                                // Dirty bit is off
                                next_state = allocate;
                            end
                        end else begin
                            // Compulsory Miss
                            next_state = allocate;
                        end
                    end
                end
            end
            allocate: begin
                if(!valid_cpu_request) begin
                    next_state = idle;
                end else begin
                    dfp_addr = {ufp_addr[31:5],5'b00000};
                    dfp_read = 1'b1;
                    if(dfp_resp) begin
                        // Set the new data to be replaced
                        data_we[plru_replace_index[req_addr_set]] = 1'b0;
                        data_wmask = '1; // write the entire 256 bit block
                        data_in[plru_replace_index[req_addr_set]] = dfp_rdata;

                        // Set Tag and Valid Bit
                        tag_we[plru_replace_index[req_addr_set]] = 1'b0;
                        valid_we[plru_replace_index[req_addr_set]] = 1'b0;
                            
                        tag_in[plru_replace_index[req_addr_set]][(TAG_BITS-1):0] = req_addr_tag;
                        tag_in[plru_replace_index[req_addr_set]][TAG_BITS] = 1'b0;
                        valid_in[plru_replace_index[req_addr_set]] = 1'b1;
                        
                        next_state = idle;
                    end else begin
                        next_state = allocate;
                    end
                end
            end
            write_back: begin
                 if(!valid_cpu_request) begin
                    next_state = idle;
                end else begin
                    dfp_addr = {tag_out[plru_replace_index[req_addr_set]][(TAG_BITS-1):0],req_addr_set,5'b00000};
                    dfp_write = 1'b1;
                    dfp_wdata = data_out[plru_replace_index[req_addr_set]];
                    if(dfp_resp) begin
                        next_state = allocate;
                    end else begin
                        next_state = write_back;
                    end
                end
            end
        endcase
    end
    




endmodule
