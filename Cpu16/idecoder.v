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
    input wire clk,
    input wire reset,
    input wire interrupt,
    input wire [BITS * 2 - 1:0] instruction,
    input wire c,
    input wire z,
    input wire [BITS - 1:0] alu_out,
    input wire [BITS - 1:0] alu_out2,
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
    output reg io_data_direction = 1
);
    reg [BITS - 1:0] stack [0:(1 << STACK_BITS) - 1];
    reg [STACK_BITS - 1:0] sp;
    reg [BITS - 1:0] registers [0:255];
    reg [2:0] stage, max_stage;
    reg [BITS * 2 - 1:0] current_instruction;
    reg in_interrupt;

    function [0:0] jmp(input [3:0] i);
        case (i)
            0: jmp = 1;
            1, 2: jmp = c == i[0];
            3, 4: jmp = z == i[0];
            5: jmp = z == 0 && c == 0;
            6: jmp = z == 1 || c == 1;
            //error
            default: jmp = 0;
        endcase
    endfunction

    always @(posedge clk or negedge reset) begin
        if (reset == 0) begin
            hlt <= 0;
            error <= 0;
            sp <= 0;
            io_rd <= 1;
            io_wr <= 1;
            io_data_direction <= 1;
            alu_clk <= 0;
            address <= 0;
            stage <= 0;
            max_stage <= 2;
            in_interrupt <= 0;
        end
        else if (hlt == 0) begin
            case (stage)
                0: begin
                    alu_clk <= 0;
                    io_data_direction <= 1;
                    io_rd <= 1;
                    if (interrupt == 1 && in_interrupt == 0) begin
                        in_interrupt <= 1;
                        stack[sp - 1] <= address;
                        sp <= sp - 1;
                        address <= 1;
                    end
                    stage <= 1;
                end
                1:  begin
                    current_instruction <= instruction;
                    case (instruction[7:`ALU_OPID_WIDTH])
                        // jmp instructions
                        0: begin
                            stage <= 0;
                            if (jmp(instruction[3:0])) begin
                                if (instruction[4] == 0)
                                    address <= instruction[BITS * 2 - 1: BITS];
                                else
                                    address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                            end
                            else
                                address <= address + 1;
                        end
                        // call instructions
                        1: begin
                            stage <= 0;
                            if (jmp(instruction[3:0])) begin
                                stack[sp - 1] <= address + 1;
                                sp <= sp - 1;
                                if (instruction[4] == 0)
                                    address <= instruction[BITS * 2 - 1: BITS];
                                else
                                    address <= registers[instruction[15:8]] + instruction[BITS * 2 - 1: BITS];
                            end
                            else
                                address <= address + 1;
                        end
                        // return/special opcodes
                        2: begin
                            stage <= 0;
                            case (instruction[`ALU_OPID_WIDTH - 1:0])
                                //ret/reti
                                0,1,2,3,4,5,6,'h10,'h11,'h12,'h13,'h14,'h15,'h16: begin
                                    if (jmp(instruction[3:0])) begin
                                        //reti
                                        if (instruction[3] == 1)
                                            in_interrupt <= 0;
                                        address <= stack[sp];
                                        sp <= sp + 1;
                                    end
                                    else
                                        address <= address + 1;
                                end
                                // mov flags to register
                                'h1B: registers[instruction[15:8]] <= {14'h0, c, z};
                                // NOP
                                'h1C: address <= address + 1;
                                // mov immediate-register
                                'h1D: begin
                                    registers[instruction[15:8]] <= instruction[BITS * 2 - 1: BITS];
                                    address <= address + 1;
                                end
                                // mov register-register
                                'h1E: begin
                                    registers[instruction[15:8]] <= registers[instruction[23:16]] + {{8{1'b0}}, instruction[BITS * 2 - 1: 24]};
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
                            stage <= 2;
                            max_stage <= 3;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[23:16]];
                            alu_op2 <= registers[instruction[31:24]];
                            alu_op3 <= registers[instruction[15:8]];
                            address <= address + 1;
                        end
                        // alu instruction, immediate->register
                        4: begin
                            stage <= 2;
                            max_stage <= 3;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= instruction[31:16];
                            alu_op2 <= registers[instruction[15:8]];
                            address <= address + 1;
                        end
                        // alu instruction, io->register
                        5: begin
                            stage <= 2;
                            max_stage <= 4;
                            io_address <= registers[instruction[31:24]];
                            io_rd <= 0;
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[23:16]];
                            address <= address + 1;
                        end
                        // alu instruction, register->io
                        6: begin
                            stage <= 2;
                            max_stage <= 4;
                            io_address <= registers[instruction[31:24]];
                            alu_op_id <= instruction[`ALU_OPID_WIDTH - 1:0];
                            alu_op1 <= registers[instruction[23:16]];
                            alu_op2 <= registers[instruction[15:8]];
                            address <= address + 1;
                        end
                        // operations without ALU with io
                        7: begin
                            stage <= 2;
                            max_stage <= 2;
                            case (instruction[`ALU_OPID_WIDTH - 1:0])
                                // in io->register
                                0: begin
                                    io_rd <= 0;
                                    io_address <= registers[instruction[23:16]] + {{8{1'b0}}, instruction[BITS * 2 - 1: 24]};
                                end
                                // out register->io
                                1: begin
                                    io_wr <= 0;
                                    io_address <= registers[instruction[23:16]] + {{8{1'b0}}, instruction[BITS * 2 - 1: 24]};
                                    io_data_direction <= 0;
                                    io_data_out <= registers[instruction[15:8]];
                                end
                                default:begin
                                    hlt <= 1;
                                    error <= 1;
                                end
                            endcase
                            address <= address + 1;
                        end
                        //error
                        default: begin
                            hlt <= 1;
                            error <= 1;
                        end
                    endcase
                end
                2: begin
                    if (max_stage == 2) begin
                        if (io_rd == 0)
                            registers[current_instruction[15:8]] <= io_data_in;
                        io_wr <= 1;
                        stage <= 0;
                    end
                    else begin
                        if (max_stage != 3'd4) begin
                            if (current_instruction[7:0] == `ALU_OP_TEST || current_instruction[7:0] == `ALU_OP_CMP)
                                stage <= 0;
                            else
                                stage <= 3;
                            alu_clk <= 1;
                        end
                        else begin
                            alu_op2 <= io_data_in;
                            stage <= 3;
                        end
                    end
                end
                3: begin
                    alu_clk <= 1;
                    io_rd <= 1;
                    case (current_instruction[7:`ALU_OPID_WIDTH])
                        // alu instruction, register->register or immediate->register
                        3, 4: begin
                            if (current_instruction[7:`ALU_OPID_WIDTH] == 3 &&
                                 (current_instruction[`ALU_OPID_WIDTH - 1:0] == `ALU_OP_MUL ||
                                  current_instruction[`ALU_OPID_WIDTH - 1:0] == `ALU_OP_DIV))
                                registers[current_instruction[23:16]] <= alu_out2;
                            registers[current_instruction[15:8]] <= alu_out;
                            stage <= 0;
                        end
                        // alu instruction, io->register
                        5: begin
                            if (current_instruction[7:0] == `ALU_OP_TEST || current_instruction[7:0] == `ALU_OP_CMP)
                                stage <= 0;
                            else
                                stage <= 4;
                        end
                        // alu instruction, register->io
                        6: begin
                            io_wr <= 0;
                            io_data_direction <= 0;
                            io_data_out <= alu_out;
                            stage <= 4;
                        end
                        default: begin end
                    endcase
                end
                4: begin
                    stage <= 0;
                    io_wr <= 1;
                    // alu instruction, io->register
                    if (current_instruction[7:`ALU_OPID_WIDTH] == 5)
                        registers[current_instruction[15:8]] <= alu_out;
                end
                //error
                default: begin
                    hlt <= 1;
                    error <= 1;
                end
            endcase
        end
    end
endmodule
