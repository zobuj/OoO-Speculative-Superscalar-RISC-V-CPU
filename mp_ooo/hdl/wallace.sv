

module WallaceTreeMultiplier 
import rv32i_types::*;
// # (paramater WIDTH = 64, HEIGHT = 32 )

(

    input                   clk, 
    input                   rst, 
    input logic [31:0]      a,
    input logic [31:0]      b,
    input logic             start, 
    input logic [1:0]       mul_type,

    output logic             done, 
    output logic [63:0]     p 

);

    enum logic [1:0]{
        idle, 
        compression,
        final_addition,
        done_stage
    } curr_state, next_state; 

    `define UNSIGNED_UNSIGNED_MUL 2'b11
    `define SIGNED_SIGNED_MUL     2'b01
    `define SIGNED_UNSIGNED_MUL   2'b10

    //32 rows, 64 entries 
    logic [63:0] partial_array [32];
    logic [63:0] partial_array2 [32];

    // 1 row, 64 entries, each entry is 6 bits 
    // holds the sum of each column within the partial array 
    logic [5:0] compressed_sums [64];
    logic [5:0] compressed_sums2 [64];
    logic [5:0] compressed_sums3 [64];
    logic [5:0] compressed_sums4 [64];
    logic [5:0] compressed_sums5 [64];
    logic [5:0] compressed_sums_temp [64];

    logic [5:0] counter;
    logic ready; 
    logic ready_temp; 
    logic  is_neg; 

    logic [31:0] a_reg;
    logic [31:0] b_reg;
    // logic done2; 

    // logic [63:0] finalSum

    always_comb begin

        a_reg = a; 
        b_reg = b; 
        is_neg = '0;
        case (mul_type)
            
            `UNSIGNED_UNSIGNED_MUL:begin
               is_neg = 1'b0;  
            end 

            `SIGNED_SIGNED_MUL: begin
                if(a[31] == 1'b1 && b[31] == 1'b1)begin
                    //convert both a and b to positive, then keep track of negative 
                    is_neg = 1'b0; 
                    a_reg = ~a + 1'b1; 
                    b_reg = ~b + 1'b1; 
                end else if((a[31] != 1'b1 && b[31] == 1'b1))begin
                    is_neg = 1'b1; 
                    b_reg = ~b + 1'b1; //convert to positive, keep track of negative sign 
                end else if((a[31] == 1'b1 && b[31] != 1'b1))begin
                    is_neg = 1'b1; 
                    a_reg = ~a + 1'b1; 
                end else begin
                    //both not negative 
                    is_neg = 1'b0; 
                end
            end


            `SIGNED_UNSIGNED_MUL: begin
                //only a can be negative 
                if(a[31] == 1'b1 )begin
                    is_neg = 1'b1; 
                    a_reg = ~a + 1'b1; 
                end else begin
                    is_neg = 1'b0; 
                end
            end


            default : ; 
        endcase
    end

    always_comb begin
        // if(rst)begin
        //     // curr_state = idle;
        //     compressed_sums = '{default: '0};
        //     // compressed_sums2 = '{default: '0};
        //       compressed_sums3 = '{default: '0};
        //     next_state = idle;
        //     counter = '0; 
        //     partial_array = '{default: '0};
        //     done = '0; 
        //     p = '0; 
        //      //     curr_state = idle;
        // end
        // else begin
            compressed_sums = '{default: '0};
            compressed_sums_temp = '{default: '0};
            // compressed_sums2 = '{default: '0};
            compressed_sums3 = '{default: '0};
            next_state = idle;
            counter = '0; 
            partial_array = '{default: '0};
            done = '0; 
            p = '0; 

        // next_state = curr_state; 
            case (curr_state) 
                idle: begin
                    // ((start && !done) == 1'b1) ? compression : idle;
                    done = '0; 
                    if(start && (b != '0 && a != '0) )begin
                        next_state = compression; 
                         for (int i = 0; i < 32; i++) begin
                        //bit expansions to 64 bits 
                                partial_array[i] = '0; 
                            if(b_reg[i] == 1'b1)begin
                            partial_array[i] = {{32{1'd0}} , a_reg} << i; 
                            end 
                            // else begin
                            // end
                        end
                    end else if(start && (b == '0 || a == '0))begin 
                        next_state = done_stage;
                    end else begin
                        next_state = idle; 
                        
                    end
                end    
                compression: begin
                    // compress(); 
                     for(int i = 0; i < 64; i++)begin
                // for(int j = 0; j < 64; j++)begin
                compressed_sums[i] = {{5{1'b0}},partial_array2[0][i]} + {{5{1'b0}},partial_array2[1][i]} +  {{5{1'b0}},partial_array2[2][i]} +  {{5{1'b0}},partial_array2[3][i]} + {{5{1'b0}},partial_array2[4][i]} + {{5{1'b0}},partial_array2[5][i]} +  {{5{1'b0}},partial_array2[6][i]} + {{5{1'b0}},partial_array2[7][i]} + 
                                        {{5{1'b0}},partial_array2[8][i]} + {{5{1'b0}},partial_array2[9][i]} + {{5{1'b0}},partial_array2[10][i]} + {{5{1'b0}},partial_array2[11][i]} + {{5{1'b0}},partial_array2[12][i]} + {{5{1'b0}},partial_array2[13][i]} + {{5{1'b0}},partial_array2[14][i]} + {{5{1'b0}},partial_array2[15][i]} + 
                                            {{5{1'b0}},partial_array2[16][i]}+ {{5{1'b0}},partial_array2[17][i]} +  {{5{1'b0}},partial_array2[18][i]} +  {{5{1'b0}},partial_array2[19][i]} + {{5{1'b0}},partial_array2[20][i]}+ {{5{1'b0}},partial_array2[21][i]} +  {{5{1'b0}},partial_array2[22][i]} +  {{5{1'b0}},partial_array2[23][i]}+ 
                                                {{5{1'b0}},partial_array2[24][i]}+ {{5{1'b0}},partial_array2[25][i]} +  {{5{1'b0}},partial_array2[26][i]} +  {{5{1'b0}},partial_array2[27][i]} + {{5{1'b0}},partial_array2[28][i]}+ {{5{1'b0}},partial_array2[29][i]} +  {{5{1'b0}},partial_array2[30][i]} +  {{5{1'b0}},partial_array2[31][i]};                        
                    end
                     next_state = final_addition;
                end
                final_addition:begin
                    compressed_sums3 = compressed_sums2;
                    compressed_sums_temp = compressed_sums2;
                    for(int i = 0; i < 20; i++)begin

                            for(int i = 0; i < 64; i++)begin
                                if(i == 0)begin
                                     compressed_sums3[i] = compressed_sums_temp[0];
                                end
                                else if (i ==1) begin
                                     compressed_sums3[i] = {{5{1'b0}}, compressed_sums_temp[i][0]};
                                end
                                else if(i == 2)begin
                                    compressed_sums3[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]};
                                end 
                                else if(i == 3)begin
                                    compressed_sums3[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]} + {{5{1'b0}}, compressed_sums_temp[i-3][3]};
                                end 
                                else if (i == 4) begin
                                    compressed_sums3[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]} +  {{5{1'b0}}, compressed_sums_temp[i-3][3]} + {{5{1'b0}}, compressed_sums_temp[i-4][4]};
                                end 
                                else begin
                                    compressed_sums3[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]} +  {{5{1'b0}}, compressed_sums_temp[i-3][3]} + {{5{1'b0}},compressed_sums_temp[i-4][4]} + {{5{1'b0}},compressed_sums_temp[i-5][5]};
                                end 

                        end
                        // counter = counter + 1'b1; 
                        compressed_sums_temp = compressed_sums3; 
                    end
                        compressed_sums3[1] = {{5{1'b0}},compressed_sums3[1][0]};

                    //  next_state = (ready == 1'b1) ? idle : final_addition; 
                     next_state =  done_stage; 

                end
                
                done_stage: begin
                    done = 1'b1;
                    
                    compressed_sums5 = compressed_sums4;
                    compressed_sums_temp = compressed_sums4;
                    for(int i = 0; i < 13; i++)begin

                            for(int i = 2; i < 64; i++)begin
                                if(i == 0)begin
                                     compressed_sums5[i] = compressed_sums_temp[0];
                                end
                                else if (i ==1) begin
                                     compressed_sums5[i] = {{5{1'b0}}, compressed_sums_temp[i][0]};
                                end
                                else if(i == 2)begin
                                    compressed_sums5[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]};
                                end 
                                else if(i == 3)begin
                                    compressed_sums5[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]} + {{5{1'b0}}, compressed_sums_temp[i-3][3]};
                                end 
                                else if (i == 4) begin
                                    compressed_sums5[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]} +  {{5{1'b0}}, compressed_sums_temp[i-3][3]} + {{5{1'b0}}, compressed_sums_temp[i-4][4]};
                                end 
                                else begin
                                    compressed_sums5[i] = {{5{1'b0}}, compressed_sums_temp[i][0]} + {{5{1'b0}}, compressed_sums_temp[i-1][1]} + {{5{1'b0}}, compressed_sums_temp[i-2][2]} +  {{5{1'b0}}, compressed_sums_temp[i-3][3]} + {{5{1'b0}},compressed_sums_temp[i-4][4]} + {{5{1'b0}},compressed_sums_temp[i-5][5]};
                                end 

                        end
                        // counter = counter + 1'b1; 
                        compressed_sums_temp = compressed_sums5; 
                    end
                        // compressed_sums5[i] = compressed_sums_temp[0];

                        // compressed_sums5[1] = {{5{1'b0}},compressed_sums5[1][0]};


                    if(is_neg)begin
                        for(int i = 0; i < 64; i++)begin
                            p[i] = ~compressed_sums5[i][0];             
                        end
                        p = p + { {63{1'b0}}, 1'b1};
                    end else begin
                        for(int i = 0; i < 64; i++)begin
                            p[i] = compressed_sums5[i][0];             
                        end
                    end

                    next_state = (start == 1'b1) ? done_stage :idle; 
                end 

                default: ; 
            endcase
        end
    // end

    // always_ff @(posedge clk)begin

    //     if(is_neg)begin
    //         for(int i = 0; i < 64; i++)begin
    //                 p[i] <= ~compressed_sums4[i][0];             
    //             end
    //             p = p + { {63{1'b0}}, 1'b1};
    //         end else begin
    //             for(int i = 0; i < 64; i++)begin
    //                 p[i] <= compressed_sums4[i][0];             
    //             end
    //         end
    // end
        // assign ready = (counter == 6'd9) ;
    always_ff @(posedge clk) begin 
        if(rst) begin
            curr_state <= idle;
            compressed_sums2 <= '{default: '0};
            partial_array2 <= '{default: '0};
        end else begin 
            curr_state <= next_state; 

            // case (curr_state)
                // idle:
                 partial_array2 <= partial_array;
                // compression: 
                compressed_sums2 <= compressed_sums;
                // final_addition: 
                if(!done) begin
                    compressed_sums4 <= compressed_sums3;
                end else  begin
                    compressed_sums4 <= compressed_sums4;

                end
                // done_stage: ;
                // default: ;
            // endcase
            // compressed_sums2 <= compressed_sums;
            // done <= done2; 
        end
    end

endmodule