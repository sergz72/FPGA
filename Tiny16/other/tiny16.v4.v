`include "alu.vh"

/*

stage/instruction|halt,nop,br,jmp_reg,|jmp_preg            |mvil,mvih, |movrm               |movmr               |adi8       |jmp        |
                 |jmp_addr11          |                    |movrr      |                    |                    |           |           |
0                |fetch               |fetch               |fetch      |fetch               |fetch               |fetch      |fetch      |
1                |                    |pre_dec             |           |pre_dec             |pre_dec             |           |set_address|
2                |                    |set_load_addr       |           |set_load_addr       |set_store_addr      |           |fetch2     |
3                |                    |load                |           |load                |                    |set_alu_ops|           |
4                |                    |                    |           |                    |                    |alu_clk    |           |
5                |                    |                    |modify     |modify              |store               |store      |           |
6                |set new PC          |set new PC          |set new PC |set new PC          |set new PC          |set new PC |set new PC |
7                |set_address         |post_inc,set_address|set_address|post_inc,set_address|post_inc,set_address|set_address|set_address|

stage/instruction|call_reg,  |call              |
                 |call_addr11|                  |
0                |fetch      |fetch             |
1                |dec sp     |set_address,dec sp|
2                |           |fetch2            |
3                |set_addr   |set_addr          |
4                |           |                  |
5                |store pc   |store pc          |
6                |set new PC |set new PC        |
7                |set_address|set_address       |

stage/instruction|alu_r_immediate   |alu_r_r    |alu_r_m         |
0                |fetch             |fetch      |fetch           |
1                |set_address       |           |pre_dec         |
2                |fetch2            |           |set_load_addr   |
3                |set_alu_ops       |set_alu_ops|load,set_alu_ops|
4                |alu_clk           |alu_clk    |alu_clk         |
5                |store             |store      |store           |
6                |set new PC        |set new PC |set new PC      |
7                |set_address       |set_address|set_address     |

*/

module tiny16
#(parameter STAGE_WIDTH = 8)
(
    input wire clk,
    input wire reset,
    output reg hlt = 0,
    output reg error = 0,
    output wire [15:0] address,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output wire rd,
    output wire wr,
    input wire ready,
    output reg [STAGE_WIDTH - 1:0] stage = 1
);
    // register names
    localparam SP = 15;

    localparam NOP = 1;

    reg [15:0] current_instruction, instruction_parameter;
    reg start = 0;
    reg stage_reset = 0;

    reg [15:0] pc, address_reg;
    reg address_source_pc;

    reg [15:0] registers [0:15];
    reg [15:0] registers_data_wr, source_reg_data, dest_reg_data;
    reg [15:0] sp_data;
    reg [3:0] registers_address_wr;
    reg registers_wr;

    wire [15:0] opcode0;
    wire [3:0] opcode;
    wire [2:0] opcode3;
    wire [4:0] opcode5;
    wire [5:0] opcode6;
    wire [11:0] opcode12;

    wire [15:0] value8_to_16, value7_to_16, value6_to_16, value11_to_16, value4_to_16, alu_op_adder_to_16;
    wire [7:0] value8;
    wire [6:0] value7;
    wire [5:0] value6;
    wire [3:0] value4;
    wire [1:0] value2;
    wire [10:0] value11;

    wire [3:0] source_reg;
    wire [3:0] dest_reg;
    wire post_inc, pre_dec;
    wire halt, err;
    wire nop, reti, pushf, ret;
    wire br, jmp_reg, jmp_preg, jmp_addr11, jmp;
    wire call_reg, call_addr11, call;
    wire mvil, mvih, movrm, movmr, movrr, movrimm, movmimm;
    wire adi8, alurm, alurr, alurimm, alumr, _not, mul;
    wire load, store;
    wire fetch2;
    wire n, c, z;
    wire go;
    wire clk1, clk3, clk4, clk5;

    wire [15:0] alu_out, alu_out2;
    wire [10:0] alu_op_adder;
    reg [4:0] alu_op_id;
    wire [4:0] alu_op_id1, alu_op_id2;
    wire alu_clk;
    reg [15:0] alu_op1, alu_op2, alu_op3;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    alu #(.BITS(16))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));

    assign n = alu_out[15];

    assign opcode0 = current_instruction[15:0];
    assign opcode12 = current_instruction[15:4];
    assign opcode = current_instruction[15:12];
    assign opcode5 = current_instruction[15:11];
    assign opcode6 = current_instruction[15:10];
    assign opcode3 = current_instruction[15:13];

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
    assign post_inc = current_instruction[5];
    assign pre_dec = current_instruction[4];
    assign alu_op_id1 = {current_instruction[12:10], current_instruction[5:4]};
    assign alu_op_id2 = instruction_parameter[4:0];
    assign alu_op_adder = instruction_parameter[15:5];

    // clr = xor reg, reg
    // not = xor reg, 0xFFFF
    assign halt = opcode0 == 0;
    assign nop = opcode0 == NOP;
    assign reti = opcode0 == 2;
    //mov -(sp), flags
    assign pushf = opcode0 == 3;
    // format |12'h1|condition,4bit|
    //        |addr,16bit|
    assign jmp = opcode12 == 1;
    // format |12'h2|condition,4bit|
    //        |addr,16bit|
    assign call = opcode12 == 2;
    // format |12'h3|condition,4bit|
    assign ret = opcode12 == 3;
    // format |12'h4|reg,4bit|
    assign _not = opcode12 == 4;
    // format |4'h1|offset,8bit|condition,4bit|
    assign br = opcode == 1;
    // format |4'h2|0,offset,7bit|reg,4bit|
    assign jmp_reg = opcode5 == 4;
    // format |4'h2|1,offset,7bit|reg,4bit|
    assign call_reg = opcode5 == 5;
    // format |4'h3|offset,6bit|post_inc|pre_dec|reg,4bit|
    assign jmp_preg = opcode == 3;
    // format |4'h4|0,offset,11bit|
    assign jmp_addr11 = opcode5 == 8;
    // format |4'h4|1,offset,11bit|
    assign call_addr11 = opcode5 == 9;
    // format |4'h5|data,8bit|reg,4bit|
    assign mvil = opcode == 5;
    // format |4'h6|data,8bit|reg,4bit|
    assign mvih = opcode == 6;
    // format |4'h7|offset,2bit|dst,4bit|post_inc|pre_dec|src,4bit|
    assign movrm = opcode == 7;
    // format |4'h8|offset,2bit|dst,4bit|post_inc|pre_dec|src,4bit|
    assign movmr = opcode == 8;
    // format |4'h9|adder,2bit|dst,4bit|adder,2bit|src,4bit|
    assign movrr = opcode == 9;
    // format |4'hA|value,8bit|reg,4bit|
    assign adi8 = opcode == 10;
    // format |4'hB|00|dst,4bit|post_inc|pre_dec|src,4bit|
    //        |adder,11bit|alu_op,5bit|
    assign alurm = opcode6 == 6'h2C;
    // format |4'hB|01|dst,4bit|post_inc|pre_dec|src,4bit|
    //        |adder,11bit|alu_op,5bit|
    assign alumr = opcode6 == 6'h2D;
    // format |4'hB|10|dst,4bit|ignore,6bit|
    //        |immediate,16bit|
    assign movrimm = opcode6 == 6'h2E;
    // format |4'hB|11|dst,4bit|post_inc|pre_dec|offset,4bit|
    //        |immediate,16bit|
    assign movmimm = opcode6 == 6'h2F;
    // format |3'h6|alu_op_hi,3bit|dst,4bit|alu_op_lo,2bit|src,4bit|
    assign alurr = opcode3 == 6;
    // format |3'h7|alu_op_hi,3bit|dst,4bit|alu_op_lo,2bit|src,4bit|
    //        |immediate,16bit|
    assign alurimm = opcode3 == 7;

    assign err = !halt & !nop & !pushf &
                 !br & !jmp_reg & !jmp_preg & !jmp_addr11 & !jmp &
                 !call_reg & !call_addr11 & !call &
                 !reti &
                 !mvil &!mvih & !movrm & !movmr & !movrr & !movrimm & !movmimm &
                 !_not & !adi8 & !alurm & !alurr & !alurimm;
    
    assign load = movrm | jmp_preg | alurm;
    assign store = movmr | (call & condition_pass) | call_addr11 | call_reg | movmimm | pushf;
    assign fetch2 = jmp | call | alurimm | alurm | movrimm | movmimm;

    assign address = address_source_pc ? pc : address_reg;
    
    assign mul = ((alurm | alurr | alumr) && alu_op_id1 == `ALU_OP_MUL) || (alurimm && alu_op_id2 == `ALU_OP_MUL);

    assign clk1 = stage[0];
    assign clk3 = stage[2];
    assign clk4 = stage[3];
    assign clk5 = stage[4];
    
    assign rd = !start | error | hlt | !(clk1 | (load & clk4) | (fetch2 & clk3));
    assign wr = !start | error | hlt | !(store & clk4);

    assign alu_clk = (adi8 | _not | alurr | alurm | alumr | alurimm) & clk5;

    assign go = start & ready & !error & !hlt;

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign value4_to_16 = {value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4[3], value4};
    assign value6_to_16 = {value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6[5], value6};
    assign value7_to_16 = {value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7[6], value7};
    assign value8_to_16 = {value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8[7], value8};
    assign value11_to_16 = {value11[10], value11[10], value11[10], value11[10], value11[10], value11};
    assign alu_op_adder_to_16 = {alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder[10], alu_op_adder};

    always @(posedge stage[STAGE_WIDTH - 1]) begin
        start <= reset;
    end

    always @(negedge clk) begin
        if (error | stage_reset)
            stage <= 1;
        else if (ready == 1)
            stage <= {stage[STAGE_WIDTH - 2:0], stage[STAGE_WIDTH - 1]};
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
            address_source_pc <= 1;
            pc <= 0;
        end
        else if (go) begin
            case (stage)
                // fetch
                1: begin
                    current_instruction <= data_in;
                    stage_reset <= 0;
                    registers_wr <= 1;
                end
                // pre_dec,set_address
                2:  begin
                    hlt <= halt | err;
                    error <= err;

                    if (br)
                        pc <= pc + (condition_pass ? value8_to_16 : 1);
                    else if (jmp_addr11 | call_addr11)
                        pc <= pc + value11_to_16;
                    else if (jmp_reg | call_reg)
                        pc <= source_reg_data + value7_to_16;
                    else if ((!jmp_preg & !ret & !reti) | fetch2)
                        pc <= pc + 1;

                    // 2 stage instructions
                    if (movrr | mvil | mvih | nop | halt | br | jmp_addr11 | jmp_reg) begin
                        if (movrr | mvil | mvih) begin
                            registers_wr <= 0;
                            registers_address_wr <= mvih | mvil ? source_reg : dest_reg;
                            if (movrr)
                                registers_data_wr <= source_reg_data + value4_to_16;
                            else if (mvih)
                                registers_data_wr <= (source_reg_data & 16'h00FF) | {value8, 8'h0};
                            else if (mvil)
                                registers_data_wr <= (source_reg_data & 16'hFF00) | {8'h0, value8};
                        end

                        stage_reset <= 1;
                    end
                    else begin
                        // pre dec
                        if (pre_dec & (movrm | jmp_preg | movmr | alumr)) begin
                            registers_data_wr <= movmr ? dest_reg_data - 1 : source_reg_data - 1;
                            registers_address_wr <= movmr ? dest_reg : source_reg;
                            registers_wr <= 0;
                        end
                        else begin
                            registers_data_wr <= movmr ? dest_reg_data : source_reg_data;
                            // dec SP
                            if ((call & condition_pass) | call_addr11 | call_reg | pushf) begin
                                registers_data_wr <= sp_data - 1;
                                registers_address_wr <= SP;
                                registers_wr <= 0;
                            end
                        end
                    end
                end
                // load,set_alu_ops,fetch2
                4: begin
                    instruction_parameter <= data_in;
                    // 4 stage instructions
                    if (movrimm | jmp_preg) begin
                        if (movrimm) begin
                            registers_address_wr <= dest_reg;
                            registers_data_wr <= data_in;
                            registers_wr <= 0;
                        end
                        pc <= (jmp_preg & condition_pass) ? registers_data_wr + value6_to_16 : pc + 1;
                    end
                    else begin
                        registers_wr <= 1;

                        if (movrm | movmr) begin
                            address_reg <= registers_data_wr + {14'h0, value2};
                            if (movmr)
                                data_out <= source_reg_data;
                            address_source_pc <= 0;
                        end
                        else if (movmimm) begin
                            address_reg <= registers_data_wr + value4_to_16;
                            data_out <= instruction_parameter;
                            address_source_pc <= 0;
                        end
                        else if (adi8) begin
                            alu_op1 <= source_reg_data;
                            alu_op2 <= value8_to_16;
                            alu_op_id <= `ALU_OP_ADD;
                        end
                        else if (_not) begin
                            alu_op1 <= source_reg_data;
                            alu_op2 <= 16'hFFFF;
                            alu_op_id <= `ALU_OP_XOR;
                        end
                        else if (alurr) begin
                            alu_op1 <= dest_reg_data;
                            alu_op2 <= source_reg_data;
                            alu_op_id <= alu_op_id1;
                        end
                    end
                end
                8: begin
                    if (movrimm | jmp_preg)
                        stage_reset <= 1;

                    if ((call & condition_pass) | call_addr11 | call_reg | pushf) begin
                        address_source_pc <= 0;
                        address_reg <= sp_data;
                        data_out <= pushf ? {13'h0, c, z, n} : (call ? pc + 2 : pc + 1);
                    end
                    if (movrm | alurm) begin
                        registers_wr <= 0;
                        registers_address_wr <= dest_reg;
                        if (movrm)
                            registers_data_wr <= data_in;
                        else begin
                            alu_op1 <= dest_reg_data;
                            alu_op2 <= data_in + alu_op_adder_to_16;
                            alu_op_id <= alu_op_id1;
                        end
                    end
                end
                //alu_clk
                16: begin
                    registers_wr <= 1;
                end
                //store,modify
                32: begin
                    address_source_pc <= 1;

                    if (adi8 | _not) begin
                        registers_wr <= 0;
                        registers_address_wr <= source_reg;
                        registers_data_wr <= alu_out;
                    end
                    else if ((alurr | alurimm) && alu_op_id1 != `ALU_OP_TEST && alu_op_id1 != `ALU_OP_CMP && alu_op_id1 != `ALU_OP_SETF) begin
                        registers_wr <= 0;
                        registers_address_wr <= dest_reg;
                        registers_data_wr <= alu_out;
                    end
                    else if (alurm && alu_op_id2 != `ALU_OP_TEST && alu_op_id2 != `ALU_OP_CMP && alu_op_id1 != `ALU_OP_SETF) begin
                        registers_wr <= 0;
                        registers_address_wr <= dest_reg;
                        registers_data_wr <= alu_out + alu_op_adder_to_16;
                    end

                    // set new pc
                    if (jmp_preg)
                        pc <= data_in;
                    else if (jmp | call)
                        pc <= condition_pass ? instruction_parameter : pc + 1;
                    else if (alurimm)
                        pc <= pc + 1;
                    //6 stage instructions
                    if (adi8 | _not | alurr | alurimm | jmp_preg | jmp | call)
                        stage_reset <= 1;
                end
                //post_inc, set_address
                64: begin
                    if (post_inc & (movrm | jmp_preg | movmr | alurm)) begin
                        registers_wr <= 0;
                        registers_address_wr <= movmr ? dest_reg : source_reg;
                        registers_data_wr <= movmr ? dest_reg_data + 1 : source_reg_data + 1;
                    end
                    else
                        registers_wr <= 1;
                    if (!mul)
                        stage_reset <= 1;
                end
                128: begin
                    if (mul) begin
                        registers_wr <= 0;
                        registers_address_wr <= dest_reg + 1;
                        registers_data_wr <= alu_out2;
                    end
                    else
                        registers_wr <= 1;
                end
            endcase
        end
    end
endmodule
