`include "alu.vh"

/*

Clock diagramm

reset clk rd start stage comment
0     0   1  0     1
0     1   1  0     1
1     0   0  1     1     instruction read start

instruction without alu
reset clk rd start stage alu_clk io_rd io_wr comment
1     1   0  1     0     0       1     1     instruction read
1     0   1  1     0     0       1     1     microcode read
1     1   1  1     1     0       1     1     next address set, action1
1     0   0  1     1     0       1     1     instruction read start, microcode read

instruction with alu
reset clk rd start stage alu_clk io_rd io_wr comment
1     1   0  1     0     0       1     1     instruction read
1     0   1  1     0     0       1     1     microcode read
1     1   1  1     1     1       1     1     next address set, action1
1     0   0  1     1     1       1     1     instruction read start, microcode read

instruction with io read
reset clk rd start stage alu_clk io_rd io_wr comment
1     1   0  1     0     0       1     1     instruction read
1     0   1  1     0     0       0     1     microcode read, io address set
1     1   1  1     1     X       0     1     next address set, action1
1     0   0  1     1     X       1     1     instruction read start, microcode read

instruction with io write
reset clk rd start stage alu_clk io_rd io_wr io_data_direction comment
1     1   0  1     0     0       1     1     1                 instruction read
1     0   1  1     0     0       1     1     1                 microcode read, io address set
1     1   1  1     1     X       1     1     0                 next address set, action1
1     0   0  1     1     X       1     0     0                 instruction read start, microcode read

*/

module cpu
#(parameter BITS = 16, STACK_BITS = 4)
(
    input wire clk,
    input wire reset,
    input wire interrupt,
    // External flash interface
    output reg [BITS - 1:0] address,
    input wire [BITS * 2 - 1:0] data,
    output wire rd,
    // halt flag
    output reg hlt,
    // error flag
    output reg error,
    // IO interface
    output wire io_rd,
    output wire io_wr,
    output wire [BITS - 1:0] io_address,
    inout wire [BITS - 1:0] io_data
);
    parameter MICROCODE_WIDTH = 18;

    // can be registers[current_instruction[31:24] or current_instruction[31:16] or io_data
    function [15:0] alu_op2_f(input [1:0] source);
        case (source)
            0: alu_op2_f = registers[current_instruction[31:24]];
            1: alu_op2_f = current_instruction[31:16];
            default: alu_op2_f = io_data;
        endcase
    endfunction

    reg [BITS - 1:0] registers[0:255];

    reg [BITS - 1:0] stack [(1 << STACK_BITS) - 1:0];
    reg [STACK_BITS - 1:0] sp;
    wire push, pop;

    //ALU related
    wire c, z;
    wire [BITS-1:0] alu_op1, alu_op2, alu_op3, alu_out, alu_out2, io_data_out;
    wire [`ALU_OPID_WIDTH - 1:0] alu_op_id;
    wire alu_clk, alu_clk_set;
    wire alu_op1_source;
    wire [1:0] alu_op2_source;
    wire set_result, set_result2;

    // IO
    wire io_data_direction;
    wire io_data_out_source;
    wire io_address_source;
    wire io_wr_set;

    // address
    wire address_source, address_load;

    // stage
    reg stage;

    reg [BITS * 2 - 1:0] current_instruction;

    reg [MICROCODE_WIDTH - 1:0] microcode_data;
    reg [MICROCODE_WIDTH - 1:0] microcode [0:511];
    wire [MICROCODE_WIDTH - 1:0] current_microinstruction;
    reg microcode_valid;

    // interrupt
    reg in_interrupt;
    wire int_start;

    // error flags
    wire hltf, errorf;

    wire condition_neg, condition_pass;
    wire [2:0] condition_temp, condition_flags;

    reg start;

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    always @(negedge clk) begin
        microcode_data <= microcode[{current_instruction[7:0], stage}];
        if (reset == 0) begin
            start <= 0;
            microcode_valid <= 0;
        end
        else begin
            if (start == 1)
                microcode_valid <= 1;
            start <= 1;
        end
    end

    assign int_start = interrupt == 1 && in_interrupt == 0;

    assign rd = !start | (clk ^ !stage);
    assign current_microinstruction = microcode_valid ? microcode_data : 'b000000000000000111;

    // in reset state:
    // io_rd = io_wr = 1
    // io_data_direction = 1
    // address_load = 1
    assign io_rd = current_microinstruction[0];
    assign io_wr_set = current_microinstruction[1];
    assign io_data_direction = current_microinstruction[2];
    assign address_load = current_microinstruction[3];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign address_source = current_microinstruction[4];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign io_address_source = current_microinstruction[5];
    assign io_data_out_source = current_microinstruction[6];
    assign alu_clk_set = current_microinstruction[7];
    assign condition_neg = current_microinstruction[8];
    assign condition_flags = current_microinstruction[11:9];
    // can be registers[current_instruction[15:8]] or registers[current_instruction[23:16]]
    assign alu_op1_source = current_microinstruction[8];
    // can be registers[current_instruction[31:24]] or current_instruction[31:16] or io_data
    assign alu_op2_source = current_microinstruction[10:9];
    // can be alu_out or registers[current_instruction[15:8]]
    assign hltf = current_microinstruction[12];
    assign errorf = current_microinstruction[13];
    assign push = current_microinstruction[14];
    assign pop = current_microinstruction[15];
    assign set_result = current_microinstruction[16];
    assign set_result2 = current_microinstruction[17];

    assign alu_clk = alu_clk_set & stage;
    assign alu_op_id = current_instruction[`ALU_OPID_WIDTH - 1:0];
    assign alu_op1 = alu_op1_source ? registers[current_instruction[15:8]] : registers[current_instruction[23:16]];
    assign alu_op2 = alu_op2_f(alu_op2_source);
    assign alu_op3 = registers[current_instruction[15:8]];
    
    assign io_data_out = io_data_out_source ? alu_out : registers[current_instruction[15:8]];
    assign io_data = io_data_direction ? {BITS{1'bz}} : io_data_out;
    assign io_address = io_address_source ? current_instruction[BITS * 2 - 1:BITS] : registers[current_instruction[15:8]] + current_instruction[31:16];
    assign io_wr = !stage | io_wr_set;

    assign condition_temp = condition_flags & {c, z, alu_out[15]};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    always @(posedge clk) begin
        if (reset == 0) begin
            in_interrupt <= 0;
        end
        else if (start == 1 && rd == 0) begin
            current_instruction <= int_start == 0 ? data : 'h00010020; // call 1
            if (int_start == 1)
                in_interrupt <= 1;
        end

        if (reset == 0) begin
            sp <= 0;
            address <= 0;
        end
        if (stage == 0) begin
            hlt <= hltf;
            error <= errorf;
            if (address_load == 0)
                address <= address + 1;
            else if (condition_pass == 1) begin
                if (pop) begin
                    address <= stack[sp];
                    sp <= sp + 1;
                end
                else begin
                    if (push) begin
                        stack[sp - 1] <= address;
                        sp <= sp - 1;
                    end
                    address <= address_source ? current_instruction[BITS * 2 - 1:BITS] : registers[current_instruction[15:8]] + current_instruction[31:16];
                end
            end
        end

        if (set_result)
            registers[current_instruction[15:8]] <= alu_out;
        if (set_result2)
            registers[current_instruction[23:16]] <= alu_out2;

        if (hltf | hlt | error || !start)
            stage <= 1;
        else
            stage <= stage + 1;
    end

    alu #(.BITS(BITS))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));
    
endmodule
