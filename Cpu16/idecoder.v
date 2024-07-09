`include "alu.vh"

/*

instruction format
[31:16] immediate constant
[31:16] immediate constant
[31:24] register id1
[23:16] register id2
[15:8] register id3
[7:5] additional_data
[4:0] alu op_id
*/

module idecoder
#(parameter BITS = 16, STACK_BITS = 4)
(
    input wire [2:0] stage,
    input wire reset,
    input wire [BITS * 2 - 1:0] instruction,
    input wire [BITS - 1:0] address,
    input wire c,
    input wire z,
    input wire [BITS - 1:0] alu_out,
    input wire [BITS - 1:0] io_data_in,
    output reg [`ALU_OPID_WIDTH - 1:0] alu_op_id,
    output reg [BITS - 1:0] alu_op1,
    output reg [BITS - 1:0] alu_op2,
    output reg [BITS - 1:0] alu_op3,
    output reg [BITS - 1:0] next_address,
    output reg hlt,
    output reg io_rd = 1,
    output reg io_wr = 1,
    output reg [BITS - 1:0] io_data_out,
    output reg alu_clk,
    output reg io_data_direction = 1,
    output reg [2:0] max_stage
);
    reg [BITS - 1:0] stack [0:(1 << STACK_BITS) - 1];
    reg [STACK_BITS - 1:0] sp;
    reg [BITS - 1:0] registers [0:255];

    always @(stage or negedge reset) begin
        if (reset == 0) begin
            hlt <= 0;
            sp <= 0;
            io_rd <= 1;
            io_wr <= 1;
            max_stage <= 2;
            io_data_direction <= 1;
            alu_clk <= 0;
        end
        else begin
            case (stage)
                0: begin
                    alu_clk <= 0;
                    io_data_direction <= 1;
                end
                1:
                    case (instruction[7:`ALU_OPID_WIDTH])
                        // jmp/call/return instructions
                        0: begin
                            max_stage <= 2;
                            alu_op_id <= `ALU_OP_NOP;
                            case (instruction[`ALU_OPID_WIDTH - 1:0])
                                // NOP
                                0: next_address <= address + 1;
                                //jump
                                1: next_address <= instruction[BITS * 2 - 1: BITS];
                                //jump if carry
                                2: begin
                                    if (c == 1)
                                        next_address <= instruction[BITS * 2 - 1: BITS];
                                    else
                                        next_address <= address + 1;
                                end
                                //jump if zero
                                3: begin
                                    if (z == 1)
                                        next_address <= instruction[BITS * 2 - 1: BITS];
                                    else
                                        next_address <= address + 1;
                                end
                                // jump by register value
                                4: next_address <= registers[instruction[15:8]];
                                //call
                                9: begin
                                    next_address <= instruction[BITS * 2 - 1: BITS];
                                    stack[sp - 1] <= address + 1;
                                    sp <= sp - 1;
                                end
                                //call if carry
                                'hA: begin
                                    if (c == 1) begin
                                        next_address <= instruction[BITS * 2 - 1: BITS];
                                        stack[sp - 1] <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    else
                                        next_address <= address + 1;
                                end
                                //call if zero
                                'hB: begin
                                    if (z == 1) begin
                                        next_address <= instruction[BITS * 2 - 1: BITS];
                                        stack[sp - 1] <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    else
                                        next_address <= address + 1;
                                end
                                // return
                                'h11: begin
                                    next_address <= stack[sp];
                                    sp <= sp + 1;
                                end
                                //return if carry
                                'h12: begin
                                    if (c == 1) begin
                                        next_address <= stack[sp];
                                        sp <= sp + 1;
                                    end
                                    else
                                        next_address <= address + 1;
                                end
                                //return if zero
                                'h13: begin
                                    if (z == 1) begin
                                        next_address <= stack[sp];
                                        sp <= sp + 1;
                                    end
                                    else
                                        next_address <= address + 1;
                                end
                                //hlt
                                'h1F: hlt <= 1;
                                //NOP
                                default: next_address <= address + 1;
                            endcase
                        end
                        // alu instruction, register->register
                        1: begin
                            max_stage <= 2;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[23:16]];
                            alu_op2 <= registers[instruction[31:24]];
                        end
                        // alu instruction, immediate->register
                        2: begin
                            max_stage <= 2;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= instruction[31:16];
                            alu_op2 <= registers[instruction[15:8]];
                        end
                        // alu instruction, io->register
                        2: begin
                            max_stage <= 3;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op2 <= registers[instruction[15:8]];
                        end
                        // alu instruction, register->io
                        3: begin
                            max_stage <= 4;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[15:8]];
                            alu_op2 <= registers[instruction[15:8]];
                        end
                        //NOP
                        default: begin
                            max_stage <= 2;
                            alu_op_id <= `ALU_OP_NOP;
                            next_address <= address + 1;
                        end
                    endcase
                2: begin
                    if (max_stage != 3'd3)
                        alu_clk <= 1;
                    else
                        alu_op2 <= io_data_in;
                end
                3: begin
                    alu_clk <= 1;
                    case (instruction[7:`ALU_OPID_WIDTH])
                        // alu instruction, register->register or immediate->register
                        1, 2: registers[instruction[15:8]] <= alu_out;
                        // alu instruction, register->io
                        3: begin
                            io_wr <= 0;
                            io_data_direction <= 0;
                            io_data_out <= alu_out;
                        end
                        default: begin end
                    endcase
                end
                4: io_wr <= 1;
                default: begin end
            endcase
        end
    end
endmodule
