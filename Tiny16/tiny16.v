/*

*/

module tiny16
#(parameter STAGE_WIDTH = 5)
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
    reg [15:0] acc;
    reg start = 0;

    reg [15:0] registers [0:15];
    reg [15:0] registers_data_wr, source_reg_data, dest_reg_data, pc_data;
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
    wire halt, err, nop, br, jmp_reg, jmp_preg, jmp_addr12, mvil, mvih, movrm, movmr, movrr, adi8;
    wire load, store;
    wire z, n;
    reg c;
    wire go;
    wire clk1, clk3;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    assign z = acc == 0;
    assign n = acc[15];

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

    assign err = !halt & !nop & !br & !jmp_reg & !jmp_preg & !jmp_addr12 & !mvil &!mvih & !movrm & !movmr & !movrr & !adi8;
    
    assign load = movrm | jmp_preg;
    assign store = movmr;

    assign clk1 = stage[0];
    assign clk3 = stage[2];
    
    assign rd = !start | !clk1 | !(load & clk3);
    assign wr = !start | !(store & clk3);

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
                // instruction read
                1: begin
                    current_instruction <= data_in;
                    registers_wr <= 1;
                end
                2:  begin
                    hlt <= halt | err;
                    error <= err;
                    if (adi8)
                        {c, acc} <= source_reg_data + value8_to_16;
                    if (movrr) begin
                        registers_data_wr <= source_reg_data + value4_to_16;
                        registers_address_wr <= dest_reg;
                        registers_wr <= 0;
                    end
                    else if (mvih) begin
                        registers_data_wr <= (source_reg_data & 16'h00FF) | {value8, 8'h0};
                        registers_address_wr <= source_reg;
                        registers_wr <= 0;
                    end
                    else if (mvil) begin
                        registers_data_wr <= (source_reg_data & 16'hFF00) | {8'h0, value8};
                        registers_address_wr <= source_reg;
                        registers_wr <= 0;
                    end
                    else if (pre_dec) begin
                        if (movrm | jmp_preg) begin
                            registers_data_wr <= source_reg_data - 1;
                            registers_address_wr <= source_reg;
                            registers_wr <= 0;
                        end
                        else if (movmr) begin
                            registers_data_wr <= dest_reg_data - 1;
                            registers_address_wr <= dest_reg;
                            registers_wr <= 0;
                        end
                    end
                end
                4: begin
                    if (jmp_preg & condition_pass)
                        address <= source_reg_data + value6_to_16;
                    else if (movrm)
                        address <= source_reg_data + {14'h0, value2};
                    else if (movmr) begin
                        address <= dest_reg_data + {14'h0, value2};
                        data_out <= source_reg_data;
                    end
                end
                8: begin
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
                16: begin
                    if (movrm) begin
                        registers_wr <= 0;
                        registers_address_wr <= dest_reg;
                        registers_data_wr <= data_in;
                    end
                end
                16: begin
                    if (post_inc) begin
                        if (movrm | jmp_preg) begin
                            registers_wr <= 0;
                            registers_address_wr <= source_reg;
                            registers_data_wr <= source_reg_data + 1;
                        end
                        else if (movmr) begin
                            registers_wr <= 0;
                            registers_address_wr <= dest_reg;
                            registers_data_wr <= dest_reg_data + 1;
                        end
                    end
                    address <= pc_data;
                end
            endcase
        end
    end
endmodule
