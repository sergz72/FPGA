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
    output reg [2:0] stage
);
    localparam MICROCODE_WIDTH = 28;
    localparam SP = 15;
    localparam NOP = {9'h1, 7'h0};

    reg [15:0] current_instruction, instruction_parameter;
    reg start = 0;
    reg stage_reset = 0;

    reg [15:0] pc;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:1023];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 7;

    reg [15:0] registers [0:15];
    reg [15:0] registers_data_wr, source_reg_data, dest_reg_data, sp_data;
    reg [3:0] registers_address_wr;
    reg registers_wr;

    wire [15:0] value8_to_16, value7_to_16, value6_to_16, value11_to_16, value4_to_16, alu_op_adder_to_16;
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

    wire halt, err;
    wire fetch, fetch2, alu_op1_source, stage_reset_no_mul, stage_reset_mul, set_pc;
    wire alu_op_id_source, alu_clk;
    wire registers_wr_f;
    wire [1:0] registers_wr_address_source, data_out_source, alu_op2_source, address_source;
    wire [2:0] pc_source;
    wire [3:0] registers_wr_data_source;
    wire mul;

    alu #(.BITS(16))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    assign n = alu_out[15];

    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];
    assign value8 = current_instruction[11:4];
    assign value7 = current_instruction[10:4];
    assign value2 = current_instruction[11:10];
    assign value4 = {current_instruction[11:10], current_instruction[5:4]};
    assign value6 = current_instruction[11:6];
    assign value11 = current_instruction[10:0];
    assign source_reg = current_instruction[3:0];
    assign dest_reg = current_instruction[9:6];
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

    assign value4_to_16 = {value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4};
    assign value6_to_16 = {value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6};
    assign value7_to_16 = {value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7};
    assign value8_to_16 = {value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8};
    assign value11_to_16 = {value11[10], value11[10], value11[10], value11[10], value11[10], value11};
    assign alu_op_adder_to_16 = {alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder};

    assign registers_wr_f = current_microinstruction[0];
    assign rd = current_microinstruction[1];
    assign wr = current_microinstruction[2];

    assign halt = current_microinstruction[3];
    assign err = current_microinstruction[4];            

    assign fetch = current_microinstruction[5];
    assign fetch2 = current_microinstruction[6];
    assign set_pc = current_microinstruction[7];

    assign pc_source = current_microinstruction[10:8];
    assign address_source = current_microinstruction[12:11];

    assign data_out_source = current_microinstruction[14:13];

    assign registers_wr_data_source = current_microinstruction[18:15];
    assign registers_wr_address_source = current_microinstruction[20:19];

    assign stage_reset_no_mul = current_microinstruction[21];
    assign stage_reset_mul = current_microinstruction[22];

    assign alu_op1_source = current_microinstruction[23];
    assign alu_op2_source = current_microinstruction[25:24];
    assign alu_op_id_source = current_microinstruction[26];
    assign alu_clk = current_microinstruction[27];
    assign mul = alu_op_id == `ALU_OP_MUL;
    
    function [15:0] pc_source_f(input [2:0] source);
        case (source)
            0: pc_source_f = pc + 2;
            1: pc_source_f = pc + (condition_pass ? value8_to_16 : 1);
            2: pc_source_f = pc + value11_to_16;
            3: pc_source_f = source_reg_data + value7_to_16;
            4: pc_source_f = condition_pass ? instruction_parameter : pc + 1;
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

    function [15:0] alu_op2_f(input [1:0] source);
        case (source)
            0: alu_op2_f = value8_to_16;
            1: alu_op2_f = 16'hFFFF;
            2: alu_op2_f = source_reg_data;
            3: alu_op2_f = data_in + alu_op_adder_to_16;
        endcase
    endfunction

    always @(negedge clk) begin
        if (error | stage_reset)
            stage = 0;
        else begin
            if (reset == 0)
                start <= 0;
            else if (stage == 7)
                start <= 1;
            if (ready == 1)
                stage = stage + 1;
        end
        if (!error && !hlt)
            current_microinstruction <= microcode[{current_instruction[15:10], condition_pass, stage}];
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
            pc <= 0;
            hlt <= 0;
            error <= 0;
            current_instruction <= NOP;
        end
        else if (go) begin
            hlt <= halt | err;
            error <= err;
            if (fetch)
                current_instruction <= data_in;
            if (fetch2)
                instruction_parameter <= data_in;
            if (set_pc)
                pc <= pc_source_f(pc_source);
            registers_wr <= registers_wr_f;
            registers_address_wr <= registers_address_wr_f(registers_wr_address_source);
            registers_data_wr = registers_data_wr_f(registers_wr_data_source);
            stage_reset <= (mul & stage_reset_mul) | (!mul & stage_reset_no_mul);
        end
    end
endmodule
