module store_buffer 
import rv32i_types::*;
#(parameter  QUEUE_DEPTH = 32, BIT_DEPTH = 6)
(
    input   logic                       clk,
    input   logic                       rst,
    input   logic                       flush,
    input   logic                       enqueue,
    input   logic                       dequeue,

    //data from store 
    input    logic          [31:0]      store_addr,
    input    logic          [31:0]      wdata, 
    input    logic          [3:0]       wmask,


    //data from load 
    input    logic          [31:0]      load_addr,
    input    logic          [3:0]       rmask,

    
    // output  logic   [QUEUE_WIDTH-1:0]   _rdata, //dont need the dequeued data 
    output  logic        [31:0]         r_data,
    output  logic                       is_empty,
    output  logic                       is_full,

    //add logic for this 
    output  logic                       sb_match
);

    // Parameters: QUEUE_WIDTH = Size of data (# bits), QUEUE_DEPTH = # of entries, BIT_DEPTH = # bits to index entries + 1 overflow bit

    store_buff_t  entries [QUEUE_DEPTH];


    logic   [BIT_DEPTH-1:0]     head_ptr;
    logic   [BIT_DEPTH-1:0]     tail_ptr;
    logic   [BIT_DEPTH-1:0]     head_ptr_next;
    logic   [BIT_DEPTH-1:0]     tail_ptr_next;
    // logic   dequeue;

    logic   write_data;
    logic   swap_data;
    logic   [3:0]     swap_idx;
    // logic   almost_full;
    // assign almost_full = (
    //     (head_ptr[BIT_DEPTH-2:0] == tail_ptr[BIT_DEPTH-2:0] +1'b1) &&
    //     (head_ptr[BIT_DEPTH-1] != tail_ptr[BIT_DEPTH-1])
    // );
    assign is_full = (
        (head_ptr[BIT_DEPTH-2:0] == tail_ptr[BIT_DEPTH-2:0]) &&
        (head_ptr[BIT_DEPTH-1] != tail_ptr[BIT_DEPTH-1])
    );

    assign is_empty = head_ptr == tail_ptr;

    always_ff @(posedge clk) begin
        if(rst) begin
            head_ptr <= '0;
            tail_ptr <= '0;
        end else begin
            head_ptr <= head_ptr_next;
            tail_ptr <= tail_ptr_next;

            // Write Data Synchronously

            if(swap_data && !write_data)begin
                entries[swap_idx].store_addr<= store_addr;
                entries[swap_idx].wdata <= wdata;
                entries[swap_idx].wmask <= wmask;
            end

            if(!swap_data && write_data) begin
                entries[tail_ptr[BIT_DEPTH-2:0]].store_addr <= store_addr;
                entries[tail_ptr[BIT_DEPTH-2:0]].wdata <= wdata;
                entries[tail_ptr[BIT_DEPTH-2:0]].wmask <= wmask;
            end
            
            if(flush) begin
                entries <= '{default: '0};
                head_ptr <= '0;
                tail_ptr <= '0;
            end
            
        end
    end

    always_comb begin :addr_compare
        sb_match = 1'b0; 
        swap_data = 1'b0;
        swap_idx = '0; 
        r_data ='x; 

        //might need to change i to logic or smth
        for( int i = '0; i < QUEUE_DEPTH; i++)begin
            swap_idx = swap_data + 4'b1;
            if((store_addr == entries[i].store_addr) && enqueue && (store_addr != '0 && entries[i].store_addr !='0 ))begin
                swap_data = 1'b1;
                sb_match = 1'b0; 
            end

            if((load_addr == entries[i].store_addr) && !enqueue && (load_addr != '0 && entries[i].store_addr !='0 ))begin
                if(rmask <= entries[i].wmask)begin
                    sb_match = 1'b1;   
                    r_data = entries[i].wdata; 
                end else begin
                    sb_match = 1'b0;   
                end
            end
        end
    end :addr_compare 


    always_comb begin
        head_ptr_next = head_ptr; // Don't Move pointers when not reading or writing
        tail_ptr_next = tail_ptr;
        write_data = 1'b0; // Default Don't Write Data
        // dequeue_rdata = 'x; // Read Data Doesn't Matter when not reading
        // dequeue = 1'b0; 

        if(enqueue && dequeue && !swap_data) begin 
            if(is_empty) begin
                head_ptr_next = head_ptr; // Don't move head pointer if we are currently empty
            end else begin
                head_ptr_next = head_ptr + 1'b1; // Move the head pointer if there is data
                // dequeue_rdata = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
            end

            // if(is_full) begin
            //     tail_ptr_next = tail_ptr; // Don't move tail pointer if its full
            // end else begin
                tail_ptr_next = tail_ptr + 1'b1; // Move tail pointer if there is room
                write_data = 1'b1; // Send Signal to Write Data
            // end
        end else if(enqueue && !dequeue && !swap_data) begin

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
                // dequeue_rdata = entries[head_ptr[BIT_DEPTH-2:0]]; // Read Data Out
            end

        end else if(!enqueue && !dequeue) begin
            head_ptr_next = head_ptr;
            tail_ptr_next = tail_ptr;
        end
    end

endmodule


