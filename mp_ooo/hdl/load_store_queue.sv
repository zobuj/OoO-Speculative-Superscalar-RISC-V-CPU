module load_store_queue 
import rv32i_types::*;
#(parameter QUEUE_DEPTH = 16, BIT_DEPTH = 5)
(
    input   logic               clk,
    input   logic               rst,
    input   logic               flush,
    input   logic [3:0]         rob_curr_head, 
    input   cdb_entry_t         cdb_entry,
    input   logic               br_cdb_sent,
    input   logic               lsq_cdb_sent,
    input   rename_data_t       lsq_entry_in,
    input   logic               d_cache_in_use,
    input   logic               enqueue, // if (not full, is_mem_op, mem_rs_dispatch)
    // input   logic               dequeue, //probably the dmem_resp?
    // input   logic               dmem_resp,
    output  rename_data_t       lsq_entry_out,
    output  logic               is_empty,
    output  logic               is_full
);

    logic dequeue;
    rename_data_t     entries [QUEUE_DEPTH];

    logic   [BIT_DEPTH-1:0]     head_ptr;
    logic   [BIT_DEPTH-1:0]     tail_ptr;
    logic   [BIT_DEPTH-1:0]     head_ptr_next;
    logic   [BIT_DEPTH-1:0]     tail_ptr_next;

    logic   write_data;

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

            // Write Data Synchronously
            if(write_data) begin
                entries[tail_ptr[BIT_DEPTH-2:0]] <= lsq_entry_in;
            end
            // if(dequeue) begin
            //     entries[head_ptr[BIT_DEPTH-2:0]] <= '0; // Read Data Out
            // end

            //check CDB writeback and intercept value 
            for (int i=0; i< QUEUE_DEPTH; i++) begin
                if(cdb_entry.pd == entries[i].ps1 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                        entries[i].ps1_v <= 1'b1;
                end
                    if(cdb_entry.pd == entries[i].ps2 && cdb_entry.valid && cdb_entry.pd != 6'd0) begin
                        entries[i].ps2_v <= 1'b1;
                end
            end

            if(flush) begin
                head_ptr <= '0;
                tail_ptr <= '0;
                entries <= '{default: '0};
            end
        end
    end


    always_comb begin
        dequeue = 1'b0;
        if(!lsq_cdb_sent && (!br_cdb_sent)) begin
            if(entries[head_ptr[BIT_DEPTH-2:0]].ps1_v && entries[head_ptr[BIT_DEPTH-2:0]].ps2_v && entries[head_ptr[BIT_DEPTH-2:0]].valid) begin
                if(entries[head_ptr[BIT_DEPTH-2:0]].book_keeping.is_store == 1'b1)begin
                    if(entries[head_ptr[BIT_DEPTH-2:0]].rob_entry == rob_curr_head) begin
                        if(!d_cache_in_use) begin
                            dequeue = 1'b1;
                        end else begin
                            dequeue = 1'b0;
                        end
                    end else begin
                        dequeue = 1'b0;
                    end
                end
                else if(entries[head_ptr[BIT_DEPTH-2:0]].book_keeping.is_load == 1'b1) begin
                    if(!d_cache_in_use) begin
                        dequeue = 1'b1;
                    end
                    else begin
                        dequeue = 1'b0;
                    end
                end
            end
        end
    end

    always_comb begin
        head_ptr_next = head_ptr; // Don't Move pointers when not reading or writing
        tail_ptr_next = tail_ptr;
        write_data = 1'b0; // Default Don't Write Data
        lsq_entry_out = '0; // Read Data Doesn't Matter when not reading

        if(enqueue && dequeue) begin

            if(is_full) begin
                tail_ptr_next = tail_ptr; // Don't move tail pointer if its full
            end else begin
                tail_ptr_next = tail_ptr + 1'b1; // Move tail pointer if there is room
                write_data = 1'b1; // Send Signal to Write Data
            end

            if(is_empty) begin
                head_ptr_next = head_ptr; // Don't move head pointer if we are currently empty
            end else begin
                head_ptr_next = head_ptr + 1'b1; // Move the head pointer if there is data
                lsq_entry_out = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
            end

        end else if(enqueue && !dequeue) begin

            if(is_full) begin
                tail_ptr_next = tail_ptr; // Don't move tail pointer if its full
            end else begin
                tail_ptr_next = tail_ptr + 1'b1; // Move tail pointer if there is room
                write_data = 1'b1; // Send Signal to Write Data
            end

        end else if(!enqueue && dequeue) begin

            if(is_empty) begin
                head_ptr_next = head_ptr; // Don't move head pointer if we are currently empty
            end else begin
                head_ptr_next = head_ptr + 1'b1; // Move the head pointer if there is data
                lsq_entry_out = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
            end

        end else if(!enqueue && !dequeue) begin
            head_ptr_next = head_ptr;
            tail_ptr_next = tail_ptr;
        end
    end

    


endmodule