`include "alu.vh"

/*

Clock diagramm

instruction without io and without alu
stage clk1 clk2 clk3 clk4 rd alu_clk io_rd io_wr registers read/write stack read/write comment
0     1    0    0    0    0  0       1     1     1                    1                instruction read start, io_wr = 1, io_data_direction = 1
1     0    1    0    0    1  0       1     1     0                    0                instruction read, registers_wr = 1, io_rd = 1
2     0    0    1    0    1  0       1     1     1                    0                microcode read
3     0    0    0    1    1  0       1     1     0                    0                next address set, registers_wr set

instruction without io with alu
stage clk1 clk2 clk3 clk4 rd alu_clk io_rd io_wr registers read/write stack read/write comment
0     1    0    0    0    0  0       1     1     1                    1                instruction read start, io_wr = 1, io_data_direction = 1
1     0    1    0    0    1  0       1     1     0                    0                instruction read, registers_wr = 1, io_rd = 1
2     0    0    1    0    1  0       1     1     1                    0                microcode read
3     0    0    0    1    1  1       1     1     0                    0                next address set, registers_wr set

instruction with io read and without alu
stage clk1 clk2 clk3 clk4 rd alu_clk io_rd io_wr registers read/write stack read/write comment
0     1    0    0    0    0  0       0     1     1                    1                instruction read start, io_wr = 1, io_data_direction = 1
1     0    1    0    0    1  0       1     1     0                    0                instruction read, registers_wr = 1, io_rd = 1
2     0    0    1    0    1  0       1     1     1                    0                microcode read, io address set
3     0    0    0    1    1  0       0     1     0                    0                next address set, registers_wr set

instruction with io write and without alu
stage clk1 clk2 clk3 clk4 rd alu_clk io_rd io_wr registers read/write stack read/write io_data_direction comment
0     1    0    0    0    0  0       1     1     1                    1                1                 instruction read start, io_wr = 1, io_data_direction = 1
1     0    1    0    0    1  0       1     1     0                    0                1                 instruction read, registers_wr = 1, io_rd = 1
2     0    0    1    0    1  0       1     1     1                    0                0                 microcode read, io address set, io data set
3     0    0    0    1    1  0       1     0     0                    0                0                 next address set, registers_wr set, io write

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
    output reg [1:0] stage = 0
);
    parameter MICROCODE_WIDTH = 21;

    wire clk1, clk2, clk3, clk4;

    reg start = 0;
    
    reg [STACK_BITS - 1:0] sp;
    wire push, pop;
    wire stack_wr;
    wire [BITS-1:0] stack_data;
    reg [BITS-1:0] prev_address;

    //ALU related
    wire c, z;
    wire [BITS-1:0] alu_op1, alu_op2, alu_op3, alu_out, alu_out2, io_data_out;
    wire [`ALU_OPID_WIDTH - 1:0] alu_op_id;
    wire alu_clk, alu_clk_set;
    wire alu_op1_source;
    wire alu_op2_source;

    // IO
    wire io_data_direction;
    wire io_data_out_source;
    wire io_wr_set, io_rd_set;

    // address
    wire address_source, address_load;

    reg [BITS * 2 - 1:0] current_instruction = 0;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:255];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 7;

    // interrupt
    reg in_interrupt;
    wire int_start, in_interrupt_clear;

    // error flags
    wire hltf, errorf;

    wire condition_neg, condition_pass;
    wire [2:0] condition_temp, condition_flags;

    wire [BITS - 1:0] registers_data1, registers_data2, registers_data3, registers_wr_data;
    wire registers_wr_set, regs_clk, registers_wr_dest, registers_wr;
    wire [7:0] registers_wr_address;
    wire [2:0] registers_wr_source;

    // can be registers[current_instruction[31:24] or current_instruction[31:16]
    function [15:0] alu_op2_f(input source);
        case (source)
            0: alu_op2_f = registers_data3;
            default: alu_op2_f = current_instruction[31:16];
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

    register_file3 #(.WIDTH(BITS), .SIZE(8))
        registers(.clk(regs_clk), .rd_address1(current_instruction[15:8]), .rd_data1(registers_data1),
                  .rd_address2(current_instruction[23:16]), .rd_data2(registers_data2),
		          .rd_address3(current_instruction[31:24]), .rd_data3(registers_data3),
                  .wr_address(registers_wr_address), .wr_data(registers_wr_data), .wr(registers_wr));

    register_file #(.WIDTH(BITS), .SIZE(STACK_BITS))
        stack(.clk(clk1), .rd_address(sp), .rd_data(stack_data),
                  .wr_address(sp), .wr_data(prev_address), .wr(stack_wr));

    alu #(.BITS(BITS))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    // instruction read start
    assign clk1 = start && stage[0] == 0 && stage[1] == 0;
    // instruction read
    assign clk2 = start && stage[0] == 1 && stage[1] == 0;
    // microcode read
    assign clk3 = start && stage[0] == 0 && stage[1] == 1;
    // registers read/write
    assign clk4 = start && stage[0] == 1 && stage[1] == 1;

    assign regs_clk = start & !stage[0] & clk;

    assign int_start = interrupt == 1 && in_interrupt == 0;

    assign rd = error || !clk1;

    // in reset state:
    // io_rd = io_wr = 1
    assign io_rd_set = current_microinstruction[0];
    assign io_wr_set = current_microinstruction[1];
    assign address_load = current_microinstruction[2];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign address_source = current_microinstruction[3];
    assign alu_clk_set = current_microinstruction[4];
    assign condition_neg = current_microinstruction[5];
    assign condition_flags = current_microinstruction[8:6];
    // can be registers[current_instruction[15:8]] or registers[current_instruction[23:16]]
    assign alu_op1_source = current_microinstruction[9];
    // can be registers[current_instruction[31:24]] or current_instruction[31:16]
    assign alu_op2_source = current_microinstruction[10];
    assign hltf = current_microinstruction[11];
    assign errorf = current_microinstruction[12];
    assign push = current_microinstruction[13];
    assign in_interrupt_clear = current_microinstruction[14];
    assign pop = current_microinstruction[15];
    assign registers_wr_set = current_microinstruction[16];
    assign registers_wr_dest = current_microinstruction[17];
    assign registers_wr_source = current_microinstruction[20:18];

    assign registers_wr_address = registers_wr_dest ? current_instruction[23:16] : current_instruction[15:8];
    assign registers_wr_data = registers_wr_source_f(registers_wr_source);
    assign registers_wr = !registers_wr_set | !clk1;

    assign alu_clk = (alu_clk_set == 1) && (clk4 == 1);
    assign alu_op_id = current_instruction[`ALU_OPID_WIDTH - 1:0];
    assign alu_op1 = alu_op1_source ? registers_data1 : registers_data2;
    assign alu_op2 = alu_op2_f(alu_op2_source);
    assign alu_op3 = registers_data1;
    
    assign io_data_direction = io_wr_set | clk1 | clk2;
    assign io_data = io_data_direction ? {BITS{1'bz}} : registers_data1;
    assign io_address = registers_data2 + {{8{1'b0}}, current_instruction[BITS * 2 - 1: 24]};
    assign io_rd = io_rd_set | !(clk1 | clk4);
    assign io_wr = io_wr_set | !clk4;

    assign condition_temp = condition_flags & {c, z, alu_out[15]};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign stack_wr = !push;

    always @(negedge clk) begin
        if (error != 0 || hlt != 0)
            stage <= 0;
        else
            stage <= stage + 1;
    end

    always @(posedge clk3) begin
        if (error == 0)
            current_microinstruction <= microcode[current_instruction[7:0]];
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            in_interrupt <= 0;
            sp <= 0;
            address <= 0;
            hlt <= 0;
            error <= 0;
            current_instruction <= 0;
            start <= 0;
        end
        else begin
            if (stage == 0)
                start <= 1;
            else begin
                if (start == 1 && error == 0) begin
                    if (clk2 == 1) begin
                        if (int_start == 0) begin
                            if (hlt == 0)
                                current_instruction <= data;
                        end
                        else begin
                            current_instruction <= 'h00010020; // call 1
                            in_interrupt <= 1;
                            address <= address - 1;
                            hlt <= 0;
                        end
                    end
                    else if (clk4 == 1 && hlt == 0) begin
                        hlt <= hltf;
                        error <= errorf;
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
                                address <= address_source ? current_instruction[BITS * 2 - 1:BITS] : registers_data1 + current_instruction[31:16];
                            end
                        end
                    end
                end
            end
        end
    end

endmodule
