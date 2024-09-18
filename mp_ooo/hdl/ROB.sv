module ROB
import rv32i_types::*;
#(parameter QUEUE_WIDTH = 31, QUEUE_DEPTH = 16, BIT_DEPTH = 5, P_REG_DEPTH = 6, R_REG_DEPTH = 5)
(
    input   logic                           clk,
    input   logic                           rst,
    input   logic   [P_REG_DEPTH-1:0]       dispatch_pd,
    input   logic   [R_REG_DEPTH-1:0]       dispatch_rd,
    input   logic                           dispatch_enqueue,
    input   logic                           flush,
    input   cdb_entry_t                     cdb_entry,
    output  logic   [BIT_DEPTH-1:0]         dispatch_rob_index, // changed to 2->1
    output  rob_entry_t                     rob_dequeue_rdata,
    output  logic   [BIT_DEPTH-2:0]         rob_curr_head,
    output  logic                           is_full
);
    logic is_empty;
    // logic is_full;


    rob_entry_t  entries [QUEUE_DEPTH];//extra bit for commit field

    logic   [BIT_DEPTH-1:0]     head_ptr;
    logic   [BIT_DEPTH-1:0]     tail_ptr;
    logic   [BIT_DEPTH-1:0]     head_ptr_next;
    logic   [BIT_DEPTH-1:0]     tail_ptr_next;
    logic   write_data;
    logic   dequeue;
    logic   update_commit;

    rob_entry_t enqueue_wdata;

    assign rob_curr_head = head_ptr[BIT_DEPTH-2:0];

    always_comb begin
        enqueue_wdata.commit = 1'b0;
        enqueue_wdata.rd = dispatch_rd;
        enqueue_wdata.pd = dispatch_pd;
        enqueue_wdata.rvfi_mon = '0;
        enqueue_wdata.result = '0;
        enqueue_wdata.jump = '0;
        enqueue_wdata.flush = '0;
        enqueue_wdata.update_rat = '0;
        // enqueue_wdata.invalid = '0;
        // enqueue_wdata.rs1_addr = cdb_entry.rs1_addr;
        // enqueue_wdata.rs2_addr = cdb_entry.rs2_addr;
        // enqueue_wdata.rd_addr = cdb_entry.rd_addr;
        // enqueue_wdata.rd_wdata = cdb_entry.result;
        // enqueue_wdata.order = cdb_entry.order;
        // enqueue_wdata.inst = cdb_entry.instruction;
        // enqueue_wdata.rs1_data = cdb_entry.ps1_value;
        // enqueue_wdata.rs2_data = cdb_entry.ps2_value;
        // enqueue_wdata.pc_wdata = cdb_entry.pc_next;
        // enqueue_wdata.pc_rdata = cdb_entry.pc;
        // enqueue_wdata.regf_we = cdb_entry.CDB_regf_we;
        // enqueue_wdata.rvfi_mon = cdb_entry.rvfi_mon;
    end

    assign dequeue = is_empty ? 1'b0 : entries[head_ptr[BIT_DEPTH-2:0]].commit; //assert dequeue when head points at index w commit flag on
    // assign dequeue = is_empty ? 1'b0 : entries[head_ptr[BIT_DEPTH-2:0]].commit && !entries[head_ptr[BIT_DEPTH-2:0]].invalid; //assert dequeue when head points at index w commit flag on

    assign is_full = (
        (head_ptr[BIT_DEPTH-2:0] == tail_ptr[BIT_DEPTH-2:0]) &&
        (head_ptr[BIT_DEPTH-1] != tail_ptr[BIT_DEPTH-1])
    );

    assign is_empty = head_ptr == tail_ptr;

    always_ff @(posedge clk) begin
        if(rst) begin
            head_ptr <= '0;
            tail_ptr <= '0;
            entries <= '{default: '0};
        end else begin
            head_ptr <= head_ptr_next;
            tail_ptr <= tail_ptr_next;


            // if(cdb_entry.flush) begin
            //     for(logic [3:0] i=(cdb_entry.rob_index + 1'b1);i<tail_ptr[BIT_DEPTH-2:0];i=i+1'b1) begin
            //         entries[i].invalid <= 1'b1;
            //     end
            // end



            if(cdb_entry.pd == entries[cdb_entry.rob_index].pd && cdb_entry.rd == entries[cdb_entry.rob_index].rd) begin
                entries[cdb_entry.rob_index].rvfi_mon <= cdb_entry.rvfi_mon;
                entries[cdb_entry.rob_index].result <= cdb_entry.result;
                entries[cdb_entry.rob_index].commit <= 1'b1;
                // entries[cdb_entry.rob_index].invalid <= 1'b0;
                entries[cdb_entry.rob_index].jump <= cdb_entry.jump;
                entries[cdb_entry.rob_index].flush <= cdb_entry.flush;
                entries[cdb_entry.rob_index].update_rat <= cdb_entry.CDB_regf_we;
            end

            // Write Data Synchronously
            if(write_data) begin
                entries[tail_ptr[BIT_DEPTH-2:0]] <= enqueue_wdata;
            end
            
            
            if(flush) begin
                head_ptr <= '0;
                tail_ptr <= '0;
                entries <= '{default: '0};
            end
        end
    end


    always_comb begin
        head_ptr_next = head_ptr; // Don't Move pointers when not reading or writing
        tail_ptr_next = tail_ptr;
        write_data = 1'b0; // Default Don't Write Data
        rob_dequeue_rdata = '0;
        dispatch_rob_index = '0;
        if(dispatch_enqueue && dequeue) begin

            if(is_full) begin
                tail_ptr_next = tail_ptr; // Don't move tail pointer if its full
            end else begin
                tail_ptr_next = tail_ptr + 1'b1; // Move tail pointer if there is room
                write_data = 1'b1; // Send Signal to Write Data
                dispatch_rob_index = tail_ptr;
            end

            if(is_empty) begin
                head_ptr_next = head_ptr; // Don't move head pointer if we are currently empty
            end else begin
                head_ptr_next = head_ptr + 1'b1; // Move the head pointer if there is data
                rob_dequeue_rdata = entries[head_ptr[BIT_DEPTH-2:0]];// Read out pd and rd to retire and monitor signals
            end

        end else if(dispatch_enqueue && !dequeue) begin

            if(is_full) begin
                tail_ptr_next = tail_ptr; // Don't move tail pointer if its full
            end else begin
                tail_ptr_next = tail_ptr + 1'b1; // Move tail pointer if there is room
                write_data = 1'b1; // Send Signal to Write Data
                dispatch_rob_index = tail_ptr;
            end

        end else if(!dispatch_enqueue && dequeue) begin

            if(is_empty) begin
                head_ptr_next = head_ptr; // Don't move head pointer if we are currently empty
            end else begin
                head_ptr_next = head_ptr + 1'b1; // Move the head pointer if there is data
                rob_dequeue_rdata = entries[head_ptr[BIT_DEPTH-2:0]];// Read out pd and rd to retire and monitor signals
            end

        end else if(!dispatch_enqueue && !dequeue) begin
            head_ptr_next = head_ptr;
            tail_ptr_next = tail_ptr;
        end
    end

endmodule