`include "alu.vh"

/*

Clock diagramm

reset clk rd start stage comment
0     0   1  0     1
0     1   1  0     1
1     0   0  1     1     instruction read start

instruction without io
reset clk rd start stage alu_clk io_rd io_wr comment
1     1   0  1     0     0       1     1     instruction read, stage reset
1     0   1  1     0     0       1     1     microcode read, registers read
1     1   1  1     1     0       1     1     next address set, may be alu clk
1     0   0  1     1     0       1     1     instruction read start, microcode read, may be registers write

instruction with io read
reset clk rd start stage alu_clk io_rd io_wr comment
1     1   0  1     0     0       1     1     instruction read, stage reset
1     0   1  1     0     0       1     1     microcode read, registers read
1     1   1  1     1     0       1     1     next address set, io address set
1     0   1  1     1     0       0     1     microcode read, io read begin
1     1   1  1     2     0       0     1     io read, may be alu clk, may be registers write
1     0   0  1     2     0       1     1     instruction read start, microcode read

instruction with io write
reset clk rd start stage alu_clk io_rd io_wr io_data_direction comment
1     1   0  1     0     0       1     1     1                 instruction read, stage reset
1     0   1  1     0     0       1     1     1                 microcode read, registers read
1     1   1  1     1     0       1     1     0                 next address set, io address set, may be alu clk
1     0   1  1     1     0       1     0     0                 microcode read, io write begin
1     1   1  1     2     0       1     0     0                 io write
1     0   0  1     2     0       1     1     0                 instruction read start, microcode read

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
    output reg hlt = 0,
    // error flag
    output reg error = 0,
    // IO interface
    output wire io_rd,
    output wire io_wr,
    output wire [BITS - 1:0] io_address,
    inout wire [BITS - 1:0] io_data,
    // stage
    output reg [1:0] stage
);
    parameter MICROCODE_WIDTH = 20;

    wire stage_reset;

    reg [STACK_BITS - 1:0] sp;
    wire push, pop;
    reg stack_wr;
    wire [BITS-1:0] stack_data;
    reg [BITS-1:0] prev_address;

    //ALU related
    wire c, z;
    wire [BITS-1:0] alu_op1, alu_op2, alu_op3, alu_out, alu_out2, io_data_out;
    wire [`ALU_OPID_WIDTH - 1:0] alu_op_id;
    wire alu_clk, alu_clk_set;
    wire alu_op1_source;
    wire [1:0] alu_op2_source;

    // IO
    wire io_data_direction, io_data_direction_set;
    wire io_data_out_source;
    wire io_address_source;
    wire io_wr_set, io_rd_set;

    // address
    wire address_source, address_load, address_set;

    reg [BITS * 2 - 1:0] current_instruction = 0;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:1023];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction;

    // interrupt
    reg in_interrupt;
    wire int_start;

    // error flags
    wire hltf, errorf;

    wire condition_neg, condition_pass;
    wire [2:0] condition_temp, condition_flags;

    wire [BITS - 1:0] registers_data1, registers_data2, registers_data3, registers_wr_data1;
    wire registers_wr1, registers_wr2;

    reg start;

    // can be registers[current_instruction[31:24] or current_instruction[31:16] or io_data
    function [15:0] alu_op2_f(input [1:0] source);
        case (source)
            0: alu_op2_f = registers_data3;
            1: alu_op2_f = current_instruction[31:16];
            default: alu_op2_f = io_data;
        endcase
    endfunction

    register_files #(.WIDTH(BITS), .SIZE(8))
        registers(.clk(!clk), .rd_address1(current_instruction[15:8]), .rd_data1(registers_data1),
                  .rd_address2(current_instruction[23:16]), .rd_data2(registers_data2),
		          .rd_address3(current_instruction[31:24]), .rd_data3(registers_data3),
                  .wr_address1(current_instruction[14:8]), .wr_data1(registers_wr_data1), .wr1(registers_wr1),
                  .wr_address2(current_instruction[22:16]), .wr_data2(alu_out2), .wr2(registers_wr2));

    register_file #(.WIDTH(BITS), .SIZE(STACK_BITS))
        stack(.clk(!clk), .rd_address(sp), .rd_data(stack_data),
                  .wr_address(sp), .wr_data(prev_address), .wr(stack_wr));

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    always @(negedge clk) begin
        current_microinstruction <= microcode[{current_instruction[7:0], stage}];
        start <= reset;
    end

    assign int_start = interrupt == 1 && in_interrupt == 0;

    assign rd = !start | (clk ^ !(stage[0] | stage[1]));

    // in reset state:
    // io_rd = io_wr = 1
    // io_data_direction = 1
    // stage_reset = 1
    assign stage_reset = current_microinstruction[0];
    assign io_rd_set = current_microinstruction[1];
    assign io_wr_set = current_microinstruction[2];
    assign io_data_direction_set = current_microinstruction[3];
    assign address_set = current_microinstruction[4];
    assign address_load = current_microinstruction[5];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign address_source = current_microinstruction[6];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign io_address_source = current_microinstruction[7];
    assign io_data_out_source = current_microinstruction[8];
    assign alu_clk_set = current_microinstruction[9];
    assign condition_neg = current_microinstruction[10];
    assign condition_flags = current_microinstruction[13:11];
    // can be registers[current_instruction[15:8]] or registers[current_instruction[23:16]]
    assign alu_op1_source = current_microinstruction[10];
    // can be registers[current_instruction[31:24]] or current_instruction[31:16] or io_data
    assign alu_op2_source = current_microinstruction[12:11];
    // can be alu_out or registers[current_instruction[15:8]]
    assign hltf = current_microinstruction[14];
    assign errorf = current_microinstruction[15];
    assign push = current_microinstruction[16];
    assign pop = current_microinstruction[17];
    assign registers_wr1 = current_microinstruction[18];
    assign registers_wr2 = current_microinstruction[19];

    assign alu_clk = (alu_clk_set == 1) && (stage == 1);
    assign alu_op_id = current_instruction[`ALU_OPID_WIDTH - 1:0];
    assign alu_op1 = alu_op1_source ? registers_data1 : registers_data2;
    assign alu_op2 = alu_op2_f(alu_op2_source);
    assign alu_op3 = registers_data1;
    
    assign io_data_out = io_data_out_source ? alu_out : registers_data1;
    assign io_data = io_data_direction ? {BITS{1'bz}} : io_data_out;
    assign io_address = io_address_source ? current_instruction[BITS * 2 - 1:BITS] : registers_data1 + current_instruction[BITS * 2 - 1:BITS];
    assign io_wr = (start == 0) || (stage != 1) || (io_wr_set == 1);
    assign io_rd = !start | io_rd_set;
    assign io_data_direction = !start | io_data_direction_set;

    assign condition_temp = condition_flags & {c, z, alu_out[15]};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    always @(posedge clk) begin
        if (reset == 0) begin
            in_interrupt <= 0;
            sp <= 0;
            address <= 0;
            stack_wr <= 1;
        end
        else if (start == 1 && error = 0) begin
            if (rd == 0) begin
                current_instruction <= int_start == 0 ? data : 'h00010020; // call 1
                if (int_start == 1)
                    in_interrupt <= 1;
            end

            hlt <= hltf;
            error <= errorf;
            if (address_set) begin
                if ((address_load == 0) || (condition_pass == 0))
                    address <= address + 1;
                else begin
                    if (pop) begin
                        address <= stack_data;
                        sp <= sp + 1;
                    end
                    else begin
                        if (push) begin
                            prev_address <= address + 1;
                            sp <= sp - 1;
                        end
                        stack_wr <= !push;
                        address <= address_source ? current_instruction[BITS * 2 - 1:BITS] : registers_data1 + current_instruction[31:16];
                    end
                end
            end
            else
                stack_wr <= 1;
        end

        if (!start)
            stage <= 3;
        else if (hltf | hlt | error | stage_reset)
            stage <= 0;
        else
            stage <= stage + 1;
    end

    alu #(.BITS(BITS))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));
    
endmodule
