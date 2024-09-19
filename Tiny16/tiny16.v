`include "alu.vh"

/*

stage/instruction|halt,nop,br,jmp_reg,jmp_addr12|jmp_preg            |jmp_addr12 |mvil,mvih,movrr  |movrm               |movmr               |adi8       |jmp
0                |fetch                         |fetch               |fetch      |fetch            |fetch               |fetch               |fetch      |fetch      |
1                |                              |pre_dec             |           |                 |pre_dec             |pre_dec             |           |set_address|
2                |                              |load                |           |                 |load                |                    |set_alu_ops|fetch2     |
3                |                              |                    |           |                 |                    |                    |alu_clk    |           |
4                |                              |                    |           |modify           |modify              |store               |store      |           |
5                |set new PC                    |set new PC          |set new PC |set new PC       |set new PC          |set new PC          |set new PC |set new PC |
6                |set_address                   |post inc,set_address|set_address|set_address      |post_inc,set_address|post_inc,set_address|set_address|set_address|

stage/instruction|alu_r_immediate   |alu_r_r    |alu_r_m         |
0                |fetch             |fetch      |fetch           |
1                |set_address       |           |pre_dec         |
2                |fetch2,set_alu_ops|set_alu_ops|load,set_alu_ops|
3                |alu_clk           |alu_clk    |alu_clk         |
4                |store             |store      |store           |
5                |set new PC        |set new PC |set new PC      |
6                |set_address       |set_address|set_address     |

*/

module tiny16
#(parameter STAGE_WIDTH = 8)
(
    input wire clk,
    input wire reset,
    output reg hlt,
    output reg error,
    output reg [15:0] address,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output wire rd,
    output wire wr,
    input wire ready,
    output reg [STAGE_WIDTH - 1:0] stage
);
    // register names
    localparam SP = 14;
    localparam PC = 15;

    localparam NOP = 1;

    reg [15:0] current_instruction, instruction_parameter;
    reg start = 0;

    reg [15:0] registers [0:15];
    reg [15:0] registers_data_wr, source_reg_data, dest_reg_data;
    reg [15:0] pc_data;
    reg [3:0] registers_address_wr;
    reg registers_wr;

    wire [15:0] opcode0, value8_to_16, value12_to_16, value6_to_16, value4_to_16;
    wire [7:0] value8;
    wire [5:0] value6;
    wire [3:0] value4;
    wire [1:0] value2;
    wire [11:0] value12;
    wire [3:0] opcode;
    wire [3:0] source_reg;
    wire [3:0] dest_reg;
    wire post_inc, pre_dec;
    wire halt, err, nop, br, jmp_reg, jmp_preg, jmp_addr12, mvil, mvih, movrm, movmr, movrr, adi8, jmp;
    wire load, store, modify1;
    wire n, c, z;
    wire go;
    wire clk1, clk4, clk5;

    wire [15:0] alu_out;
    reg [4:0] alu_op_id;
    wire alu_clk;
    reg [15:0] alu_op1, alu_op2;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    alu #(.BITS(16))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .c(c), .z(z), .out(alu_out));

    assign n = alu_out[15];

    assign opcode0 = current_instruction[15:0];
    assign opcode = current_instruction[15:12];
    assign condition = opcode[2:0];
    assign condition_neg = opcode[3];
    assign value8 = current_instruction[11:4];
    assign value2 = current_instruction[11:10];
    assign value4 = {current_instruction[11:10], current_instruction[5:4]};
    assign value6 = current_instruction[11:6];
    assign value12 = current_instruction[11:0];
    assign source_reg = current_instruction[3:0];
    assign dest_reg = current_instruction[9:6];
    assign post_inc = current_instruction[5];
    assign pre_dec = current_instruction[4];

    assign halt = opcode0 == 0;
    assign nop = opcode0 == NOP;
    // format |4'h1|offset,8bit|condition,4bit|
    assign br = opcode == 1;
    // format |4'h2|offset,8bit|reg,4bit|
    assign jmp_reg = opcode == 2;
    // format |4'h3|offset,6bit|post_inc|pre_dec|reg,4bit|
    assign jmp_preg = opcode == 3;
    // format |4'h4|offset,12bit|
    assign jmp_addr12 = opcode == 4;
    // format |4'h5|adr_hi,12bit|
    //        |addr_lo,16bit|
    assign jmp = opcode == 5;
    // format |4'h6|data,8bit|reg,4bit|
    assign mvil = opcode == 6;
    // format |4'h7|data,8bit|reg,4bit|
    assign mvih = opcode == 7;
    // format |4'h8|offset,2bit|dst,4bit|post_inc|pre_dec|src,4bit|
    assign movrm = opcode == 8;
    // format |4'h9|offset,2bit|dst,4bit|post_inc|pre_dec|src,4bit|
    assign movmr = opcode == 9;
    // format |4'hA|adder,2bit|dst,4bit|adder,2bit|src,4bit|
    assign movrr = opcode == 10;
    // format |4'hB|value,8bit|reg,4bit|
    assign adi8 = opcode == 11;

    assign err = !halt & !nop & !br & !jmp_reg & !jmp_preg & !jmp_addr12 & !mvil &!mvih & !movrm & !movmr & !movrr & !adi8 & !jmp;
    
    assign load = movrm | jmp_preg;
    assign store = movmr;
    assign modify1 = movrr | mvih | mvil | movrm;

    assign clk1 = stage[0];
    assign clk4 = stage[3];
    assign clk5 = stage[4];
    
    assign rd = !start | !clk1 | !(load & clk4);
    assign wr = !start | !(store & clk4);

    assign alu_clk = adi8 & clk5;

    assign go = start & ready & !error;

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign value4_to_16 = {value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4};
    assign value6_to_16 = {value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6};
    assign value8_to_16 = {value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8};
    assign value12_to_16 = {value12[11], value12[11], value12[11], value12[11], value12};

    always @(posedge stage[STAGE_WIDTH - 1]) begin
        start <= reset;
    end

    always @(negedge clk) begin
        if (error != 0)
            stage <= 1;
        else if (ready == 1)
            stage <= {stage[STAGE_WIDTH - 2:0], stage[STAGE_WIDTH - 1]};
    end

    always @(negedge clk) begin
        if (registers_wr == 0)
            registers[registers_address_wr] <= registers_data_wr;
        pc_data <= registers[PC];
        source_reg_data <= registers[source_reg];
        dest_reg_data <= registers[dest_reg];
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            address <= 0;
            registers_wr <= 0;
            registers_address_wr <= PC;
            registers_data_wr <= 0;
            current_instruction <= NOP;
        end
        else if (go) begin
            case (stage)
                // fetch
                1: current_instruction <= data_in;
                // pre_dec,set_address
                2:  begin
                    hlt <= halt | err;
                    error <= err;

                    if (pre_dec & (movrm | jmp_preg | movmr)) begin
                        registers_data_wr <= movmr ? dest_reg_data - 1 : source_reg_data - 1;
                        registers_address_wr <= movmr ? dest_reg : source_reg;
                        registers_wr <= 0;
                    end
                end
                // load,set_alu_ops,fetch2
                4: begin
                    if (jmp_preg & condition_pass)
                        address <= source_reg_data + value6_to_16;
                    else if (movrm)
                        address <= source_reg_data + {14'h0, value2};
                    else if (movmr) begin
                        address <= dest_reg_data + {14'h0, value2};
                        data_out <= source_reg_data;
                    end
                    else if (adi8) begin
                        alu_op1 <= source_reg_data;
                        alu_op2 <= value8_to_16;
                        alu_op_id <= `ALU_OP_ADD;
                    end
                end
                8: begin
                    if (modify1) begin
                        registers_wr <= 0;
                        registers_address_wr <= mvih | mvil ? source_reg : dest_reg;
                        if (movrr)
                            registers_data_wr <= source_reg_data + value4_to_16;
                        else if (mvih)
                            registers_data_wr <= (source_reg_data & 16'h00FF) | {value8, 8'h0};
                        else if (mvil)
                            registers_data_wr <= (source_reg_data & 16'hFF00) | {8'h0, value8};
                        else if (movrm)
                            registers_data_wr <= data_in;
                    end
                end
                //alu_clk
                16: begin
                    registers_wr <= 1;
                end
                //store,modify
                32: begin
                    if (adi8) begin
                        registers_wr <= 0;
                        registers_address_wr <= source_reg;
                        registers_data_wr <= alu_out;
                    end
                end
                // set new pc
                64: begin
                    registers_address_wr <= PC;
                    registers_wr <= 0;
                    if (br)
                        registers_data_wr <= pc_data + (condition_pass ? value8_to_16 : 1);
                    else if (jmp_addr12)
                        registers_data_wr <= pc_data + (condition_pass ? value12_to_16 : 1);
                    else if (jmp_reg)
                        registers_data_wr <= condition_pass ? source_reg_data + value8_to_16 : 1;
                    else if (jmp_preg)
                        registers_data_wr <= condition_pass ? data_in : 1;
                    else
                        registers_data_wr <= pc_data + 1;
                end
                //post_inc, set_address
                128: begin
                    if (post_inc & (movrm | jmp_preg | movmr)) begin
                        registers_wr <= 0;
                        registers_address_wr <= movmr ? dest_reg : source_reg;
                        registers_data_wr <= movmr ? dest_reg_data + 1 : source_reg_data + 1;
                    end
                    address <= pc_data;
                end
            endcase
        end
    end
endmodule
