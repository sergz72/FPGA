/*

call = 
    mvi XL, low(SP_ADDR)
    mvi XH, high(SP_ADDR)
    mov W, (X)
    adi W, -1
    mov (X), W
    mov (W), PC
    mvi WL, low(addr)
    mvi WH, high(addr)
    mov PC, W

ret = 
    mvi XL, low(SP_ADDR)
    mvi XH, high(SP_ADDR)
    mov W, (X)
    adi W, 1
    mov (X), W
    mov PC, (W-1)

*/

module tiny16
#(parameter STAGE_WIDTH = 4)
(
    input wire clk,
    input wire reset,
    output reg hlt = 0,
    output reg error = 0,
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
    localparam PC = 3;

    localparam NOP = 1;

    reg [15:0] current_instruction;
    reg [15:0] registers [0:3];
    reg [15:0] acc;
    reg start = 0;

    wire [15:0] opcode0, value9_to_16, value12_to_16, value8_to_16;
    wire [7:0] value;
    wire [3:0] opcode;
    wire [8:0] value9;
    wire [11:0] value12;
    wire [1:0] source_reg;
    wire [1:0] dest_reg;
    wire halt, err, nop, br, jmp, mvi, movrm, movmr, movrr, adi, shl, shr, xori, andi, ori;
    wire load, store;
    wire z, n;
    reg c;
    wire go, hi;
    wire clk1, clk3;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    assign z = acc == 0;
    assign n = acc[15];

    assign opcode0 = current_instruction[15:0];
    assign opcode = current_instruction[7:4];
    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];
    assign value = current_instruction[15:8];
    assign value9 = {current_instruction[2], current_instruction[15:8]};
    assign value12 = {current_instruction[3:0], current_instruction[15:8]};
    assign source_reg = current_instruction[1:0];
    assign dest_reg = current_instruction[3:2];
    assign hi = current_instruction[2];

    assign halt = opcode0 == 0;
    assign nop = opcode0 == NOP;
    assign shr = current_instruction[15:2] == 1;
    assign shl = current_instruction[15:2] == 2;
    // format |offset,8bit|4'h1|condition,4bit|
    assign br = opcode == 1;
    // format |offset,8bit|4'h2|offset,4bit|
    assign jmp = opcode == 2;
    // format |data,8bit|4'h3|0hi/lo,reg,2bit|
    assign mvi = current_instruction[7:3] == 6;
    // format |value,8bit|4'h3|1value,1bit,reg,2bit|
    assign adi = current_instruction[7:3] == 7;
    // format |offset,8bit|4'h4|dst,2bit,src,2bit|
    assign movrm = opcode == 4;
    // format |offset,8bit|4'h5|dst,2bit,src,2bit|
    assign movmr = opcode == 5;
    // format |offset,8bit|4'h5|dst,2bit,src,2bit|
    assign movrr = opcode == 6;
    // format |value,8bit|4'h6|0value,1bit,reg,2bit|
    assign xori = current_instruction[7:3] == 5'hC;
    // format |value,8bit|4'h6|1value,1bit,reg,2bit|
    assign andi = current_instruction[7:3] == 5'hD;
    // format |value,8bit|4'h7|0value,1bit,reg,2bit|
    assign ori = current_instruction[7:3] == 5'hE;

    assign err = !halt & !nop & !br & !jmp & !mvi & !movrm & !movmr & !movrr & !adi & !shr & !shl & !xori & !andi & !ori;
    
    assign load = movrm;
    assign store = movmr;

    assign clk1 = stage[0];
    assign clk3 = stage[2];
    
    assign rd = !go | !(clk1 | (load & clk3));
    assign wr = !go | !(store & clk3);

    assign go = start & !hlt & !error;

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign value8_to_16 = {value[7], value[7], value[7], value[7], value[7], value[7], value[7], value[7], value};
    assign value9_to_16 = {value9[8], value9[8], value9[8], value9[8], value9[8], value9[8], value9[8], value9};
    assign value12_to_16 = {value12[11], value12[11], value12[11], value12[11], value12};

    always @(posedge stage[STAGE_WIDTH - 1]) begin
        start <= reset;
    end

    always @(negedge clk) begin
        if (error)
            stage <= 1;
        else
            stage <= {stage[STAGE_WIDTH - 2:0], stage[STAGE_WIDTH - 1]};
    end

    always @(posedge clk) begin
        if (!reset) begin
            registers[PC] <= 0;
            current_instruction <= NOP;
            address <= 0;
            hlt <= 0;
            error <= 0;
        end
        else if (go) begin
            case (stage)
                1: current_instruction <= data_in;
                2: begin
                    hlt <= halt | err;
                    error <= err;
                    registers[PC] <= registers[PC] + (jmp ? value12_to_16 : (br & condition_pass ? value8_to_16 : 1));
                    if (load | store) begin
                        address <= registers[load ? source_reg : dest_reg] + value8_to_16;
                        if (store)
                            data_out <= registers[source_reg];
                    end
                    else if (adi)
                        {c, acc} <= registers[source_reg] + value9_to_16;
                    else if (shl)
                        {c, acc} <= {registers[source_reg], 1'b0};
                    else if (shr)
                        {acc, c} <= {1'b0, registers[source_reg]};
                    else if (xori)
                        acc <= registers[source_reg] ^ value9_to_16;
                    else if (andi)
                        acc <= registers[source_reg] & value9_to_16;
                    else if (ori)
                        acc <= registers[source_reg] | value9_to_16;
                end
                4: begin
                    if (load)
                        registers[dest_reg] <= data_in;
                    else if (movrr)
                        registers[dest_reg] <= registers[source_reg];
                    else if (mvi) begin
                        if (hi)
                            registers[dest_reg][15:8] <= value;
                        else
                            registers[dest_reg][7:0] <= value;
                    end
                    else if (adi | shl | shr | xori | andi | ori)
                        registers[source_reg] <= acc;
                end
                8: begin
                    address <= registers[PC];
                end
            endcase
        end
    end
endmodule
