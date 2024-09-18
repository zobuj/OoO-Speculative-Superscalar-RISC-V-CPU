module shift_sub_divider
#(
    parameter int OPERAND_WIDTH = 32
)
(
    input logic clk,
    input logic rst,
    // Start must be reset after the done flag is set before another multiplication can execute
    input logic start,

    // Use this input to select what type of multiplication you are performing
    // 0 = Divide two unsigned numbers
    // 1 = Divide two signed numbers
    // 2 = Divide a signed number and unsigned number
    //      a = signed
    //      b = unsigned
    input logic [1:0] div_type,

    input logic[OPERAND_WIDTH-1:0] a,
    input logic[OPERAND_WIDTH-1:0] b,
    output logic[OPERAND_WIDTH-1:0] q,
    output logic[OPERAND_WIDTH -1 :0] rem, 
    output logic done
);

    // Constants for divide case readability
    `define UNSIGNED_UNSIGNED_MUL 2'b11
    `define SIGNED_SIGNED_MUL     2'b01
    // `define SIGNED_UNSIGNED_MUL   2'b10

    // enum int unsigned {IDLE, SHIFT, SUBTRACT, DONE} curr_state, next_state;
    enum int unsigned {IDLE, SHIFT, DONE} curr_state, next_state;
    localparam int OP_WIDTH_LOG = $clog2(OPERAND_WIDTH);
    logic [OP_WIDTH_LOG:0] counter;
    logic [OPERAND_WIDTH-1:0] b_reg, a_reg;
    logic [OPERAND_WIDTH:0] accumulator; 

    logic [31:0] quo_temp;
    logic neg_result;
    logic subtract_flag;
    logic edge_case;


    always_comb
    begin : state_outputs
        done = '0;
        q = '0;
        rem = '0; 
        unique case (curr_state)
            DONE:
            begin
                done = 1'b1;
                rem = (b == '0 || a<b) ? a : accumulator[OPERAND_WIDTH-1 : 0]; 
                if((a == 32'hefffffff && b == 32'hffffffff))begin
                    rem = '0; 
                end
                // if(accumulator[OPERAND_WIDTH] && is_neg)begin //signed overflow?
                // end
                unique case (div_type)
                    `UNSIGNED_UNSIGNED_MUL:begin
                        if(b== '0 || a =='b0 || a < b)begin
                            q = '0; 
                        end else begin
                            q = quo_temp;
                        end
                    end 
                    `SIGNED_SIGNED_MUL: begin
                        if(b== '0 || a =='b0 || a < b)begin
                            q = neg_result ? (~quo_temp)+1'b1 : quo_temp;
                        end else begin
                            q = quo_temp;
                        end
                        //  rem = accumulator[OPERAND_WIDTH-1 : 0];
                    end 
                    default: ;
                endcase
            end
            default: ;
        endcase
    end : state_outputs

    always_comb
    begin : state_transition
        next_state = curr_state;
            subtract_flag = 1'b0; 
            edge_case = 1'b0; 

        unique case (curr_state)
            IDLE:   begin
                next_state = start ? SHIFT : IDLE;
                if(((a == '0 || b == '0 || a < b) && start) || (start && (a == 32'hefffffff && b == 32'hffffffff && div_type ==2'b01)) )begin
                    edge_case = 1'b1; 
                    next_state = DONE; 
                end
            end 
            // SUBTRACT:     next_state = counter > 6'd31 ? DONE : SHIFT;
            SHIFT: begin   
                
                    if(accumulator >= {{1{1'b0}}, b_reg})begin
                    //    accumulator <= accumulator - b_reg; 
                        // next_state = SUBTRACT; 
                        subtract_flag = 1'b1; 
 
                    end else if(counter  >= (6'd32) ) begin
                        next_state = DONE; 
                        // counter = '0;
                        // accumulator = '0; 
                        // counter = counter + 1'b1;
                    end else begin
                        // counter = counter + 1'b1; 
                        next_state = SHIFT;
                    end
            end
            DONE:    next_state = start ? DONE : IDLE;
            default: next_state = curr_state;
        endcase
    end : state_transition

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            curr_state <= IDLE;
            a_reg <= '0;
            b_reg <= '0;
            accumulator <= '0;
            counter <= '0;
            neg_result <= '0;
            quo_temp <= '0; 
            // done <= '0;
            // q <= '0;
            // rem <= '0;
        end

        else
        begin
            // done <= '0;
            // q <= '0;
            // rem <= '0;
            // next_state <= IDLE;
            // a_reg <= '0;
            // b_reg <= '0;
            accumulator <= '0;
            // counter <= '0;
            // neg_result <= '0;
            // quo_temp <= '0; 
            curr_state <= next_state;

            unique case (curr_state)
                IDLE:
                begin
                    if (start && !edge_case)
                    begin
                        quo_temp <= '0; 

                        accumulator <= '0;
                        unique case (div_type)
                            `UNSIGNED_UNSIGNED_MUL:
                            begin
                                neg_result <= '0;   // Not used in case of unsigned mul, but just cuz . . .
                                a_reg <= a;
                                b_reg <= b;
                            end
                            `SIGNED_SIGNED_MUL:
                            begin
                                // A -*+ or +*- results in a negative number unless the "positive" number is 0
                                neg_result <= (a[OPERAND_WIDTH-1] ^ b[OPERAND_WIDTH-1]) && ((a != '0) && (b != '0));
                                // If operands negative, make positive
                                a_reg <= (a[OPERAND_WIDTH-1]) ?  (~a + 1'b1) : a;
                                b_reg <= (b[OPERAND_WIDTH-1]) ?  (~b + 1'b1) : b;
                            end
                            // `SIGNED_UNSIGNED_MUL:
                            // begin
                            //     neg_result <= a[OPERAND_WIDTH-1];
                            //     a_reg <= (a[OPERAND_WIDTH-1]) ? (~a + 1'b1) : a;
                            //     b_reg <= b;
                            // end
                            default:;
                        endcase
                    end
                end
                // SUBTRACT: begin
                    //  if(counter < 6'd32)begin
                //    quo_temp[0] <= 1'b1; 
                //    accumulator <= accumulator - b_reg; 
                    // end
                // end

                SHIFT:
                begin
                    if(counter < 6'd32 && !subtract_flag)begin
                        accumulator <= {accumulator[OPERAND_WIDTH-1:0], a_reg[OPERAND_WIDTH-1]};
                        quo_temp <= quo_temp << 1;
                        a_reg <= a_reg << 1;
                        counter <= counter + 1'b1;
                    end else if(subtract_flag) begin
                        quo_temp[0] <= 1'b1; 
                        accumulator <= accumulator - b_reg; 
                    end else begin
                        accumulator<= accumulator;
                    end
                end

                DONE: begin
                    // done = 1'b1;
                    accumulator <= accumulator;  
                    counter <= '0; 

                    // unique case (div_type)
                    //     `UNSIGNED_UNSIGNED_MUL:begin
                    //     q <= quo_temp;
                    //     rem <= accumulator[OPERAND_WIDTH-1 : 0]; 
                    // end 
                    //     `SIGNED_UNSIGNED_MUL: begin
                    //     q <= neg_result ? (~quo_temp)+1'b1 : quo_temp;
                    //      rem <= accumulator[OPERAND_WIDTH-1 : 0];
                    // end 
                    //     default: ;
                    // endcase
            // end
                end
                default: ;
            endcase
        end
    end


endmodule