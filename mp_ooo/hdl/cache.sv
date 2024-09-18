module cache 
#(parameter NUM_SETS = 16, SET_BITS = 4, TAG_BITS = 23)
(
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);
    // localparam TAG_BITS = 32-(NUM_SETS + 5);
    logic valid_we[4]; // Active low
    logic valid_in[4];
    logic valid_out[4];

    logic data_we[4];
    logic [255:0] data_in[4];
    logic [255:0] data_out[4];

    logic tag_we[4];
    logic [TAG_BITS:0] tag_in[4];
    logic [TAG_BITS:0] tag_out[4];

    logic hit;
    logic [1:0] way;

    logic [(TAG_BITS -1):0] req_addr_tag;
    logic [(SET_BITS-1):0] req_addr_set;
    logic [4:0] req_addr_offset;
    logic [255:0] padded_ufp_wdata;
    logic [31:0] padded_ufp_wmask;

    logic [31:0] data_wmask;

    // Index to Replace
    logic [1:0] plru_replace_index[NUM_SETS];
    logic [2:0] plru_tree[NUM_SETS];

    // Control Unit Signals
    logic valid_cpu_request;
    logic update_rdata;
    logic update_tree;

    // Cache Output
    logic [3:0]   data_select;
    logic [255:0] cache_data;

    always_comb begin
        // Extract information from CPU
        // req_addr_tag = ufp_addr[31:9];// set bits + 1 
        // req_addr_set = ufp_addr[8:5]; // change to set bits log2(num of sets) 

        req_addr_tag = ufp_addr[31:(SET_BITS+5)];// set bits + 1 
        req_addr_set = ufp_addr[(SET_BITS-1)+5:5]; // change to set bits log2(num of sets) 
        
        req_addr_offset = ufp_addr[4:0];
        padded_ufp_wdata = {{224{1'b0}},ufp_wdata};
        padded_ufp_wmask = {{28{1'b0}},ufp_wmask};

        if(ufp_wmask != 4'b0000 || ufp_rmask != 4'b0000) begin
            valid_cpu_request = 1'b1;
        end else begin
            valid_cpu_request = 1'b0;
        end
    end


    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_we[i]),
            .wmask0     (data_wmask),
            .addr0      (req_addr_set),
            .din0       (data_in[i]),
            .dout0      (data_out[i])
        );
        // #(.TAG_BITS(TAG_BITS), .SET_BITS(SET_BITS))
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (tag_we[i]),
            .addr0      (req_addr_set),
            .din0       (tag_in[i]),
            .dout0      (tag_out[i])
        );
        ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (valid_we[i]),
            .addr0      (req_addr_set),
            .din0       (valid_in[i]),
            .dout0      (valid_out[i])
        );
    end endgenerate

    // PLRU 
    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i=0;i<NUM_SETS;i++) begin 
                plru_tree[i] <= '0; // Initate tree
                plru_replace_index[i] <= '0;
            end 
        end else begin
            if(update_tree) begin
                unique case(way)
                    2'b00: begin
                        plru_tree[req_addr_set] <= {plru_tree[req_addr_set][2],2'b11};
                    end
                    2'b01: begin
                        plru_tree[req_addr_set] <= {plru_tree[req_addr_set][2],2'b01};
                    end
                    2'b10: begin
                        plru_tree[req_addr_set] <= {1'b1,plru_tree[req_addr_set][1],1'b0};
                    end
                    2'b11: begin
                        plru_tree[req_addr_set] <= {1'b0,plru_tree[req_addr_set][1],1'b0};
                    end
                endcase
            end
        end

        if(plru_tree[req_addr_set][0]) begin
            if(plru_tree[req_addr_set][2]) begin
                plru_replace_index[req_addr_set] <= 2'b11;
            end else begin
                plru_replace_index[req_addr_set] <= 2'b10;
            end
        end else begin
            if(plru_tree[req_addr_set][1]) begin
                plru_replace_index[req_addr_set] <= 2'b01;
            end else begin
                plru_replace_index[req_addr_set] <= 2'b00;
            end
        end
    end

    control #(
        .NUM_SETS (NUM_SETS),
        .SET_BITS (SET_BITS),
        .TAG_BITS (TAG_BITS)
        )
    control(
      .*
    );

    // Compare Logic
    always_comb begin
        data_select = '0;
        hit = 1'b0;
        ufp_rdata = '0;
        cache_data = '0;
        data_select = '0;
        way = 'x;
        
        if(valid_cpu_request == 1'b1) begin
            // if((req_addr_tag == tag_out[0][22:0]) && valid_out[0] == 1'b1) begin
            //change to 32 - set_bits - tag_bits
            if((req_addr_tag == tag_out[0][(TAG_BITS -1):0]) && valid_out[0] == 1'b1) begin
                data_select[0] = 1'b1;
            end else begin
                data_select[0] = 1'b0;
            end

            if((req_addr_tag == tag_out[1][(TAG_BITS -1):0]) && valid_out[1] == 1'b1) begin
                data_select[1] = 1'b1;
            end else begin
                data_select[1] = 1'b0;
            end

            if((req_addr_tag == tag_out[2][(TAG_BITS -1):0]) && valid_out[2] == 1'b1) begin
                data_select[2] = 1'b1;
            end else begin
                data_select[2] = 1'b0;
            end

            if((req_addr_tag == tag_out[3][(TAG_BITS -1):0]) && valid_out[3] == 1'b1) begin
                data_select[3] = 1'b1;
            end else begin
                data_select[3] = 1'b0;
            end
            
            hit = data_select[0] | data_select[1] | data_select[2] | data_select[3];

            unique case(data_select)
                4'b0001: begin
                    cache_data = data_out[0];
                    way = 2'b00;
                end
                4'b0010: begin
                    cache_data = data_out[1];
                    way = 2'b01;
                end
                4'b0100: begin
                    cache_data = data_out[2];
                    way = 2'b10;
                end
                4'b1000: begin
                    cache_data = data_out[3];
                    way = 2'b11;
                end
                default: begin 
                    cache_data = 'x;
                    way = 'x;
                end
            endcase

            if(update_rdata == 1'b1) begin
                ufp_rdata = cache_data[(8 * (req_addr_offset)) +: 32]; // would this work if offset if is 32
            end else begin
                ufp_rdata = '0;
            end
        end
    end



endmodule
