module retired_freelist 
import rv32i_types::*;
#(parameter QUEUE_WIDTH = 6, QUEUE_DEPTH = 64, BIT_DEPTH = 6)
(
    input   logic                       clk,
    input   logic                       rst,

    //enqueue data once we commit instruction and change RRAT entry 
    input   logic                       enqueue, //from RRAT 
    input   logic   [QUEUE_WIDTH-1:0]   enqueue_wdata, //from RRAT, physical register that was just freed 

    //dequeue signal from rename/dispatch 
    input   logic                       dequeue,
    output  logic   [QUEUE_WIDTH-1:0]   dequeue_rdata,
    output  logic                       is_empty,
    output  logic                       is_full,
    output  logic   [BIT_DEPTH-1:0]     retired_head_ptr,
    output  logic   [BIT_DEPTH-1:0]     retired_tail_ptr,
    output  logic   [QUEUE_WIDTH-1:0]   entries [32]
);

    // Parameters: QUEUE_WIDTH = Size of data (# bits), QUEUE_DEPTH = # of entries, BIT_DEPTH = # bits to index entries + 1 overflow bit

    // logic   [QUEUE_WIDTH-1:0] entries [32];


    logic   [BIT_DEPTH-1:0]     head_ptr;
    logic   [BIT_DEPTH-1:0]     tail_ptr;
    logic   [BIT_DEPTH-1:0]     head_ptr_next;
    logic   [BIT_DEPTH-1:0]     tail_ptr_next;

    logic   write_data;

    assign retired_head_ptr = head_ptr;
    assign retired_tail_ptr = tail_ptr;

    assign is_full = (
        (head_ptr[BIT_DEPTH-2:0] == tail_ptr[BIT_DEPTH-2:0]) &&
        (head_ptr[BIT_DEPTH-1] != tail_ptr[BIT_DEPTH-1])
    );

    assign is_empty = head_ptr == tail_ptr;

    always_ff @(posedge clk) begin
        if(rst) begin
            head_ptr <= 6'd0;
            // tail_ptr <= 6'd31; //next open spot?? might need to be 31 
            tail_ptr <= 6'd32; //next open spot?? might need to be 31 

            // entries[0] <= 6'd0;
            // entries[31] <= 6'd31;
            entries[0] <= 6'd32;
            entries[1] <= 6'd33;
            entries[2] <= 6'd34;
            entries[3] <= 6'd35;
            entries[4] <= 6'd36;
            entries[5] <= 6'd37;
            entries[6] <= 6'd38;
            entries[7] <= 6'd39;
            entries[8] <= 6'd40;
            entries[9] <= 6'd41;
            entries[10] <= 6'd42;
            entries[11] <= 6'd43;
            entries[12] <= 6'd44;
            entries[13] <= 6'd45;
            entries[14] <= 6'd46;
            entries[15] <= 6'd47;
            entries[16] <= 6'd48;
            entries[17] <= 6'd49;
            entries[18] <= 6'd50;
            entries[19] <= 6'd51;
            entries[20] <= 6'd52;
            entries[21] <= 6'd53;
            entries[22] <= 6'd54;
            entries[23] <= 6'd55;
            entries[24] <= 6'd56;
            entries[25] <= 6'd57;
            entries[26] <= 6'd58;
            entries[27] <= 6'd59;
            entries[28] <= 6'd60;
            entries[29] <= 6'd61;
            entries[30] <= 6'd62;
            entries[31] <= 6'd63;
           

        end else begin
            head_ptr <= head_ptr_next;
            tail_ptr <= tail_ptr_next;

            if(write_data & !rst) begin
                entries[tail_ptr[BIT_DEPTH-2:0]] <= enqueue_wdata;
            end
            // Write Data Synchronously

        end
    end


    always_comb begin
        head_ptr_next = head_ptr; // Don't Move pointers when not reading or writing
        tail_ptr_next = tail_ptr;
        write_data = 1'b0; // Default Don't Write Data
        dequeue_rdata = 'x; // Read Data Doesn't Matter when not reading

        if(enqueue && dequeue) begin

            tail_ptr_next = tail_ptr + 1'b1; // Move tail pointer if there is room
            write_data = 1'b1; // Send Signal to Write Data
            // if(is_full) begin
            //     tail_ptr_next = tail_ptr; // Don't move tail pointer if its full
            // end else begin
            // end

            if(is_empty) begin
                head_ptr_next = head_ptr; // Don't move head pointer if we are currently empty
            end else begin
                head_ptr_next = head_ptr + 1'b1; // Move the head pointer if there is data
                dequeue_rdata = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
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
                dequeue_rdata = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
            end

        end else if(!enqueue && !dequeue) begin
            head_ptr_next = head_ptr;
            tail_ptr_next = tail_ptr;
        end
    end

endmodule


