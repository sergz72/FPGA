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
stage clk1 clk2 clk3 clk4 rd alu_clk io_rd io_wr registers read/write stack read/write comment
0     1    0    0    0    0  0       1     1     1                    1                instruction read start, io_wr = 1, io_data_direction = 1
1     0    1    0    0    1  0       1     1     0                    0                instruction read, registers_wr = 1, io_rd = 1
2     0    0    1    0    1  0       1     1     1                    0                microcode read, io address set, io data set
3     0    0    0    1    1  0       1     0     0                    0                next address set, registers_wr set, io write

*/

module cpu
#(parameter BITS = 16)
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
    input wire [BITS - 1:0] io_data_in,
    output wire [BITS - 1:0] io_data_out,
    output reg [1:0] stage = 0
);
    localparam MICROCODE_WIDTH = 27;

    wire clk1, clk2, clk4;

    reg start = 0;
    
    reg [7:0] sp;
    wire push, pop;
    reg [BITS-1:0] prev_address;

    reg [7:0] rp;
    wire [1:0] rp_op;

    //ALU related
    wire c, z;
    wire [BITS-1:0] alu_op1, alu_op2, alu_out;
    wire [`ALU_OPID_WIDTH - 1:0] alu_op_id;
    wire alu_clk, alu_clk_set;
    wire alu_op2_source;

    // IO
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

    wire [BITS - 1:0] registers_data1, registers_data2, registers_wr_data;
    wire registers_wr_set, regs_clk;
    wire [1:0] registers_wr_dest;
    wire [7:0] registers_wr_address;
    wire [2:0] registers_wr_source;
    reg registers_wr = 1;
    wire [7:0] registers_rd_address1, registers_rd_address2;
    wire [1:0] registers_rd_source1, registers_rd_source2;

    function [15:0] registers_wr_source_f(input [2:0] source);
        case (source)
            0: registers_wr_source_f = alu_out;
            1: registers_wr_source_f = current_instruction[BITS * 2 - 1:BITS]; // immediate
            2: registers_wr_source_f = registers_data1 + {{8{1'b0}}, current_instruction[BITS * 2 - 1:24]};
            3: registers_wr_source_f = registers_data1 + current_instruction[BITS * 2 - 1:BITS];
            4: registers_wr_source_f = {13'h0, alu_out[15], c, z};
            5: registers_wr_source_f = prev_address;
            default: registers_wr_source_f = io_data_in;
        endcase
    endfunction

    function [7:0] registers_wr_address_f(input [1:0] source);
        case (source)
            0: registers_wr_address_f = current_instruction[15:8];
            1: registers_wr_address_f = sp;
            2: registers_wr_address_f = rp - 1;
            3: registers_wr_address_f = rp;
        endcase
    endfunction

    function [7:0] registers_rd_source1_f(input [1:0] source);
        case (source)
            0: registers_rd_source1_f = current_instruction[23:16];
            1: registers_rd_source1_f = current_instruction[15:8];
            2: registers_rd_source1_f = sp;
            default: registers_rd_source1_f = rp_op == 3 ? rp - 1: rp;
        endcase
    endfunction

    function [7:0] registers_rd_source2_f(input [1:0] source);
        case (source)
            0: registers_rd_source2_f = current_instruction[31:24];
            1: registers_rd_source2_f = current_instruction[23:16];
            2: registers_rd_source2_f = sp;
            default: registers_rd_source2_f = rp_op == 3 ? rp - 1: rp;
        endcase
    endfunction

    register_file2 #(.WIDTH(BITS), .SIZE(8))
        registers(.clk(regs_clk), .rd_address1(registers_rd_address1), .rd_data1(registers_data1),
                  .rd_address2(registers_rd_address2), .rd_data2(registers_data2),
                  .wr_address(registers_wr_address), .wr_data(registers_wr_data), .wr(registers_wr));

    alu #(.BITS(BITS))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .c(c), .z(z), .out(alu_out));

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    assign registers_rd_address1 = registers_rd_source1_f(registers_rd_source1);
    assign registers_rd_address2 = registers_rd_source2_f(registers_rd_source2);

    // instruction read start
    assign clk1 = start && stage[0] == 0 && stage[1] == 0;
    // instruction read
    assign clk2 = start && stage[0] == 1 && stage[1] == 0;
    // microcode read
//    assign clk3 = start && stage[0] == 0 && stage[1] == 1;
    // registers read/write
    assign clk4 = start && stage[0] == 1 && stage[1] == 1;

    assign regs_clk = !hlt & start & !stage[0];

    assign int_start = interrupt == 1 && in_interrupt == 0;

    assign rd = error || hlt || !clk1;

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
    // can be registers[current_instruction[31:24]] or current_instruction[31:16]
    assign alu_op2_source = current_microinstruction[9];
    assign hltf = current_microinstruction[10];
    assign errorf = current_microinstruction[11];
    assign push = current_microinstruction[12];
    assign in_interrupt_clear = current_microinstruction[13];
    assign pop = current_microinstruction[14];
    assign registers_wr_set = current_microinstruction[15];
    assign registers_wr_dest = current_microinstruction[17:16];
    assign registers_wr_source = current_microinstruction[20:18];
    assign rp_op = current_microinstruction[22:21];
    assign registers_rd_source1 = current_microinstruction[24:23];
    assign registers_rd_source2 = current_microinstruction[26:25];

    assign registers_wr_address = registers_wr_address_f(registers_wr_dest);
    assign registers_wr_data = registers_wr_source_f(registers_wr_source);

    assign alu_clk = (alu_clk_set == 1) && (clk4 == 1);
    assign alu_op_id = current_instruction[`ALU_OPID_WIDTH - 1:0];
    assign alu_op1 = registers_data1;
    assign alu_op2 = alu_op2_source ? current_instruction[31:16] : registers_data2;
    
    assign io_data_out = registers_data1;
    assign io_address = registers_data2 + {{8{1'b0}}, current_instruction[BITS * 2 - 1: 24]};
    assign io_rd = io_rd_set | !(clk1 | clk4);
    assign io_wr = io_wr_set | !clk4;

    assign condition_temp = condition_flags & {c, z, alu_out[15]};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    always @(negedge clk) begin
        if (error != 0)
            stage <= 0;
        else begin
            if (reset == 0)
                start <= 0;
            else if (stage == 3)
                start <= 1;
            stage <= stage + 1;
        end
    end

    always @(posedge clk2) begin
        if (error == 0 && hlt == 0)
            current_microinstruction <= microcode[current_instruction[7:0]];
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            in_interrupt <= 0;
            sp <= 0;
            rp <= 0;
            address <= 0;
            hlt <= 0;
            error <= 0;
            current_instruction <= 0;
        end
        else begin
            if (start == 1 && error == 0) begin
                case (stage)
                    0: begin
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
                    1: registers_wr <= 1;
                    3: begin
                        if (hlt == 0) begin
                            hlt <= hltf;
                            error <= errorf;
                            registers_wr <= !registers_wr_set;
                            if ((address_load == 0) || (condition_pass == 0))
                                address <= address + 1;
                            else begin
                                if (pop) begin
                                    address <= registers_data1;
                                    sp <= sp + 1;
                                    if (in_interrupt_clear)
                                        in_interrupt <= 0;
                                end
                                else begin
                                    if (push) begin
                                        prev_address <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    address <= address_source ? current_instruction[BITS * 2 - 1:BITS] : registers_data1 + current_instruction[BITS * 2 - 1:BITS];
                                end
                            end
                            case (rp_op)
                                1: rp <= current_instruction[31:24];
                                2: rp <= rp + 1;
                                3: rp <= rp - 1;
                            endcase
                        end
                    end
                endcase
            end
        end
    end

endmodule
