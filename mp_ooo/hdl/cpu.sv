module cpu
import rv32i_types::*;
(
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input   logic           clk,
    input   logic           rst,

    // output  logic   [31:0]  imem_addr,
    // output  logic   [3:0]   imem_rmask,
    // input   logic   [31:0]  imem_rdata,
    // input   logic           imem_resp,
    // output  logic   [31:0]  dmem_addr,
    // output  logic   [3:0]   dmem_rmask,
    // output  logic   [3:0]   dmem_wmask,
    // input   logic   [31:0]  dmem_rdata,
    // output  logic   [31:0]  dmem_wdata,
    // input   logic           dmem_resp

    // Single memory port connection when caches are integrated into design (CP3 and after)
    /*
    */
    output logic   [31:0]      bmem_addr,
    output logic               bmem_read,
    output logic               bmem_write,
    output logic   [63:0]      bmem_wdata,
    input logic               bmem_ready,

    input logic   [31:0]      bmem_raddr,
    input logic   [63:0]      bmem_rdata,
    input logic               bmem_rvalid
);

    // Fetching Signals
    fetch_iqbuf_reg_t fetch_iqbuf_reg;
    fetch_iqbuf_reg_t fetch_iqbuf_reg_next;

    // Instruction Queue Signals
    logic iq_is_full;
    logic iq_is_empty;
    logic iq_enqueue;
    iq_dequeue_rdata_t iq_dequeue_rdata;
    logic iq_is_almost_full;


    // Decode/Rename Signals
    logic [5:0] ps1_s; // RAT -> Decode Rename
    logic [5:0] ps2_s; // RAT -> Decode Rename
    logic [5:0] pd_free; // Free List -> Decode Rename : Renamed Destination Register
    logic [4:0] rob_index; // changed to 3->4

    logic [5:0] retired_pd_free; // Free List -> Decode Rename : Renamed Destination Register
    // logic rs_buffer_valid;
    rename_data_t rs_buffer;
    rename_data_t rs_buffer_next;

    logic stall_iq;

    //RAT Signals
    logic ps1_valid; // RAT -> Decode Rename
    logic ps2_valid; // RAT -> Decode Rename
    logic flopped_ps1_valid; // RAT -> Decode Rename
    logic flopped_ps2_valid; // RAT -> Decode Rename
    // Reservation Station Signals 

    logic rs_open;
    logic mult_rs_open;
    rs_entry_t res_station_in; // Update when superscalar
    logic      rs_dispatch;
    logic      mult_rs_dispatch;
    // rs_entry_t res_station_out[4]; // superscalar
    rs_entry_t res_station_out;
    rs_entry_t mult_res_station_out;
    
    logic mult_done;
    logic div_done;
    // Functional Unit Signals
    // FU_entry_t FU_reg [4]; //superscalar
    FU_entry_t FU_reg;
    logic FU_en;

    FU_entry_t mult_FU_reg;
    logic issue_mult;
    logic clear_out;
 
    // logic [3:0] check;
    // assign FU_reg = '0;


    // ROB Signals
    rob_entry_t rob_dequeue_rdata;
    logic [3:0] rob_curr_head;
    logic rob_is_full;

    // Common Data Bus Signals
    cdb_entry_t cdb_out;
    logic arith_cdb_sent;
    logic mult_cdb_sent;
    logic lsq_cdb_sent;
    logic br_cdb_sent;
    //RRF signals
    logic [5:0] RRF_p_reg_out;
    logic RRF_enqueue;
    logic  [5:0] arc_reg_out [32];


    //Freelist Signals
    logic freelist_empty;
    logic freelist_full;


    logic retired_freelist_empty;
    logic retired_freelist_full;
    // logic      freelist_dequeue;
    logic   [5:0]   retired_freelist_entries [32];
    logic   [5:0]     retired_head_ptr;
    logic   [5:0]     retired_tail_ptr;


    // RVFI Signals / Connected to RVFI
    rvfi_mon_t rvfi_mon;

    //MEM UNIT SIGNALS
    logic lsq_dispatch;
    // logic lsq_dequeue;
    logic lsq_is_full;
    logic lsq_is_empty;
    mem_entry_t mem_unit_lsq_entry_out; // Into the CDB from the memory unit
    
    rename_data_t mem_unit_lsq_entry_in; // Into the memory unit from the LSQ
    rename_data_t mem_unit_lsq_entry_in_next; // Into the memory unit from the LSQ

    logic d_cache_in_use;

    logic [31:0] mem_ps1_v;
    logic [31:0] mem_ps2_v;

    //BRANCH Q/UNIT SIGNALS
    logic br_dispatch;

    logic           brq_is_empty;
    logic           brq_is_full;
    rename_data_t   branch_entry_in;
    // rename_data_t   branch_entry_out; 
    // logic           flush_signal; 
    branch_entry_t  branch_entry_out;
    logic [31:0] br_ps1_val;
    logic [31:0] br_ps2_val;
    logic control_enqueue; 
    logic [31:0] branch_pc;
    logic ctrl_buff_is_empty;
    logic ctrl_buff_is_full;

    //CACHE SIGNALS
    logic   [31:0]  imem_addr;
    logic   [3:0]   imem_rmask;
    logic   [31:0]  imem_rdata;
    logic           imem_resp;
    logic   [31:0]  dmem_addr;
    logic   [3:0]   dmem_rmask;
    logic   [3:0]   dmem_wmask;
    logic   [31:0]  dmem_rdata;
    logic   [31:0]  dmem_wdata;
    logic           dmem_resp;


    assign rvfi_mon.valid =  rob_dequeue_rdata.commit;
    assign rvfi_mon.order = rob_dequeue_rdata.rvfi_mon.order;
    assign rvfi_mon.inst = rob_dequeue_rdata.rvfi_mon.inst;
    assign rvfi_mon.rs1_addr = rob_dequeue_rdata.rvfi_mon.rs1_addr;
    assign rvfi_mon.rs2_addr = rob_dequeue_rdata.rvfi_mon.rs2_addr;
    assign rvfi_mon.rs1_rdata = rob_dequeue_rdata.rvfi_mon.rs1_rdata;
    assign rvfi_mon.rs2_rdata = rob_dequeue_rdata.rvfi_mon.rs2_rdata;
    assign rvfi_mon.rd_addr = rob_dequeue_rdata.rvfi_mon.rd_addr;
    assign rvfi_mon.rd_wdata =  rob_dequeue_rdata.result;
    assign rvfi_mon.pc_rdata =   rob_dequeue_rdata.rvfi_mon.pc_rdata;
    assign rvfi_mon.pc_wdata =   rob_dequeue_rdata.flush ? branch_pc : rob_dequeue_rdata.rvfi_mon.pc_wdata;
    assign rvfi_mon.regf_we = rob_dequeue_rdata.rvfi_mon.regf_we;
    assign rvfi_mon.dmem_addr =   rob_dequeue_rdata.rvfi_mon.dmem_addr;
    assign rvfi_mon.dmem_rmask =   rob_dequeue_rdata.rvfi_mon.dmem_rmask;
    assign rvfi_mon.dmem_wmask =   rob_dequeue_rdata.rvfi_mon.dmem_wmask;
    assign rvfi_mon.dmem_rdata =   rob_dequeue_rdata.rvfi_mon.dmem_rdata;
    assign rvfi_mon.dmem_wdata =   rob_dequeue_rdata.rvfi_mon.dmem_wdata;


    // logic dummy;
    // assign dmem_rmask = '0;
    // assign dmem_wmask = '0;
    // assign dmem_addr = '0;
    // assign dmem_wdata = '0;
    // assign dummy = dmem_resp | imem_resp;
    


    always_ff @(posedge clk) begin
        if(rst) begin
            fetch_iqbuf_reg <= '0;
        end else begin
            // if(imem_resp && !iq_is_full) begin 
            // if(!iq_is_full) begin 
            //     // Not sure if we should be keeping this register
            // end else begin
            //     fetch_iqbuf_reg <= '0;
            // end 
            if(rob_dequeue_rdata.flush) begin
                fetch_iqbuf_reg <= '0;
            
            end else if(iq_is_full && imem_resp) begin
                fetch_iqbuf_reg <= fetch_iqbuf_reg;
            end else begin
                fetch_iqbuf_reg <= fetch_iqbuf_reg_next;
            end
        end
    end

    logic           invalid_cpu_request; // cancel communicating with dram

    logic   [31:0]  i_dfp_addr;
    logic           i_dfp_read;
    logic           i_dfp_write;
    logic   [255:0] i_dfp_rdata;
    logic   [255:0] i_dfp_wdata;
    logic           i_dfp_resp;

    logic   [31:0]  d_dfp_addr;
    logic           d_dfp_read;
    logic           d_dfp_write;
    logic   [255:0] d_dfp_rdata;
    logic   [255:0] d_dfp_wdata;
    logic           d_dfp_resp;

    logic   [31:0]      cla_raddr;
    logic   [31:0]      cla_addr;
    logic               cla_read;
    logic               cla_write;
    logic   [255:0]     cla_rdata;
    logic   [255:0]     cla_wdata;
    logic               cla_resp;


    //CACHES
    cache i_cache(
    .*,
        .ufp_addr(imem_addr),
        .ufp_rmask(imem_rmask),
        .ufp_wmask(4'b0),
        .ufp_rdata(imem_rdata),
        .ufp_wdata('x),
        .ufp_resp(imem_resp),
        .dfp_addr(i_dfp_addr),
        .dfp_read(i_dfp_read),
        .dfp_write(i_dfp_write),
        .dfp_rdata(i_dfp_rdata),
        .dfp_wdata(i_dfp_wdata),
        .dfp_resp(i_dfp_resp)

    );
    cache d_cache(
        .*,
        .ufp_addr(dmem_addr),
        .ufp_rmask(dmem_rmask),
        .ufp_wmask(dmem_wmask),
        .ufp_rdata(dmem_rdata),
        .ufp_wdata(dmem_wdata),
        .ufp_resp(dmem_resp),
        .dfp_addr(d_dfp_addr),
        .dfp_read(d_dfp_read),
        .dfp_write(d_dfp_write),
        .dfp_rdata(d_dfp_rdata),
        .dfp_wdata(d_dfp_wdata),
        .dfp_resp(d_dfp_resp)
    );
    

    cacheline_arbiter CL_arbiter(
        .*,
        .invalid_cpu_request(invalid_cpu_request),
        .flush(rob_dequeue_rdata.flush),
        .i_dfp_addr(i_dfp_addr),
        .i_dfp_read(i_dfp_read),
        // .i_dfp_write('0),
        .i_dfp_rdata(i_dfp_rdata),
        // .i_dfp_wdata('x),
        .i_dfp_resp(i_dfp_resp),
        .d_dfp_addr(d_dfp_addr),
        .d_dfp_read(d_dfp_read),
        .d_dfp_write(d_dfp_write),
        .d_dfp_rdata(d_dfp_rdata),
        .d_dfp_wdata(d_dfp_wdata),
        .d_dfp_resp(d_dfp_resp),
        .cla_addr(cla_addr),
        .cla_read(cla_read),
        .cla_write(cla_write),
        .cla_rdata(cla_rdata),
        .cla_wdata(cla_wdata),
        .cla_raddr(cla_raddr),
        .cla_resp(cla_resp)

    );
    cacheline_adaptor CL_adaptor(
        .*,
        .invalid_cpu_request(invalid_cpu_request),
        .cla_addr(cla_addr),
        .cla_read(cla_read),
        .cla_write(cla_write),
        .cla_rdata(cla_rdata),
        .cla_wdata(cla_wdata),
        .cla_resp(cla_resp),
        .cla_raddr(cla_raddr),
        .bmem_ready(bmem_ready),
        .bmem_raddr(bmem_raddr),
        .bmem_rdata(bmem_rdata),
        .bmem_rvalid(bmem_rvalid),
        .bmem_addr(bmem_addr),
        .bmem_read(bmem_read),
        .bmem_write(bmem_write),
        .bmem_wdata(bmem_wdata)
    );



    fetch fetch(
        .*,
        .branch_order(rob_dequeue_rdata.rvfi_mon.order),
        .flush(rob_dequeue_rdata.flush),
        .iq_enqueue(fetch_iqbuf_reg_next.iq_enqueue),
        .inst_info(fetch_iqbuf_reg_next.inst_info)
    );

    // assign rs_dispatch = 1'b1;

    // Instruction Queue
    queue #(.QUEUE_WIDTH(160), .QUEUE_DEPTH(16), .BIT_DEPTH(5))instruction_queue(
        .*,
        .flush(rob_dequeue_rdata.flush),
        .enqueue(!iq_is_full && imem_resp && !rob_dequeue_rdata.flush),
        .enqueue_wdata({fetch_iqbuf_reg.inst_info, imem_rdata}),
        .dequeue((rs_dispatch || mult_rs_dispatch || lsq_dispatch) && !stall_iq),
        .dequeue_rdata(iq_dequeue_rdata),
        .is_full(iq_is_full),
        .is_empty(iq_is_empty)
        // .almost_full(iq_is_almost_full)
    );

    control_buffer #(.QUEUE_WIDTH(32), .QUEUE_DEPTH(16), .BIT_DEPTH(5)) control_buffer(
        .*,
        .enqueue(branch_entry_out.rename_data.valid && branch_entry_out.flush),
        .enqueue_wdata(branch_entry_out.pc),
        .dequeue(rob_dequeue_rdata.commit && rob_dequeue_rdata.jump && rob_dequeue_rdata.flush),
        .flush(rob_dequeue_rdata.flush),
        .dequeue_rdata(branch_pc),
        .is_empty(ctrl_buff_is_empty),
        .is_full(ctrl_buff_is_full)
    );

    // assign rob_index = '0;
    decode_rename decode_rename(
        .*,
        // .ps1_valid(ps1_valid), 
        // .ps2_valid(ps2_valid), 
        // .ps1_s(ps1_s),
        // .ps2_s(ps2_s),
        .pd(pd_free),
        .rob_index(rob_index),
        .rename_data_out(rs_buffer_next),
        .rs_dispatch(rs_dispatch),
        .mult_rs_dispatch(mult_rs_dispatch)
    );

    always_ff @ (posedge clk) begin
            if(rst) begin
                rs_buffer <= '0;
            end else begin
                if((rs_dispatch || mult_rs_dispatch || lsq_dispatch) && !stall_iq) begin
                    rs_buffer <= rs_buffer_next;
                end
                else begin
                    rs_buffer <= rs_buffer;
                end

                if(rob_dequeue_rdata.flush) begin

                    rs_buffer <= '0;
                end
            end
    end

    always_comb begin
        stall_iq = 1'b0;
        res_station_in = 'x;
        if(rob_dequeue_rdata.flush) begin
            res_station_in = '0;
        end else if(rs_buffer.book_keeping.res_type == arith_res) begin
            if(rs_open) begin
                res_station_in.rename_data = rs_buffer;
                res_station_in.rename_data.ps1_v = ps1_valid;
                res_station_in.rename_data.ps2_v = ps2_valid;
                res_station_in.rename_data.ps1 = ps1_s;
                res_station_in.rename_data.ps2 = ps2_s;
                stall_iq = 1'b0;
            end else begin
                res_station_in.rename_data = 'x;
                stall_iq = 1'b1;
            end
        end else if(rs_buffer.book_keeping.res_type == mult_res) begin
            if(mult_rs_open) begin
                res_station_in.rename_data = rs_buffer;
                res_station_in.rename_data.ps1_v = ps1_valid;
                res_station_in.rename_data.ps2_v = ps2_valid;
                res_station_in.rename_data.ps1 = ps1_s;
                res_station_in.rename_data.ps2 = ps2_s;
                stall_iq = 1'b0;
            end else begin
                res_station_in.rename_data = 'x;
                stall_iq = 1'b1;
            end
        end else if(rs_buffer.book_keeping.res_type == mem_res) begin
            if(!lsq_is_full) begin
                res_station_in.rename_data = rs_buffer;
                res_station_in.rename_data.ps1_v = ps1_valid;
                res_station_in.rename_data.ps2_v = ps2_valid;
                res_station_in.rename_data.ps1 = ps1_s;
                res_station_in.rename_data.ps2 = ps2_s;
                stall_iq = 1'b0;
            end else begin
                res_station_in.rename_data = 'x;
                stall_iq = 1'b1;
            end
        end else if(rs_buffer.book_keeping.res_type == branch_res) begin
            if(!brq_is_full) begin
                res_station_in.rename_data = rs_buffer;
                res_station_in.rename_data.ps1_v = ps1_valid;
                res_station_in.rename_data.ps2_v = ps2_valid;
                res_station_in.rename_data.ps1 = ps1_s;
                res_station_in.rename_data.ps2 = ps2_s;
                stall_iq = 1'b0;
            end else begin
                res_station_in.rename_data = 'x;
                stall_iq = 1'b1;
            end
        end
    end

    rat rat(
        .*,
        .regf_we((rs_dispatch || mult_rs_dispatch || lsq_dispatch) && !stall_iq),
        .rs1_s(rs_buffer.book_keeping.rs1_s),
        .rs2_s(rs_buffer.book_keeping.rs2_s),
        // .flopped_rs1_s(rs_buffer.book_keeping.rs1_s),
        // .flopped_rs2_s(rs_buffer.book_keeping.rs2_s),
        .rd_s(rs_buffer.rd),
        .pd_s(rs_buffer.pd),
        .cdb_entry(cdb_out),
        .ps1_s(ps1_s),
        .ps2_s(ps2_s),  
        .ps1_valid(ps1_valid),
        .ps2_valid(ps2_valid),
        .rrat_mapping(arc_reg_out),
        .flush(rob_dequeue_rdata.flush),
        .rob_rd(rob_dequeue_rdata.rd),
        .rob_pd(rob_dequeue_rdata.pd),
        .update_rat(rob_dequeue_rdata.commit && rob_dequeue_rdata.update_rat && rob_dequeue_rdata.flush)//jal or jalr
        // .flopped_ps1_valid(flopped_ps1_valid),
        // .flopped_ps2_valid(flopped_ps2_valid)
    );



    reservation_station reservation_station (
        .*,
        .flush(rob_dequeue_rdata.flush),
        .rs_open(rs_open),
        .rename_data_in(res_station_in.rename_data),
        .rs_dispatch(!stall_iq && res_station_in.rename_data.book_keeping.res_type == arith_res && rs_dispatch),
        .cdb_entry(cdb_out),
        .res_station_rename_data_out(res_station_out.rename_data)
    );

    mult_reservation_station mult_reservation_station (
        .*,
        .rs_open(mult_rs_open),
        .flush(rob_dequeue_rdata.flush),
        .rename_data_in(res_station_in.rename_data),
        .rs_dispatch(!stall_iq && res_station_in.rename_data.book_keeping.res_type == mult_res && mult_rs_dispatch),
        .cdb_entry(cdb_out),
        .res_station_rename_data_out(mult_res_station_out.rename_data)
    );

    load_store_queue LSQ(
        .*,
        .flush(rob_dequeue_rdata.flush),
        .lsq_entry_in(res_station_in.rename_data),
        .enqueue(lsq_dispatch && !stall_iq && res_station_in.rename_data.book_keeping.res_type == mem_res && lsq_dispatch),
        // .dequeue(lsq_dequeue),
        .cdb_entry(cdb_out),
        .lsq_entry_out(mem_unit_lsq_entry_in_next),
        .is_empty(lsq_is_empty),
        .is_full(lsq_is_full)
    
    );

    branch_queue ranch_queue(
    .*,
    .flush(rob_dequeue_rdata.flush),
    .cdb_entry(cdb_out),
    .branch_entry_in(res_station_in.rename_data),
    .enqueue(br_dispatch && !stall_iq && res_station_in.rename_data.book_keeping.res_type == branch_res),
    .branch_entry_out(branch_entry_in),
    .is_empty(brq_is_empty),
    .is_full(brq_is_full)
    // .flush(flush_signal)       

    );
        // always_ff @(posedge clk) begin
        //     if(rst) begin
        //         lsq_entry_in <= '0;
        //     end else begin
        //         if(dmem_resp || (!dmem_resp && !lsq_entry_in.valid)) begin
        //             lsq_entry_in <= lsq_entry_in_next;
        //         end
        //         else begin
        //             lsq_entry_in <= lsq_entry_in;
        //         end
        //     end
        // end
    // always_ff @(posedge clk) begin// flop if branch in cbd
    //     if(!lsq_cdb_sent) begin//flush condition?
    //         lsq_entry_in <= lsq_entry_in_next;
    //     end else begin
    //         lsq_entry_in <= lsq_entry_in; 
    //     end
    // end


    pregfile pregfile (
        .clk(clk),
        .rst(rst),
        // .flush(cdb_out.flush),
        .CDB_regf_we(cdb_out.CDB_regf_we),
        .CDB_rd_v(cdb_out.result),
        .CDB_rd_s(cdb_out.pd),
        .read_rs1(res_station_out.rename_data.read_rs1),
        .read_rs2(res_station_out.rename_data.read_rs2),
        .rs1_s(res_station_out.rename_data.ps1),
        .rs2_s(res_station_out.rename_data.ps2),
        .rs1_v(res_station_out.ps1_value),
        .rs2_v(res_station_out.ps2_value),
        .mult_read_rs1(mult_res_station_out.rename_data.read_rs1),
        .mult_read_rs2(mult_res_station_out.rename_data.read_rs2),
        .mult_rs1_s(mult_res_station_out.rename_data.ps1),
        .mult_rs2_s(mult_res_station_out.rename_data.ps2),
        .mult_rs1_v(mult_res_station_out.ps1_value),
        .mult_rs2_v(mult_res_station_out.ps2_value),
        .mem_read_rs1(mem_unit_lsq_entry_in.read_rs1),
        .mem_read_rs2(mem_unit_lsq_entry_in.read_rs2),
        .mem_rs1_s(mem_unit_lsq_entry_in.ps1),
        .mem_rs2_s(mem_unit_lsq_entry_in.ps2),
        .mem_rs1_v(mem_ps1_v),
        .mem_rs2_v(mem_ps2_v),
        .br_read_rs1(branch_entry_in.read_rs1),
        .br_read_rs2(branch_entry_in.read_rs2),
        .br_rs1_s(branch_entry_in.ps1),
        .br_rs2_s(branch_entry_in.ps2),
        .br_rs1_v(br_ps1_val),
        .br_rs2_v(br_ps2_val)

    );

    branch_unit ranch_unit(
        .*, 
        .flush(rob_dequeue_rdata.flush),
        .branch_rename_data_in(branch_entry_in),
        .br_ps1_val(br_ps1_val),
        .br_ps2_val(br_ps2_val),
        .branch_entry_out(branch_entry_out)
        // .flush(flush_signal)
    );

    assign d_cache_in_use = (mem_unit_lsq_entry_in.book_keeping.is_store && dmem_wmask != '0 && lsq_cdb_sent)
            ||(mem_unit_lsq_entry_in.book_keeping.is_load && dmem_rmask != '0 && lsq_cdb_sent)
            ||(!mem_unit_lsq_entry_in.valid) ? 1'b0 : 1'b1;

    always_ff @(posedge clk) begin
        if(rst) begin
            mem_unit_lsq_entry_in <= '0;
        end else begin
            if(rob_dequeue_rdata.flush) begin
                mem_unit_lsq_entry_in <= '0;
            end else if((mem_unit_lsq_entry_in.book_keeping.is_store && dmem_wmask != '0 && lsq_cdb_sent)
            ||(mem_unit_lsq_entry_in.book_keeping.is_load && dmem_rmask != '0 && lsq_cdb_sent)
            ||(!mem_unit_lsq_entry_in.valid)) begin
                // d_cache_in_use <= 1'b0;           
                mem_unit_lsq_entry_in <= mem_unit_lsq_entry_in_next;
            end else begin
                // d_cache_in_use <= 1'b1;
                mem_unit_lsq_entry_in <= mem_unit_lsq_entry_in;
            end
        end
    end



 
    // store_buffer buffy(
    //      .*, 
    //     .enqueue (mem_unit_lsq_entry_in.book_keeping.is_store && mem_unit_lsq_entry_in.valid),
    //     .dequeue (mem_unit_lsq_entry_in.book_keeping.is_store && mem_unit_lsq_entry_in.valid && sb_full),
    //     .lsq_entry(mem_unit_lsq_entry_in)
    //     .is_empty(sb_empty), 
    //     .is_full(sb_full)
    //     .sb_entry_out(sb_entry_out)
    // );
    memory_unit mem_unit(
        .*,
        .flush(rob_dequeue_rdata.flush),
        .mem_ps1_v(mem_ps1_v),
        .mem_ps2_v(mem_ps2_v),
        .lsq_entry(mem_unit_lsq_entry_in),
        .dmem_rdata(dmem_rdata),
        .dmem_resp(dmem_resp),
        .dmem_addr(dmem_addr),
        .dmem_rmask(dmem_rmask),
        .dmem_wmask(dmem_wmask),
        .dmem_wdata(dmem_wdata),
        .lsq_entry_out(mem_unit_lsq_entry_out)

    );

    
    func_unit FU(
        .*,
        .flush(rob_dequeue_rdata.flush),
        .mult_fu_res_station_in(mult_res_station_out),
        .fu_res_station_in(res_station_out),
        .FU_en(FU_en),
        .FU_out(FU_reg),
        .mult_FU_out(mult_FU_reg)
    );

    cdb cdb(
        .*,
        .flush(rob_dequeue_rdata.flush),
        .br_in(branch_entry_out),
        .lsq_in(mem_unit_lsq_entry_out),
        .mult_FU_in(mult_FU_reg),
        .FU_in(FU_reg),
        .cdb_out(cdb_out)
    );

    rob_entry_t rob_dequeue_rdata_next;
    ROB rob(
        .*,
        .flush(rob_dequeue_rdata.flush),
        .dispatch_pd(rs_buffer_next.pd),
        .dispatch_rd(rs_buffer_next.rd),
        .dispatch_enqueue((rs_dispatch || mult_rs_dispatch || lsq_dispatch) && !stall_iq),
        .cdb_entry(cdb_out),
        .dispatch_rob_index(rob_index),
        .rob_dequeue_rdata(rob_dequeue_rdata_next),
        .is_full(rob_is_full)
    );

    always_ff @(posedge clk) begin
        if(rst) begin
            rob_dequeue_rdata <= '0;
        end else begin
            if(rob_dequeue_rdata_next.commit && !rob_dequeue_rdata.flush) begin
                rob_dequeue_rdata <= rob_dequeue_rdata_next;
            end else begin
                rob_dequeue_rdata<= '0;
            end

        end
    end
    // assign RRF_enqueue = '0;
    // assign RRF_p_reg_out = '0;

    freelist  #(.QUEUE_WIDTH(6),.QUEUE_DEPTH(32),.BIT_DEPTH(6)) freelist(
        .*,
        .flush(rob_dequeue_rdata.flush),
        .enqueue(RRF_enqueue),
        .enqueue_wdata(RRF_p_reg_out),
        .dequeue(((rs_dispatch || mult_rs_dispatch || lsq_dispatch) && !stall_iq) && rs_buffer_next.rd != 5'd0),
        .dequeue_rdata(pd_free),
        .is_empty(freelist_empty), //1 => empty;
        .is_full(freelist_full)//1 => full;

    );

    retired_freelist  #(.QUEUE_WIDTH(6),.QUEUE_DEPTH(32),.BIT_DEPTH(6)) retired_freelist(
        .*,
        .entries(retired_freelist_entries),
        .enqueue(RRF_enqueue),
        .enqueue_wdata(RRF_p_reg_out),
        .dequeue(RRF_enqueue),
        .dequeue_rdata(retired_pd_free),
        .is_empty(retired_freelist_empty), //1 => empty;
        .is_full(retired_freelist_full)//1 => full;

    );



    retired_rat retired_rat(
        .*,
        .regf_we(rob_dequeue_rdata.commit),
        .rd(rob_dequeue_rdata.rd),
        .pd(rob_dequeue_rdata.pd),
        .old_ps_idx(RRF_p_reg_out),
        .enqueue(RRF_enqueue),
        .freelist_full(freelist_full)
    );

    logic           monitor_valid;
    logic   [63:0]  monitor_order;
    logic   [31:0]  monitor_inst;
    logic   [4:0]   monitor_rs1_addr;
    logic   [4:0]   monitor_rs2_addr;
    logic   [31:0]  monitor_rs1_rdata;
    logic   [31:0]  monitor_rs2_rdata;
    logic   [4:0]   monitor_rd_addr;
    logic   [31:0]  monitor_rd_wdata;
    logic   [31:0]  monitor_pc_rdata;
    logic   [31:0]  monitor_pc_wdata;
    logic   [31:0]  monitor_dmem_addr;
    logic   [3:0]   monitor_dmem_rmask;
    logic   [3:0]   monitor_dmem_wmask;
    logic   [31:0]  monitor_dmem_rdata;
    logic   [31:0]  monitor_dmem_wdata;


    assign monitor_valid      = rvfi_mon.valid;
    // assign monitor_valid      = 1'b0;
    assign monitor_order      = rvfi_mon.order;
    assign monitor_inst       = rvfi_mon.inst;
    assign monitor_rs1_addr   = rvfi_mon.rs1_addr;
    assign monitor_rs2_addr   = rvfi_mon.rs2_addr;
    assign monitor_rs1_rdata  = rvfi_mon.rs1_rdata;
    assign monitor_rs2_rdata  = rvfi_mon.rs2_rdata;
    assign monitor_rd_addr    = rvfi_mon.regf_we ? rvfi_mon.rd_addr : 5'd0;
    assign monitor_rd_wdata   = rvfi_mon.rd_wdata;
    assign monitor_pc_rdata   = rvfi_mon.pc_rdata;
    assign monitor_pc_wdata   = rvfi_mon.pc_wdata;
    assign monitor_dmem_addr  = rvfi_mon.dmem_addr;
    assign monitor_dmem_rmask = rvfi_mon.dmem_rmask;
    assign monitor_dmem_wmask = rvfi_mon.dmem_wmask;
    assign monitor_dmem_rdata = rvfi_mon.dmem_rdata;
    assign monitor_dmem_wdata = rvfi_mon.dmem_wdata;

endmodule : cpu
