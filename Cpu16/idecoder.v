`include "alu.vh"

/*

instruction format
[31:16] address
[15:8] register id
[7:0] opcode

[31:16] immediate constant
[15:8] register id
[7:5] opcode
[4:0] alu op_id

[31:24] io address offset
[23:16] io address register
[15:8] register id
[7:5] opcode
[4:0] alu op_id

*/

module idecoder
#(parameter BITS = 16, STACK_BITS = 4)
(
    input wire [2:0] stage,
    input wire reset,
    input wire [BITS * 2 - 1:0] instruction,
    input wire c,
    input wire z,
    input wire [BITS - 1:0] alu_out,
    input wire [BITS - 1:0] io_data_in,
    output reg [BITS - 1:0] address,
    output reg [`ALU_OPID_WIDTH - 1:0] alu_op_id,
    output reg [BITS - 1:0] alu_op1,
    output reg [BITS - 1:0] alu_op2,
    output reg [BITS - 1:0] alu_op3,
    output reg hlt,
    output reg error,
    output reg io_rd = 1,
    output reg io_wr = 1,
    output reg [BITS - 1:0] io_data_out,
    output reg [BITS - 1:0] io_address,
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
            error <= 0;
            sp <= 0;
            io_rd <= 1;
            io_wr <= 1;
            max_stage <= 2;
            io_data_direction <= 1;
            alu_clk <= 0;
            address <= 0;
        end
        else begin
            case (stage)
                0: begin
                    alu_clk <= 0;
                    io_data_direction <= 1;
                end
                1:
                    case (instruction[7:`ALU_OPID_WIDTH])
                        // jmp instructions
                        0: begin
                            max_stage <= 2;
                            alu_op_id <= `ALU_OP_NOP;
                            case (instruction[`ALU_OPID_WIDTH - 1:0])
                                //jump
                                0: address <= instruction[BITS * 2 - 1: BITS];
                                //jump if carry
                                1: begin
                                    if (c == 1)
                                        address <= instruction[BITS * 2 - 1: BITS];
                                    else
                                        address <= address + 1;
                                end
                                //jump if zero
                                2: begin
                                    if (z == 1)
                                        address <= instruction[BITS * 2 - 1: BITS];
                                    else
                                        address <= address + 1;
                                end
                                // jump by register value
                                'h10: address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                                // jump by register value if carry
                                'h11: begin
                                    if (c == 1)
                                        address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                                    else
                                        address <= address + 1;
                                end
                                //jump by register value if zero
                                'h12: begin
                                    if (z == 1)
                                        address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                                    else
                                        address <= address + 1;
                                end
                                //error
                                default: begin
                                    hlt <= 1;
                                    error <= 1;
                                end
                            endcase
                        end
                        // call instructions
                        1: begin
                            max_stage <= 2;
                            alu_op_id <= `ALU_OP_NOP;
                            case (instruction[`ALU_OPID_WIDTH - 1:0])
                                //call
                                0: begin
                                    address <= instruction[BITS * 2 - 1: BITS];
                                    stack[sp - 1] <= address + 1;
                                    sp <= sp - 1;
                                end
                                //call if carry
                                1: begin
                                    if (c == 1) begin
                                        address <= instruction[BITS * 2 - 1: BITS];
                                        stack[sp - 1] <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    else
                                        address <= address + 1;
                                end
                                //call if zero
                                2: begin
                                    if (z == 1) begin
                                        address <= instruction[BITS * 2 - 1: BITS];
                                        stack[sp - 1] <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    else
                                        address <= address + 1;
                                end
                                //call by register value
                                'h10: begin
                                    address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                                    stack[sp - 1] <= address + 1;
                                    sp <= sp - 1;
                                end
                                //call by register value if carry
                                'h11: begin
                                    if (c == 1) begin
                                        address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                                        stack[sp - 1] <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    else
                                        address <= address + 1;
                                end
                                //call by register value if zero
                                'h12: begin
                                    if (z == 1) begin
                                        address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                                        stack[sp - 1] <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    else
                                        address <= address + 1;
                                end
                                // error
                                default: begin
                                    hlt <= 1;
                                    error <= 1;
                                end
                            endcase
                        end
                        // return/special opcodes
                        2: begin
                            max_stage <= 2;
                            alu_op_id <= `ALU_OP_NOP;
                            case (instruction[`ALU_OPID_WIDTH - 1:0])
                                // NOP
                                0: address <= address + 1;
                                // return
                                1: begin
                                    address <= stack[sp];
                                    sp <= sp + 1;
                                end
                                //return if carry
                                2: begin
                                    if (c == 1) begin
                                        address <= stack[sp];
                                        sp <= sp + 1;
                                    end
                                    else
                                        address <= address + 1;
                                end
                                //return if zero
                                3: begin
                                    if (z == 1) begin
                                        address <= stack[sp];
                                        sp <= sp + 1;
                                    end
                                    else
                                        address <= address + 1;
                                end
                                //hlt
                                'h1F: hlt <= 1;
                                // error
                                default: begin
                                    hlt <= 1;
                                    error <= 1;
                                end
                            endcase
                        end
                        // alu instruction, register->register
                        3: begin
                            max_stage <= 2;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[23:16]];
                            alu_op2 <= registers[instruction[31:24]];
                        end
                        // alu instruction, immediate->register
                        4: begin
                            max_stage <= 2;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= instruction[31:16];
                            alu_op2 <= registers[instruction[15:8]];
                        end
                        // alu instruction, io->register
                        5: begin
                            max_stage <= 3;
                            io_address <= registers[instruction[23:16]] + {{8{1'b0}}, instruction[BITS * 2 - 1: 24]};
                            io_rd <= 0;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[15:8]];
                        end
                        // alu instruction, register->io
                        6: begin
                            max_stage <= 4;
                            io_address <= registers[instruction[23:16]] + {{8{1'b0}}, instruction[BITS * 2 - 1: 24]};
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[15:8]];
                            alu_op2 <= registers[instruction[15:8]];
                        end
                        //error
                        default: begin
                            hlt <= 1;
                            error <= 1;
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
                    io_rd <= 1;
                    case (instruction[7:`ALU_OPID_WIDTH])
                        // alu instruction, register->register or immediate->register
                        3, 4: registers[instruction[15:8]] <= alu_out;
                        // alu instruction, register->io
                        6: begin
                            io_wr <= 0;
                            io_data_direction <= 0;
                            io_data_out <= alu_out;
                        end
                        default: begin end
                    endcase
                end
                4: io_wr <= 1;
                //error
                default: begin
                    hlt <= 1;
                    error <= 1;
                end
            endcase
        end
    end
endmodule
