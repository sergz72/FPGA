/*

call = 
    mvi XL, low(SP_ADDR)
    mvi XH, low(SP_ADDR)
    mov W, (X)
    adi W, -1
    mov (X), W
    mov (W), PC
    mvi WL, low(addr)
    mvi WH, low(addr)
    mov PC, W

ret = 
    mvi XL, low(SP_ADDR)
    mvi XH, low(SP_ADDR)
    mov W, (X)
    adi W, 1
    mov (X), W
    mov PC, (W-1)

*/

module tiny16
(
    input wire clk,
    input wire reset,
    output reg hlt,
    output reg error,
    output wire [15:0] address,
    input wire [15:0] data_in,
    output wire [15:0] data_out,
    output wire rd,
    output reg wr,
    input wire ready
);
    // register names
    localparam A  = 0;
    localparam W  = 1;
    localparam X  = 2;
    localparam PC = 3;

    localparam NOP = 1;

    reg [15:0] current_instruction;
    reg [15:0] registers [0:3];
    reg start = 0;
    reg [1:0] stage;

    wire [7:0] opcode0, value;
    wire [3:0] opcode;
    wire [9:0] value10;
    wire [2:0] condition;
    wire condition_neg;
    wire [1:0] source_reg;
    wire [1:0] dest_reg;
    wire halt, err, nop, br, jmp, mvi, movrm, movmr, adi;
    wire load, store;
    wire z, n;
    reg c;
    reg [1:0] address_source;
    reg [1:0] data_out_source;

    assign z = registers[A] == 0;
    assign n = registers[A][15];

    assign address = registers[address_source];
    assign data_out = registers[data_out_source];

    assign opcode0 = current_instruction[15:0];
    assign opcode = current_instruction[7:4];
    assign condition = opcode[2:0];
    assign condition_neg = opcode[3];
    assign value = current_instruction[15:8];
    assign value10 = {current_instruction[3:2], current_instruction[15:8]};
    assign source_reg = current_instruction[1:0];
    assign dest_reg = current_instruction[3:2];
    assign hilo = current_instruction[2];

    assign halt = opcode0 == 0;
    assign nop = opcode0 == NOP;
    // format |offset,8bit|4'h1|condition,4bit|
    assign br = opcode == 1;
    // format |offset,8bit|4'h2|offset,2bit,reg,2bit|
    assign jmp = opcode == 2;
    // format |data,8bit|4'h3|0hi/lo,reg,2bit|
    assign mvi = current_instruction[7:3] == 6;
    // format |offset,8bit|4'h4|dst,2bit,src,2bit|
    assign movrm = opcode == 4;
    // format |offset,8bit|4'h5|dst,2bit,src,2bit|
    assign movmr = opcode == 5;
    // format |value,8bit|4'h6|value,2bit,reg,2bit|
    assign adi = opcode == 6;

    assign err = !halt & !nop & !br & !jmp & !mvi & !movrm & !movmr & !adi;
    
    assign load = movrm;
    assign store = movmr;

    assign rd = !start | !(stage == 0) | !(load & stage == 2);

    always @(negedge clk) begin
        if (error != 0)
            stage <= 0;
        else begin
            if (reset == 0)
                start <= 0;
            else if (stage == 3)
                start <= 1;
            if (ready == 1)
                stage <= stage + 1;
        end
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            registers[PC] <= 0;
            current_instruction <= NOP;
            stage_reset <= 7;
            address_source <= PC;
        end
        else if (start & ready & !error) begin
            case (stage)
                0: begin
                    current_instruction <= data_in;
                end
                1: begin
                    hlt <= halt | err;
                    error <= err;
                    address_source <= load ? source_reg : dest_reg;
                end
                2: begin
                end
                3: begin
                    address_source <= PC;
                end
            endcase
        end
    end
endmodule
