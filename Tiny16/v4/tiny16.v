`include "tiny16.vh"

/*

clk|substage|stage|mem_clk
0  |1       |1    |0
1  |1       |1    |1
0  |2       |1    |0
1  |2       |1    |0
0  |4       |1    |0
1  |4       |2    |0
0  |1       |2    |0
1  |1       |2    |1
*/
module tiny16
#(parameter INTERRUPT_BITS = 2)
(
    input wire clk,
    input wire nreset,
    output wire hlt,
    output reg wfi = 0,
    output reg [15:0] address = 0,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output wire nrd,
    output wire nwr,
    input wire [INTERRUPT_BITS - 1:0] interrupt,
    output reg in_interrupt = 0,
    input wire ready
    output reg [STAGE_WIDTH - 1:0] stage = 1,
    output reg [2:0] substage = 1,
);
    localparam STAGE_WIDTH = 6;
    localparam INTERRUPT_BITS_TO_16 = 16 - INTERRUPT_BITS;

    // register names
    localparam SP = 15;

    localparam NOP = 16'hFF50;

    reg [15:0] current_instruction = NOP;
    reg [15:0] registers [0:15];
    reg [15:0] acc, saved_acc, saved_pc, saved_pc2;
    reg [15:0] pc = 0;
    reg start = 0;

    wire [15:0] isr_address;

    wire [3:0] opcode;
    wire [7:0] opcode8;
    wire [3:0] source_reg;
    wire [3:0] dest_reg;
    wire [14:0] value15;
    wire [9:0] value10;
    wire [3:0] value4;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;
    wire z, n;
    reg c, saved_c;
    wire [15:0] alu_op1, alu_op2;
    wire [3:0] alu_op;

    wire go;
    reg next_stage = 1;

`ifdef MUL
    reg [15:0] acc2;
`endif

    assign opcode = current_instruction[15:12];
    assign opcode8 = current_instruction[15:8];
    assign alu_op = current_instruction[11:8];
    assign source_reg = current_instruction[3:0];
    assign dest_reg = current_instruction[7:4];
    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];
    assign value15 = current_instruction[14:0];
    assign value10 = current_instruction[13:4];
    assign value4 = current_instruction[3:0];

    assign z = acc == 0;
    assign n = acc[15];

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign isr_address = {{INTERRUPT_BITS_TO_16{1'b0}}, interrupt};

    assign clk2 = stage[1];
    assign clk4 = stage[3];

    // format |0|offset,15bit|
    assign j = !current_instruction[15];
    // format |10|offset,10bit|condition,4bit|
    assign br = current_instruction[15:14] == 2;
    // format |1100|alu_op|dst_reg,src_reg|
    assign alurr = opcode == 12;
    // format |1101|alu_op|dst_reg,src_reg|
    //        |offset 16 bit|
    assign alurm = opcode == 13;
    // format |1110|alu_op|dst_reg,src_reg|
    //        |offset 16 bit|
    assign alurimm = opcode == 14;
    // format |11110000|dst_reg,src_reg|
    //        |offset 16 bit|
    assign store = opcode8 == 8'b11110000;
    // format |11110001|XXXXXXXX|
    assign hlt = opcode8 == 8'b11110001;
    // format |11110010|XXXXXXXX|
    assign reti = opcode8 == 8'b11110010;
    // format |11110011|XXXXXXXX|
    assign wfi = opcode8 == 8'b11110011;
    // format |11110100|XXXX,src_reg|
    assign j_reg = opcode8 == 8'b11110100;
    // format |11110101|dst_reg,offset,4bit|
    //        |address 16 bit|
    assign jal = opcode8 == 8'b11110101;
    // format |11110110|dst_reg,src_reg|
    //        |offset 16 bit|
    assign jal_reg = opcode8 == 8'b11110110;

    assign nrd = !go | !(clk2 | ((load | fetch2) & clk4));
    assign nwr = !go | !(store & clk4);

    assign go = start & !hlt;

    assign value4_to_16 = {12{value4[3]}, value4};
    assign value10_to_16 = {6{value10[9]}, value10};
    assign value15_to_16 = {value15[14], value15};

    assign alu_op1 = registers[dest_reg];
    assign alu_op2 = current_instruction[13:12] == 0 ? registers[source_reg] : data_in;

    always @(posedge clk) begin
        if (!nreset)
            start <= 0;
        else if (stage[STAGE_WIDTH - 1])
            start <= 1;
    end

    always @(negedge clk) begin
        if (!nreset)
            stage <= 1;
        else if (!wfi & next_stage)
            stage <= {stage[STAGE_WIDTH - 2:0], stage[STAGE_WIDTH - 1]};
    end

    always @(posedge clk) begin
        if (clk2) begin
            source_reg_data <= source_reg == 0 ? 0 : registers[source_reg];
            dest_reg_data <= dest_reg == 0 ? 0 : registers[dest_reg];
        end
    end

    always @(posedge clk) begin
        if (clk1 & !registers_wr)
            registers[dest_reg] <= registers_data_wr;
    end

    always @(posedge clk) begin
        if (!nreset) begin
            pc <= 0;
            current_instruction <= NOP;
            address <= 0;
            hlt <= 0;
            in_interrupt <= 0;
            next_stage <= 1;
        end
        else if (go) begin
            case (stage)
                1: begin
                    if (interrupt != 0 && !in_interrupt) begin
                        in_interrupt <= 1;
                        wfi <= 0;
                        saved_pc <= pc;
                        saved_c <= c;
                        saved_acc <= acc;
                        pc <= isr_address;
                        address <= isr_address;
                    end
                    else begin
                        address <= pc;
                        wfi <= wfi_;
                    end
                end
                2: begin
                    next_stage <= ready;
                    current_instruction <= data_in;
                    saved_pc2 <= pc;
                end
                4: begin
                    case (1'b1)
                        load: address <= (source_reg == 0 ? 0 : registers[source_reg]) + value9_to_16;
                        fetch2: address <= saved_pc2 + 1;
                        store: begin
                            if (call | call_reg) begin
                                address <= registers[dest_reg] - 1;
                                data_out <= saved_pc2 + 1;
                            end
                            else begin
                                address <= (dest_reg == 0 ? 0 : registers[dest_reg]) + value9_to_16;
                                data_out <= registers[source_reg];
                            end
                        end
                        add: {c, acc} <= alu_op1 + alu_op2;
                        sub | cmp: {c, acc} <= alu_op1 - alu_op2;
                        shl: {c, acc} <= {alu_op1, 1'b0};
                        shr: {acc, c} <= {1'b0, alu_op1};
                        and_ | test: acc <= alu_op1 & alu_op2;
                        or_: acc <= alu_op1 | alu_op2;
                        xor_: acc <= alu_op1 ^ alu_op2;
`ifdef MUL
                        mul: {acc2, acc} <= alu_op1 * alu_op2;
`endif
`ifdef DIV
                        div: acc <= alu_op1 / alu_op2;
                        rem: acc <= alu_op1 % alu_op2;
`endif
                    endcase
                end
                8: begin
                    if (reti) begin
                        in_interrupt <= 0;
			            c <= saved_c;
                        acc <= saved_acc;
                    end
                    case (1'b1)
                        reti: pc <= saved_pc;
                        j: pc <= pc + value15_to_16;
                        br: pc <= pc + (condition_pass ? value10_to_16 : 1);
                        j_reg | jal_reg: pc <= source_reg_data;
                        jal: pc <= data_in;
                    endcase
                    case (1'b1)
                        loadpc | jmp16: pc <= data_in;
                        movrm | movrimm: registers[dest_reg] <= data_in;
                        movrr: registers[dest_reg] <= registers[source_reg];
                        swab: registers[dest_reg] <= {registers[source_reg][7:0], registers[source_reg][15:8]};
                        mvl: registers[dest_reg] <= value11_to_16;
                        alu_op: registers[dest_reg] <= acc;
                    endcase
                end
            endcase
        end
    end

endmodule
