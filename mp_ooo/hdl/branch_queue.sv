module branch_queue 
import rv32i_types::*;
#(parameter QUEUE_DEPTH = 16, BIT_DEPTH = 5)
(
    input   logic               clk,
    input   logic               rst,
    input   logic               flush,
    input   cdb_entry_t         cdb_entry,
    input   rename_data_t       branch_entry_in,
    input   logic               enqueue, // if (not full, is_mem_op, mem_rs_dispatch)
    // input   logic               dequeue, //probably the dmem_resp?
    output  rename_data_t       branch_entry_out,
    output  logic               is_empty,
    output  logic               is_full
);

    // logic dum;
    // assign dum = flush;
    logic             dequeue;
    rename_data_t     entries [QUEUE_DEPTH];
    logic   [BIT_DEPTH-1:0]     head_ptr;
    logic   [BIT_DEPTH-1:0]     tail_ptr;
    logic   [BIT_DEPTH-1:0]     head_ptr_next;
    logic   [BIT_DEPTH-1:0]     tail_ptr_next;

    logic   write_data;

    assign dequeue = entries[head_ptr[BIT_DEPTH-2:0]].ps1_v && entries[head_ptr[BIT_DEPTH-2:0]].ps2_v && entries[head_ptr[BIT_DEPTH-2:0]].valid;

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
                entries[tail_ptr[BIT_DEPTH-2:0]] <= branch_entry_in;
            end


            //check CDB writeback and intercept value 
            for (int i=0; i<QUEUE_DEPTH; i++)begin
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
        head_ptr_next = head_ptr; // Don't Move pointers when not reading or writing
        tail_ptr_next = tail_ptr;
        write_data = 1'b0; // Default Don't Write Data
        branch_entry_out = '0; // Read Data Doesn't Matter when not reading

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
                branch_entry_out = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
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
                branch_entry_out = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
            end

        end else if(!enqueue && !dequeue) begin
            head_ptr_next = head_ptr;
            tail_ptr_next = tail_ptr;
        end
    end

    


endmodule