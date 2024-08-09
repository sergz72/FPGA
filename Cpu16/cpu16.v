`include "alu.vh"

/*

Clock diagramm

reset clk rd start stage comment
0     0   1  0     1
0     1   1  0     1
1     0   0  1     1     instruction read start

instruction without io
clk rd stage alu_clk io_rd io_wr comment
1   0  0     0       1     1     instruction read
0   1  0     0       1     1     microcode read, registers read
1   1  1     0       1     1     next address set, may be alu clk
0   0  1     0       1     1     instruction read start, microcode read, may be registers write

instruction wit io read
clk rd stage alu_clk io_rd io_wr comment
1   0  0     0       1     1     instruction read
0   1  0     0       1     1     microcode read, registers read, io address set
1   1  1     0       0     1     next address set, io read start
0   1  1     0       0     1     microcode read, io read
1   1  2     0       1     1     may be alu clk
0   0  2     0       1     1     instruction read start, microcode read, may be registers write

instruction with io write
clk rd stage alu_clk io_rd io_wr io_data_direction comment
1   0  0     0       1     1     1                 instruction read
0   1  0     0       1     1     1                 microcode read, registers read, io address set
1   1  1     0       1     1     0                 next address set, may be alu clk
0   1  1     0       1     0     0                 microcode read, may be registers write, io write start
1   1  2     0       1     0     0                 io write
0   0  2     0       1     1     0                 instruction read start, microcode read

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
    parameter MICROCODE_WIDTH = 22;

    wire main_clk;

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
    reg io_data_direction;
    wire io_data_direction_set;
    wire io_data_out_source;
    wire io_address_source;

    // address
    wire address_source, address_load, address_set;

    reg [BITS * 2 - 1:0] current_instruction = 0;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:1023];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction;

    // interrupt
    reg in_interrupt;
    wire int_start, in_interrupt_clear;

    // error flags
    wire hltf, errorf;

    wire condition_neg, condition_pass;
    wire [2:0] condition_temp, condition_flags;

    wire [BITS - 1:0] registers_data1, registers_data2, registers_data3, registers_wr_data;
    wire registers_wr, regs_clk, registers_wr_dest;
    wire [7:0] registers_wr_address;
    wire [2:0] registers_wr_source;

    reg start;
    
    // can be registers[current_instruction[31:24] or current_instruction[31:16] or io_data
    function [15:0] alu_op2_f(input [1:0] source);
        case (source)
            0: alu_op2_f = registers_data3;
            1: alu_op2_f = current_instruction[31:16];
            default: alu_op2_f = io_data;
        endcase
    endfunction

    function [15:0] registers_wr_source_f(input [2:0] source);
        case (source)
            0: registers_wr_source_f = alu_out;
            1: registers_wr_source_f = alu_out2;
            2: registers_wr_source_f = current_instruction[BITS * 2 - 1:BITS]; // immediate
            3: registers_wr_source_f = registers_data1;
            4: registers_wr_source_f = registers_data2 + {{8{1'b0}}, current_instruction[BITS * 2 - 1: 24]};
            5: registers_wr_source_f = registers_data3;
            6: registers_wr_source_f = {14'h0, c, z};
            default: registers_wr_source_f = io_data;
        endcase
    endfunction

    assign regs_clk = clk | hlt; // clock is stopped when hlt is 1
    assign main_clk = clk | error; // clock is stopped when error is 1

    register_file3 #(.WIDTH(BITS), .SIZE(8))
        registers(.clk(!regs_clk), .rd_address1(current_instruction[15:8]), .rd_data1(registers_data1),
                  .rd_address2(current_instruction[23:16]), .rd_data2(registers_data2),
		          .rd_address3(current_instruction[31:24]), .rd_data3(registers_data3),
                  .wr_address(registers_wr_address), .wr_data(registers_wr_data), .wr(registers_wr));

    register_file #(.WIDTH(BITS), .SIZE(STACK_BITS))
        stack(.clk(!regs_clk), .rd_address(sp), .rd_data(stack_data),
                  .wr_address(sp), .wr_data(prev_address), .wr(stack_wr));

    alu #(.BITS(BITS))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    assign int_start = interrupt == 1 && in_interrupt == 0;

    assign rd = !start | (clk ^ !(stage[0] | stage[1]));

    // in reset state:
    // io_rd = io_wr = 1
    // io_data_direction = 1
    // stage_reset = 1
    assign stage_reset = current_microinstruction[0];
    assign io_rd = current_microinstruction[1];
    assign io_wr = current_microinstruction[2];
    assign io_data_direction_set = current_microinstruction[3];
    assign address_load = current_microinstruction[4];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign address_source = current_microinstruction[5];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign io_address_source = current_microinstruction[6];
    assign io_data_out_source = current_microinstruction[7];
    assign alu_clk_set = current_microinstruction[8];
    assign condition_neg = current_microinstruction[9];
    assign condition_flags = current_microinstruction[12:10];
    // can be registers[current_instruction[15:8]] or registers[current_instruction[23:16]]
    assign alu_op1_source = current_microinstruction[9];
    // can be registers[current_instruction[31:24]] or current_instruction[31:16] or io_data
    assign alu_op2_source = current_microinstruction[11:10];
    // can be alu_out or registers[current_instruction[15:8]]
    assign hltf = current_microinstruction[13];
    assign errorf = current_microinstruction[14];
    assign push = current_microinstruction[15];
    assign in_interrupt_clear = current_microinstruction[15];
    assign pop = current_microinstruction[16];
    assign registers_wr = current_microinstruction[17];
    assign registers_wr_dest = current_microinstruction[18];
    assign registers_wr_source = current_microinstruction[21:19];

    assign registers_wr_address = registers_wr_dest ? current_instruction[23:16] : current_instruction[15:8];
    assign registers_wr_data = registers_wr_source_f(registers_wr_source);

    assign alu_clk = (alu_clk_set == 1) && (clk == 1);
    assign alu_op_id = current_instruction[`ALU_OPID_WIDTH - 1:0];
    assign alu_op1 = alu_op1_source ? registers_data1 : registers_data2;
    assign alu_op2 = alu_op2_f(alu_op2_source);
    assign alu_op3 = registers_data1;
    
    assign io_data_out = io_data_out_source ? alu_out : registers_data1;
    assign io_data = io_data_direction ? {BITS{1'bz}} : io_data_out;
    assign io_address = io_address_source ? registers_data2 + {{8{1'b0}}, current_instruction[BITS * 2 - 1: 24]} : registers_data3;

    assign condition_temp = condition_flags & {c, z, alu_out[15]};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign address_set = stage == 1;

    always @(negedge main_clk) begin
        current_microinstruction <= microcode[{current_instruction[7:0], stage}];
        start <= reset;
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            in_interrupt <= 0;
            sp <= 0;
            address <= 0;
            hlt <= 0;
            error <= 0;
            stack_wr <= 1;
            current_instruction <= 0;
        end
        else if (start == 1 && error == 0) begin
            io_data_direction <= io_data_direction_set;
            if (rd == 0) begin
                if (int_start == 0)
                    current_instruction <= data;
                else begin
                    current_instruction <= 'h00010020; // call 1
                    in_interrupt <= 1;
                    address <= address - 1;
                end
            end
            else begin
                hlt <= hltf;
                error <= errorf;
                if (address_set) begin
                    if ((address_load == 0) || (condition_pass == 0))
                        address <= address + 1;
                    else begin
                        if (pop) begin
                            address <= stack_data;
                            sp <= sp + 1;
                            if (in_interrupt_clear)
                                in_interrupt <= 0;
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
        end

        if (!start)
            stage <= 3;
        else if (hltf | hlt | error | stage_reset)
            stage <= 0;
        else
            stage <= stage + 1;
    end

endmodule
