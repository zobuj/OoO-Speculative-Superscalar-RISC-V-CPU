module fetch_tb;
    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = 5;
    
    bit clk;
    always #(clock_half_period_ps)clk = ~clk;
    
    bit rst;
    int timeout = 10000000; // in cycles, change according to your needs
    
    logic   [31:0]  imem_rdata;
    logic           imem_resp;
    logic   [3:0]   imem_rmask;
    logic   [31:0]  imem_addr;
    logic   [31:0]  pc;
    logic   [31:0]  pc_next;
    logic   [63:0]  order;
    logic           commit;
    logic           enqueue;
    logic           dequeue;

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;
    end

    fetch dut(
        .clk(clk),
        .rst(rst),
        .imem_rdata(imem_rdata),
        .imem_resp(imem_resp),
        .imem_rmask(imem_rmask),
        .imem_addr(imem_addr),
        .pc(pc),
        .pc_next(pc_next),
        .order(order),
        .commit(commit), 
        .enqueue(enqueue),
        .dequeue(dequeue)
    );

    task testing1();
            dequeue = 1'b0;
            enqueue = 1'b0;

        for(int i = 0; i<16; i++) begin
            @(posedge clk);
            std::randomize(imem_rdata);
            imem_resp <= 1'b1;
            enqueue <= 1'b1;
        end
        for(int j = 0; j<16; j++) begin
            @(posedge clk);
            dequeue <= 1'b1;
            enqueue <= 1'b0;
        end
    endtask
    task testing();
    repeat(100) begin
        @(posedge clk);
        std::randomize(imem_rdata);
        imem_resp <= 1'b1;
        enqueue = 1'b1;
        dequeue = dut.queue.is_full;

        // std::randomize(enqueue) with {
        //     enqueue inside {1'b0, 1'b1};
        // };

        // std::randomize(dequeue) with {
        //     dequeue inside {1'b0, 1'b1};
        // };
    end
    endtask
    initial begin
        @(posedge clk iff rst == 1'b1);
        // testing1();
        testing();
        #1000
        $finish;
    end
endmodule