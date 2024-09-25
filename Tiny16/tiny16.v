`include "alu.vh"

module tiny16
(
    input wire clk,
    input wire reset,
    output reg hlt = 0,
    output reg error = 0,
    output wire [15:0] address,
    input wire [15:0] data_in,
    output wire [15:0] data_out,
    output wire rd,
    output wire wr,
    input wire ready,
    input wire interrupt,
    output reg [2:0] stage = 0
);
    localparam MICROCODE_WIDTH = 28;
    localparam SP = 15;
    localparam NOP = {6'h1, 10'h0};
    localparam INT = 6'h13;

    reg [15:0] current_instruction, instruction_parameter;
    reg start = 0;
    wire stage_reset;

    reg in_interrupt = 0;
    wire in_interrupt_clear;

    reg [15:0] pc;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:1023];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 7;

    reg [15:0] registers [0:15];
    wire [15:0] registers_data_wr;
    reg [15:0] source_reg_data, dest_reg_data, sp_data;
    wire [3:0] registers_address_wr;
    wire registers_wr, registers_wr_others, registers_wr_alu;

    wire [15:0] value8_to_16, value7_to_16, value6_to_16, value11_to_16, value4_to_16, alu_op_adder_to_16;
    wire [9:0] value10;
    wire [7:0] value8;
    wire [6:0] value7;
    wire [5:0] value6;
    wire [3:0] value4;
    wire [1:0] value2;
    wire [10:0] value11;

    wire [3:0] source_reg;
    wire [3:0] dest_reg;
    wire go;
    wire n, c, z;

    wire [15:0] alu_out, alu_out2;
    wire [10:0] alu_op_adder;
    wire [4:0] alu_op_id;
    wire [15:0] alu_op1, alu_op2, alu_op3;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;
    wire [2:0] condition_in, condition_temp_in;
    wire condition_neg_in, condition_pass_in;

    wire halt, err;
    wire load, fetch2, alu_op1_source, alu_op2_source, stage_reset_no_mul, stage_reset_mul, set_pc;
    wire alu_op_id_source, alu_clk;
    wire [1:0] registers_wr_address_source, data_out_source, address_source;
    wire [2:0] pc_source;
    wire [3:0] registers_wr_data_source;
    wire mul;

    alu #(.BITS(16))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    assign n = alu_out[15];

    assign source_reg = current_instruction[3:0];
    assign dest_reg = current_instruction[7:4];

    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];
    assign condition_in = data_in[2:0];
    assign condition_neg_in = data_in[3];

    assign value10 = current_instruction[9:0];
    assign value8 = current_instruction[11:4];
    assign value7 = current_instruction[10:4];
    assign value2 = current_instruction[11:10];
    assign value4 = {current_instruction[11:10], current_instruction[5:4]};
    assign value6 = current_instruction[11:6];
    assign value11 = current_instruction[10:0];
    assign alu_op_adder = instruction_parameter[15:5];

    assign alu_op_id = alu_op_id_source ? instruction_parameter[4:0] : {current_instruction[12:10], current_instruction[5:4]};
    
    assign address = address_source_f(address_source);
    
    assign data_out = data_out_f(data_out_source);

    assign alu_op1 = alu_op1_f(alu_op1_source);
    assign alu_op2 = alu_op2_f(alu_op2_source);
    assign alu_op3 = 0;

    assign go = start & ready & !error & !hlt;

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;
    assign condition_temp_in = condition_in & {c, z, n};
    assign condition_pass_in = (condition_temp_in[0] | condition_temp_in[1] | condition_temp_in[2]) ^ condition_neg_in;

    assign value4_to_16 = {value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4};
    assign value6_to_16 = {value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6};
    assign value7_to_16 = {value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7};
    assign value8_to_16 = {value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8};
    assign value11_to_16 = {value11[10], value11[10], value11[10], value11[10], value11[10], value11};
    assign alu_op_adder_to_16 = {alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder};

    assign registers_wr_others = current_microinstruction[0];
    assign load = current_microinstruction[1];
    assign wr = current_microinstruction[2];

    assign halt = current_microinstruction[3];
    assign err = current_microinstruction[4];            

    assign fetch2 = current_microinstruction[5];
    assign set_pc = current_microinstruction[6];

    assign pc_source = current_microinstruction[9:7];
    assign address_source = current_microinstruction[11:10];

    assign data_out_source = current_microinstruction[13:12];

    assign registers_wr_data_source = current_microinstruction[17:14];
    assign registers_wr_address_source = current_microinstruction[19:18];

    assign stage_reset_no_mul = current_microinstruction[20];
    assign stage_reset_mul = current_microinstruction[21];

    assign alu_op1_source = current_microinstruction[22];
    assign alu_op2_source = current_microinstruction[23];
    assign alu_op_id_source = current_microinstruction[24];
    assign alu_clk = current_microinstruction[25];
    assign registers_wr_alu = current_microinstruction[26];
    assign mul = alu_op_id == `ALU_OP_MUL;

    assign in_interrupt_clear = current_microinstruction[27];
    
    assign rd = (!start | error | hlt) | ((stage != 0) && !load && !fetch2);

    assign registers_address_wr = registers_address_wr_f(registers_wr_address_source);
    assign registers_data_wr = registers_data_wr_f(registers_wr_data_source);
    assign registers_wr = registers_wr_others && (registers_wr_alu || (alu_op_id == `ALU_OP_TEST || alu_op_id == `ALU_OP_CMP || alu_op_id == `ALU_OP_SETF));
    assign stage_reset = (mul & stage_reset_mul) | (!mul & stage_reset_no_mul);

    function [15:0] pc_source_f(input [2:0] source);
        case (source)
            0: pc_source_f = pc + 2;
            1: pc_source_f = pc + value8_to_16;
            2: pc_source_f = pc + value11_to_16;
            3: pc_source_f = source_reg_data + value7_to_16;
            4: pc_source_f = data_in;
            5: pc_source_f = instruction_parameter;
            6: pc_source_f = {6'h0, value10};
            default: pc_source_f = pc + 1;
        endcase
    endfunction

    function [15:0] address_source_f(input [1:0] source);
        case (source)
            0: address_source_f = pc;
            1: address_source_f = sp_data;
            2: address_source_f = registers_data_wr + {14'h0, value2};
            3: address_source_f = registers_data_wr + value4_to_16;
        endcase
    endfunction

    function [15:0] registers_data_wr_f(input [3:0] source);
        case (source)
            0: registers_data_wr_f = source_reg_data + value4_to_16;
            1: registers_data_wr_f = (source_reg_data & 16'h00FF) | {value8, 8'h0};
            2: registers_data_wr_f = (source_reg_data & 16'hFF00) | {8'h0, value8};
            3: registers_data_wr_f = dest_reg_data - 1;
            4: registers_data_wr_f = source_reg_data - 1;
            5: registers_data_wr_f = sp_data - 1;
            6: registers_data_wr_f = data_in;
            7: registers_data_wr_f = alu_out;
            8: registers_data_wr_f = alu_out2;
            9: registers_data_wr_f = alu_out + alu_op_adder_to_16;
            10: registers_data_wr_f = dest_reg_data + 1;
            11: registers_data_wr_f = sp_data + 1;
            default: registers_data_wr_f = source_reg_data + 1;
        endcase
    endfunction

    function [3:0] registers_address_wr_f(input [1:0] source);
        case (source)
            0: registers_address_wr_f = source_reg;
            1: registers_address_wr_f = dest_reg;
            2: registers_address_wr_f = dest_reg + 1;
            3: registers_address_wr_f = SP;
        endcase
    endfunction

    function [15:0] data_out_f(input [1:0] source);
        case (source)
            0: data_out_f = source_reg_data;
            1: data_out_f = instruction_parameter;
            2: data_out_f = {13'h0, c, z, n};
            3: data_out_f = pc + 1;
        endcase
    endfunction

    function [15:0] alu_op1_f(input source);
        case (source)
            0: alu_op1_f = source_reg_data;
            1: alu_op1_f = dest_reg_data;
        endcase
    endfunction

    function [15:0] alu_op2_f(input source);
        case (source)
            0: alu_op2_f = source_reg_data;
            1: alu_op2_f = data_in + alu_op_adder_to_16;
        endcase
    endfunction

    always @(negedge clk) begin
        if (error | stage_reset)
            stage <= 0;
        else begin
            if (!reset)
                start <= 0;
            else if (stage == 7)
                start <= 1;
            if (ready)
                stage <= stage + 1;
        end
    end

    always @(negedge clk) begin
        if (registers_wr == 0)
            registers[registers_address_wr] <= registers_data_wr;
        sp_data <= registers[SP];
        source_reg_data <= registers[source_reg];
        dest_reg_data <= registers[dest_reg];
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            current_instruction <= NOP;
            in_interrupt <= 0;
        end
        else begin
            if (go) begin
                if (stage == 0) begin
                    if (interrupt & !in_interrupt) begin
                        in_interrupt <= 1;
                        current_instruction <= {INT, 10'h1};
                        current_microinstruction <= microcode[{INT, 4'h0}];
                    end
                    else begin
                        current_instruction <= data_in;
                        current_microinstruction <= microcode[{data_in[15:10], condition_pass_in, 3'h0}];
                    end
                end
                else begin
                    if (in_interrupt_clear)
                        in_interrupt <= 0;
                    current_microinstruction <= microcode[{current_instruction[15:10], condition_pass, stage}];
                end
            end
        end
    end

    always @(negedge clk) begin
        if (reset == 0) begin
            pc <= 0;
            hlt <= 0;
            error <= 0;
        end
        else begin
            if (go) begin
                hlt <= halt | err;
                error <= err;
                if (fetch2)
                    instruction_parameter <= data_in;
                if (set_pc)
                    pc <= pc_source_f(pc_source);
            end
        end
    end
endmodule
