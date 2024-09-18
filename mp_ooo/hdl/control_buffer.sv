module control_buffer #(parameter QUEUE_WIDTH = 32, QUEUE_DEPTH = 16, BIT_DEPTH = 5)
(
    input   logic                       clk,
    input   logic                       rst,
    input   logic                       enqueue,
    input   logic   [QUEUE_WIDTH-1:0]   enqueue_wdata,
    input   logic                       dequeue,
    input   logic                       flush,
    output  logic   [QUEUE_WIDTH-1:0]   dequeue_rdata,
    output  logic                       is_empty,
    output  logic                       is_full
    // output  logic                       almost_full
);
//ADD LOGIC FOR FLUSH


    // Parameters: QUEUE_WIDTH = Size of data (# bits), QUEUE_DEPTH = # of entries, BIT_DEPTH = # bits to index entries + 1 overflow bit

    logic   [QUEUE_WIDTH-1:0] entries [QUEUE_DEPTH];


    logic   [BIT_DEPTH-1:0]     head_ptr;
    logic   [BIT_DEPTH-1:0]     tail_ptr;
    logic   [BIT_DEPTH-1:0]     head_ptr_next;
    logic   [BIT_DEPTH-1:0]     tail_ptr_next;

    logic   write_data;
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
            entries <= '{default: '0};
        end else begin
            head_ptr <= head_ptr_next;
            tail_ptr <= tail_ptr_next;

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
        dequeue_rdata = 'x; // Read Data Doesn't Matter when not reading

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

