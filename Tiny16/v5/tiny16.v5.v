`include "tiny16.vh"

module tiny16
#(parameter INTERRUPT_BITS = 2)
(
    input wire clk,
    input wire nreset,
    output reg hlt = 0,
    output reg wfi = 0,
    output reg [15:0] address = 0,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output wire nrd,
    output wire nwr,
    output reg [STAGE_WIDTH - 1:0] stage = 1,
    input wire [INTERRUPT_BITS - 1:0] interrupt,
    output reg in_interrupt = 0,
    input wire ready
);
    localparam STAGE_WIDTH = 4;
    localparam INTERRUPT_BITS_TO_16 = 16 - INTERRUPT_BITS;

    // register names
    localparam A  = 0;
    localparam W  = 1;
    localparam X  = 2;
    localparam SP = 3;

    localparam NOP = 16'hFF50;

    reg [15:0] current_instruction = NOP;
    reg [15:0] registers [0:3];
    reg [15:0] acc, saved_acc, saved_pc, saved_pc2;
    reg [15:0] pc = 0;
    reg start = 0;

    wire [15:0] isr_address;

    wire halt, wfi_, reti, movrm, movmr, movrr, movrimm, mvl, add, sub, shl, shr, and_, or_, xor_;
    wire addi, subi, andi, ori, xori, andrm, subrm, andrm, orrm, xorrm;
    wire call_reg, call, br, loadpc, test, cmp, jmp16, swab;
    wire [15:0] value13_to_16, value9_to_16, value11_to_16, value8_to_16;
    wire [2:0] opcode;
    wire [11:0] opcode12;
    wire load, store, fetch2;
    wire [1:0] source_reg;
    wire [1:0] dest_reg;
    wire [7:0] value8;
    wire [8:0] value9;
    wire [10:0] value11;
    wire [12:0] value13;

    wire clk2, clk4;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;
    wire z, n;
    reg c, saved_c;
    wire [15:0] alu_op1, alu_op2;
    wire alu_op;

    wire go;
    reg next_stage = 1;

`ifdef MUL
    wire mul;
    reg [15:0] acc2;
`endif
`ifdef DIV
    wire div, rem;
`endif

    assign opcode3 = current_instruction[6:4];
    assign opcode4 = current_instruction[7:4];
    assign opcode12 = current_instruction[15:4];
    assign value11 = {current_instruction[1:0], current_instruction[15:7]};
    assign value8 = current_instruction[15:8];
    assign value9 = current_instruction[15:7];
    assign value13 = {current_instruction[3:0], current_instruction[15:7]};
    assign source_reg = current_instruction[1:0];
    assign dest_reg = current_instruction[3:2];
    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];

    assign z = acc == 0;
    assign n = acc[15];

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign isr_address = {{INTERRUPT_BITS_TO_16{1'b0}}, interrupt};

    // format |offset,9bit|3'h0|condition,4bit|
    assign br = opcode3 == 0;
    // format |data,9bit|3'h1|reg,2bit,data,2bit|
    assign mvl = opcode4 == 1;
    // format |offset,8bit|4'h2|dst,2bit,src,2bit|
    assign movmr = opcode4 == 2;
    // format |offset,8bit|4'h3|dst,2bit,src,2bit|
    assign movrm = opcode4 == 3;

    // format |8'h0|4'h4|XXXX|
    assign halt = opcode12 == 4;
    // format |8'h1|4'h4|XXXX|
    assign wfi_ = opcode12 == 12'h14;
    // format |8'h2|4'h4|XXXX|
    assign reti = opcode12 == 12'h24;

    // format |8'h3|4'h4|reg,2bit,XX|
    assign shr = opcode12 == 12'h34;
    // format |8'h4|4'h4|reg,2bit,XX|
    assign shl = opcode12 == 12'h44;

    // format |8'h5|4'h4|dst,2bit,src,2bit|
    assign movrr = opcode12 == 12'h54;

    // format |8'h6|4'h4|dst,2bit,src,2bit|
    assign add = opcode12 == 12'h64;
    // format |8'h7|4'h4|dst,2bit,src,2bit|
    assign sub = opcode12 == 12'h74;
    // format |8'h8|4'h4|dst,2bit,src,2bit|
    assign and_ = opcode12 == 12'h84;
    // format |8'h9|4'h4|dst,2bit,src,2bit|
    assign or_ = opcode12 == 12'h94;
    // format |8'hA|4'h4|dst,2bit,src,2bit|
    assign xor_ = opcode12 == 12'hA4;
    // format |8'hB|4'h4|dst,2bit,src,2bit|
    assign test = opcode12 == 12'hB4;
    // format |8'hC|4'h4|dst,2bit,src,2bit|
    assign cmp = opcode12 == 12'hC4;

    // format |8'hD|4'h4|dst,2bit,src,2bit|
    assign addi = opcode12 == 12'hD4;
    // format |8'hE|4'h4|dst,2bit,src,2bit|
    assign subi = opcode12 == 12'hE4;
    // format |8'hF|4'h4|dst,2bit,src,2bit|
    assign andi = opcode12 == 12'hF4;
    // format |8'h10|4'h4|dst,2bit,src,2bit|
    assign ori = opcode12 == 12'h104;
    // format |8'h11|4'h4|dst,2bit,src,2bit|
    assign xori = opcode12 == 12'h114;
    // format |8'h12|4'h4|dst,2bit,src,2bit|
    assign testi = opcode12 == 12'h124;
    // format |8'h13|4'h4|dst,2bit,src,2bit|
    assign cmpi = opcode12 == 12'h134;

    // format |8'h14|4'h4|dst,2bit,reg,2bit|
    assign call_reg = opcode12 == 12'h144;

    // format |8'h15|4'h4|dst,2bit,XX|
    assign movrimm = opcode12 == 12'h154;

    // format |8'h16|4'h4|XXXX|
    assign jmp16 = opcode12 == 12'h164;

    // format |8'h17|4'h4|dst,2bit,src,2bit|
    assign swab = opcode12 == 12'h174;

`ifdef MUL
    // format |8'h18|4'h4|dst,2bit,src,2bit|
    assign mul = opcode12 == 12'h184;
    // format |8'h19|4'h4|dst,2bit,src,2bit|
    assign muli = opcode12 == 12'h194;
`endif

`ifdef DIV
    // format |8'h1A|4'h4|dst,2bit,src,2bit|
    assign div = opcode12 == 12'h1A4;
    // format |8'h1B|4'h4|dst,2bit,src,2bit|
    assign divi = opcode12 == 12'h1B4;
    // format |8'h1A|4'h4|dst,2bit,src,2bit|
    assign rem = opcode12 == 12'h1C4;
    // format |8'h1A|4'h4|dst,2bit,src,2bit|
    assign remi = opcode12 == 12'h1D4;
`endif

    // format |value,9bit|3'h5|XX|reg,2bit|
    assign loadpc = opcode3 == 5;
    // format |offset,9bit|3'h6|reg,2bit,offset,2bit|
    assign call = opcode3 == 6;

    // format |offset,8bit|4'h7|dst,2bit,src,2bit|
    assign addrm = opcode4 == 7;
    // 8 is br
    // 9 is mvl
    // format |offset,8bit|4'h9|dst,2bit,src,2bit|
    assign subrm = opcode4 == 10;
    // format |offset,8bit|4'hA|dst,2bit,src,2bit|
    assign andrm = opcode4 == 11;
    // format |offset,8bit|4'hB|dst,2bit,src,2bit|
    assign orrm = opcode4 == 12;
    // D is loadpc
    // E is call
    // format |offset,8bit|4'hC|dst,2bit,src,2bit|
    assign xorrm = opcode4 == 15;

    assign load = movrm | loadpc;
    assign store = movmr | call | call_reg;

    assign clk2 = stage[1];
    assign clk4 = stage[3];

    assign fetch2 = movrimm | jmp16 | alurm, alurimm;

    assign nrd = !go | !(clk2 | ((load | fetch2) & clk4));
    assign nwr = !go | !(store & clk4);

    assign go = start & !hlt;

    assign value8_to_16 = {8{value8[7]}, value8};
    assign value9_to_16 = {7{value9[8]}, value9};
    assign value11_to_16 = {5{value11[10]}, value11};
    assign value13_to_16 = {3{value13[12]}, value13};

    assign alu_op = shl | shr | add | sub | and_ | or_ | xor_
`ifdef MUL
    | mul
`ifdef DIV
    | div | rem;
`else
    ;
`endif
`else
    ;
`endif

    assign alu_op1 = registers[dest_reg];
    assign alu_op2 = registers[source_reg];

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
                    case (1'b1)
                        movrm | movrimm: registers[dest_reg] <= data_in;
                        movrr: registers[dest_reg] <= registers[source_reg];
                        swab: registers[dest_reg] <= {registers[source_reg][7:0], registers[source_reg][15:8]};
                        mvl: registers[dest_reg] <= value11_to_16;
                        alu_op: registers[dest_reg] <= acc;
                    endcase

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
                    hlt <= halt;
                    if (reti) begin
                        pc <= saved_pc;
                        in_interrupt <= 0;
			            c <= saved_c;
                        acc <= saved_acc;
                    end
                    else if (call_reg)
                       pc <= registers[source_reg];
                    else
                        pc <= pc + (jmp ? value13_to_16 : (call ? value11_to_16 : ((br & condition_pass) ? value9_to_16 : (movrimm ? 2 : 1))));
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
                    endcase
                end
                8: begin
                    case (1'b1)
                        loadpc | jmp16: pc <= data_in;
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
            endcase
        end
    end

endmodule
