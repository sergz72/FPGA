module tiny86
(
    input wire clk,
    input wire reset,
    output reg hlt,
    output reg error,
    output reg [7:0] address_hi,
    output wire [15:0] address,
    input wire [15:0] data_in,
    output wire [15:0] data_out,
    output wire rd,
    output reg wr,
    input wire ready
);
    // register names
    localparam SP = 6;
    localparam PC = 7;
    localparam NOP = 1;

    reg [15:0] current_instruction;
    reg [15:0] immediate;
    reg [15:0] registers [0:7];
    reg [15:0] A;
    reg start = 0;
    reg [2:0] stage, stage_reset;

    wire [7:0] opcode0, offset, one_op_opcode;
    wire one_op;
    wire [3:0] opcode, value;
    wire [2:0] condition;
    wire condition_neg;
    wire [2:0] source_reg;
    wire [2:0] dest_reg;
    wire source_p, dest_p, source_immediate;
    wire halt, br, ret, jmp_addr, jmp_reg, call_offset, call_addr, call_reg, mov, inc, dec, neg, _not,
         shl, shr, rol, ror, err;
    wire fetch_source, fetch_dest;
    wire z, n;
    reg c;
    reg [2:0] address_source;
    reg [2:0] data_out_source;

    assign z = A == 0;
    assign n = A[15];

    assign address = registers[address_source];
    assign data_out = registers[data_out_source];

    assign value = opcode[3:0];
    assign opcode0 = current_instruction[7:0];
    assign opcode = current_instruction[7:4];
    assign one_op_opcode = {current_instruction[15:12], opcode};
    assign condition = opcode[2:0];
    assign condition_neg = opcode[3];
    assign offset = current_instruction[15:8];
    // can be R0-R7, immediate, (R1-R7)
    assign source_reg = current_instruction[10:8];
    assign source_immediate = current_instruction[11:8] == 4'b1000;
    assign source_p = current_instruction[11];
    assign dest_reg = current_instruction[14:12];
    assign dest_p = current_instruction[15];

    assign halt = opcode0 == 0;
    assign nop = opcode0 == NOP;
    // format |offset,8bit|4'h1|condition,4bit|
    assign br = opcode == 1;
    // format |0,8bit|4'h2|condition,4bit|
    assign ret = current_instruction[15:4] == 2;
    // format |addr_hi,8bit|4'h3|condition,4bit|
    //        |addr_lo,16bit|
    assign jmp_addr = opcode == 3;
    // format |dest,4bit|8'h04|condition,4bit|
    assign jmp_reg = current_instruction[11:4] == 4;
    // format |offset,8bit|4'h5|condition,4bit|
    assign call_offset = opcode == 5;
    // format |addr_hi,8bit|4'h6|condition,4bit|
    //        |addr_lo,16bit|
    assign call_addr = opcode == 6;
    // format |dest,4bit|8'h07|condition,4bit|
    assign call_reg = current_instruction[11:4] == 6;
    // format |dest,4bit|src,4bit|4'h7|adder,4bit|
    //        may be immediate
    assign mov = opcode == 7;

    // format |source/dest,4bit|8'h08|value,4bit|
    assign one_op = opcode == 8;
    assign inc = one_op_opcode == 8;
    // format |source/dest,4bit|8'h18|value,4bit|
    assign dec = one_op_opcode == 8'h18;
    // format |dest,4bit|8'h28|source,4bit|
    assign neg = one_op_opcode == 8'h28;
    // format |dest,4bit|8'h38|source,4bit|
    assign _not = one_op_opcode == 8'h38;
    // format |source/dest,4bit|8'h48|value,4bit|
    assign shl = one_op_opcode == 8'h48;
    // format |source/dest,4bit|8'h58|value,4bit|
    assign shr = one_op_opcode == 8'h58;
    // format |source/dest,4bit|8'h68|value,4bit|
    assign rol = one_op_opcode == 8'h68;
    // format |source/dest,4bit|8'h78|value,4bit|
    assign ror = one_op_opcode == 8'h78;

    assign err = !mov & !br & !ret & !jmp_addr & !jmp_reg & !call_offset &
                 !call_addr & !call_reg && !mov & !inc & !dec & !neg & !_not & !shl & !shr &
                 !rol & !ror;
    assign instruction_length2 = jmp_addr | call_addr | (mov & source_immediate);
    
    assign fetch_source = source_p && !source_immediate;

    assign rd = !start | !(stage == 0) | !(instruction_length2 & stage == 2);

    always @(negedge clk) begin
        if (error != 0)
            stage <= 0;
        else begin
            if (reset == 0)
                start <= 0;
            else if (stage == stage_reset)
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
                    stage_reset <= 7;
                end
                1: begin
                    if (!halt & !err) begin
                        if (instruction_length2)
                            registers[PC] <= registers[PC] + 1;
                        else if (fetch_source)
                            address_source <= source_reg;
                        else begin
                            if (!dest_p) begin
                                stage_reset <= 1;
                                if (mov)
                                    registers[dest_reg] <= registers[source_reg];
                                else if (inc)
                                    {c, A} <= registers[source_reg] + value;
                                else if (dec)
                                    {c, A} <= registers[source_reg] - value;
                            end
                        end
                    end
                    hlt <= halt | err;
                    error <= err;
                end
                2: begin
                    immediate <= data_in;
                    if (fetch_source) begin
                        stage_reset <= 2;
                        if (mov)
                            registers[dest_reg] <= data_in;
                        else if (inc)
                            {c, A} <= data_in + value;
                        else if (dec)
                            {c, A} <= data_in - value;
                    end
                    else begin
                        if (!dest_p) begin
                            stage_reset <= 2;
                            if (one_op)
                                registers[dest_reg] <= A;
                        end
                    end
                end
            endcase
        end
    end
endmodule
