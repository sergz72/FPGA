`define ALU_OP_NOP 0
`define ALU_OP_ADD 1
`define ALU_OP_ADC 2
`define ALU_OP_SUB 3
`define ALU_OP_SBC 4
`define ALU_OP_SHR 5
`define ALU_OP_SHL 6
`define ALU_OP_NOT 7
`define ALU_OP_NEG 8
`define ALU_OP_AND 9
`define ALU_OP_OR  10
`define ALU_OP_XOR 11

`define ALU_OP1_SOURCE_REG 0
`define ALU_OP1_DEST_REG 1

`define ALU_OP2_SOURCE_SOURCE_REG 0
`define ALU_OP2_SOURCE_VALUE9_TO_16 1
`define ALU_OP2_SOURCE_DATA_IN 2

/*

call = 
    call -1(SP), addr

ret = loadpc -1(SP)

*/

module tiny16
#(parameter STAGE_WIDTH = 4)
(
    input wire clk,
    input wire reset,
    output reg hlt = 0,
    output reg [15:0] address,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output wire rd,
    output wire wr,
    output reg [STAGE_WIDTH - 1:0] stage = 1
);
    // register names
    localparam A  = 0;
    localparam W  = 1;
    localparam X  = 2;
    localparam SP = 3;

    localparam NOP = 1;

    reg [15:0] current_instruction;
    reg [15:0] registers [0:3];
    reg [15:0] acc, pc;
    reg start = 0;

    wire [15:0] opcode0, value9_to_16, value12_to_16, value8_to_16, value10_to_16;
    wire [7:0] value;
    wire [3:0] opcode;
    wire [4:0] opcode5;
    wire [5:0] opcode6;
    wire [13:0] opcode14;
    wire [11:0] opcode12;
    wire [8:0] value9;
    wire [9:0] value10;
    wire [11:0] value12;
    wire [1:0] source_reg;
    wire [1:0] dest_reg;
    wire halt, nop, br, jmp, mvh, movrm, movmr, movrr, adi, shl, shr, not_, neg, loadpc, call, adcrr, addrr;
    wire addrm, adcrm, subrm, sbcrm, subrr, sbcrr, andrr, orrr, xorrr, andrm, orrm, xorrm, call_reg;
    wire load, store;
    wire z, n;
    reg c;
    wire go;
    wire clk1, clk3;

    reg alu_op1_source;
    reg [1:0] alu_op2_source;
    reg [3:0] alu_op;
    wire [15:0] alu_op1, alu_op2;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    assign z = acc == 0;
    assign n = acc[15];

    assign opcode0 = current_instruction[15:0];
    assign opcode = current_instruction[7:4];
    assign opcode5 = current_instruction[7:3];
    assign opcode6 = current_instruction[7:2];
    assign opcode14 = current_instruction[15:2];
    assign opcode12 = current_instruction[15:4];
    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];
    assign value = current_instruction[15:8];
    assign value9 = {current_instruction[2], current_instruction[15:8]};
    assign value10 = {current_instruction[1:0], current_instruction[15:8]};
    assign value12 = {current_instruction[3:0], current_instruction[15:8]};
    assign source_reg = current_instruction[1:0];
    assign dest_reg = current_instruction[3:2];

    assign halt = opcode0 == 0;
    assign nop = opcode0 == NOP;
    assign shr = opcode14 == 1;
    assign shl = opcode14 == 2;
    assign not_ = opcode14 == 3;
    // format |offset,8bit|4'h1|condition,4bit|
    assign br = opcode == 1;
    // format |offset,8bit|4'h2|offset,4bit|
    assign jmp = opcode == 2;
    // format |data,8bit|4'h3|0data,1bit,reg,2bit|
    assign mvh = opcode5 == 6;
    // format |value,8bit|4'h3|1value,1bit,reg,2bit|
    assign adi = opcode5 == 7;
    // format |offset,8bit|4'h4|dst,2bit,src,2bit|
    assign movrm = opcode == 4;
    // format |offset,8bit|4'h5|dst,2bit,src,2bit|
    assign movmr = opcode == 5;

    // format |8'h0|4'h6|dst,2bit,src,2bit|
    assign movrr = opcode12 == 6;
    // format |8'h1|4'h6|00,reg,2bit|
    assign neg = opcode14 == 14'b1011000;
    // format |8'h2|4'h6|dst,2bit,src,2bit|
    assign addrr = opcode12 == 12'h26;
    // format |8'h3|4'h6|dst,2bit,src,2bit|
    assign adcrr = opcode12 == 12'h36;
    // format |8'h4|4'h6|dst,2bit,src,2bit|
    assign subrr = opcode12 == 12'h46;
    // format |8'h5|4'h6|dst,2bit,src,2bit|
    assign sbcrr = opcode12 == 12'h56;
    // format |8'h6|4'h6|dst,2bit,src,2bit|
    assign andrr = opcode12 == 12'h66;
    // format |8'h7|4'h6|dst,2bit,src,2bit|
    assign orrr = opcode12 == 12'h76;
    // format |8'h8|4'h6|dst,2bit,src,2bit|
    assign xorrr = opcode12 == 12'h86;
    // format |8'h9|4'h6|dst,2bit,reg,2bit|
    assign call_reg = opcode12 == 12'h96;

    // format |value,8bit|4'h7|00|reg,2bit|
    assign loadpc = opcode6 == 7<<2;
    // format |offset,8bit|4'h8|reg,2bit,offset,2bit|
    assign call = opcode == 8;

    // format |offset,8bit|4'h9|dst,2bit,src,2bit|
    assign addrm = opcode == 9;
    // format |offset,8bit|4'hA|dst,2bit,src,2bit|
    assign adcrm = opcode == 10;
    // format |offset,8bit|4'hB|dst,2bit,src,2bit|
    assign subrm = opcode == 11;
    // format |offset,8bit|4'hC|dst,2bit,src,2bit|
    assign sbcrm = opcode == 12;
    // format |offset,8bit|4'hD|dst,2bit,src,2bit|
    assign andrm = opcode == 13;
    // format |offset,8bit|4'hE|dst,2bit,src,2bit|
    assign orrm = opcode == 14;
    // format |offset,8bit|4'hF|dst,2bit,src,2bit|
    assign xorrm = opcode == 15;
    
    assign load = movrm | loadpc | addrm | adcrm | subrm | sbcrm | andrm | orrm | xorrm;
    assign store = movmr | call | call_reg;

    assign clk1 = stage[0];
    assign clk3 = stage[2];
    
    assign rd = !go | !(clk1 | (load & clk3));
    assign wr = !go | !(store & clk3);

    assign go = start & !hlt;

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign value8_to_16 = {value[7], value[7], value[7], value[7], value[7], value[7], value[7], value[7], value};
    assign value9_to_16 = {value9[8], value9[8], value9[8], value9[8], value9[8], value9[8], value9[8], value9};
    assign value10_to_16 = {value10[9], value10[9], value10[9], value10[9], value10[9], value10[9], value10};
    assign value12_to_16 = {value12[11], value12[11], value12[11], value12[11], value12};

    assign alu_op1 = alu_op1_f(alu_op1_source);
    assign alu_op2 = alu_op2_f(alu_op2_source);

    function [15:0] alu_op1_f(input source);
        case (source)
            0: alu_op1_f = registers[source_reg];
            1: alu_op1_f = registers[dest_reg];
        endcase
    endfunction

    function [15:0] alu_op2_f(input [1:0] source);
        case (source)
            0: alu_op2_f = registers[source_reg];
            1: alu_op2_f = value9_to_16;
            default: alu_op2_f = data_in;
        endcase
    endfunction

    always @(posedge stage[STAGE_WIDTH - 1]) begin
        start <= reset;
    end

    always @(negedge clk) begin
        stage <= {stage[STAGE_WIDTH - 2:0], stage[STAGE_WIDTH - 1]};
    end

    always @(posedge clk) begin
        if (!reset) begin
            pc <= 0;
            current_instruction <= NOP;
            address <= 0;
            hlt <= 0;
        end
        else if (go) begin
            case (stage)
                1: begin
                    current_instruction <= data_in;
                    alu_op <= `ALU_OP_NOP;
                end
                2: begin
                    hlt <= halt;
                    if (call_reg)
                       pc <= registers[source_reg];
                    else
                        pc <= pc + (jmp ? value12_to_16 : (call ? value10_to_16 : ((br & condition_pass) ? value8_to_16 : 1)));
                    if (load | store) begin
                        if (call | call_reg)
                            address <= registers[dest_reg] - 1;
                        else if (load)
                            address <= (source_reg == 0 ? 0 : registers[source_reg]) + value8_to_16;
                        if (store) begin
                            address <= (dest_reg == 0 ? 0 : registers[dest_reg]) + value8_to_16;
                            if (call | call_reg)
                               data_out <= pc + 1;
                            else
                               data_out <= registers[source_reg];
                        end
                    end
                    case (1'b1)
                        adi: begin
                            alu_op1_source <= `ALU_OP1_SOURCE_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_VALUE9_TO_16;
                            alu_op <= `ALU_OP_ADD;
                        end
                        shl: begin
                            alu_op1_source <= `ALU_OP1_SOURCE_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_SHL;
                        end
                        shr: begin
                            alu_op1_source <= `ALU_OP1_SOURCE_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_SHR;
                        end
                        not_: begin
                            alu_op1_source <= `ALU_OP1_SOURCE_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_NOT;
                        end
                        neg: begin
                            alu_op1_source <= `ALU_OP1_SOURCE_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_NEG;
                        end
                        addrr: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_ADD;
                        end
                        adcrr: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_ADC;
                        end
                        subrr: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_SUB;
                        end
                        sbcrr: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_SBC;
                        end
                        addrm: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_DATA_IN;
                            alu_op <= `ALU_OP_ADD;
                        end
                        adcrm: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_DATA_IN;
                            alu_op <= `ALU_OP_ADC;
                        end
                        subrm: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_DATA_IN;
                            alu_op <= `ALU_OP_SUB;
                        end
                        sbcrm: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_DATA_IN;
                            alu_op <= `ALU_OP_SBC;
                        end
                        andrr: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_AND;
                        end
                        andrm: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_DATA_IN;
                            alu_op <= `ALU_OP_AND;
                        end
                        orrr: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_OR;
                        end
                        orrm: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_DATA_IN;
                            alu_op <= `ALU_OP_OR;
                        end
                        xorrr: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_SOURCE_REG;
                            alu_op <= `ALU_OP_XOR;
                        end
                        xorrm: begin
                            alu_op1_source <= `ALU_OP1_DEST_REG;
                            alu_op2_source <= `ALU_OP2_SOURCE_DATA_IN;
                            alu_op <= `ALU_OP_XOR;
                        end
                    endcase
                end
                4: begin
                    case (alu_op)
                        `ALU_OP_ADD: {c, acc} <= alu_op1 + alu_op2;
                        `ALU_OP_ADC: {c, acc} <= alu_op1 + alu_op2 + {15'h0, c};
                        `ALU_OP_SUB: {c, acc} <= alu_op1 - alu_op2;
                        `ALU_OP_SBC: {c, acc} <= alu_op1 - alu_op2 - {15'h0, c};
                        `ALU_OP_SHR: {acc, c} <= {1'b0, alu_op1};
                        `ALU_OP_SHL: {acc, c} <= {alu_op1, 1'b0};
                        `ALU_OP_NOT: acc <= ~alu_op1;
                        `ALU_OP_NEG: acc <= -alu_op1;
                        `ALU_OP_AND: acc <= alu_op1 & alu_op2;
                        `ALU_OP_OR:  acc <= alu_op1 | alu_op2;
                        `ALU_OP_XOR: acc <= alu_op1 ^ alu_op2;
                    endcase
                    if (loadpc)
                        pc <= data_in;
                    if (movrm | movrr)
                        registers[dest_reg] <= movrr ? registers[source_reg] : data_in;
                    else if (mvh)
                        registers[source_reg] <= {value9, 7'h0};
                end
                8: begin
                    address <= pc;
                    if (adi | shl | shr | not_ | neg)
                        registers[source_reg] <= acc;
                    else if (adcrr | addrr | subrr | sbcrr | adcrm | addrm | sbcrm | subrm | andrm | andrr | orrm | orrr | xorrm | xorrr)
                        registers[dest_reg] <= acc;
                end
            endcase
        end
    end
endmodule
