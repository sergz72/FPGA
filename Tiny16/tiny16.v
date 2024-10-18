module tiny16
(
    input wire clk,
    input wire reset,
    output reg hlt = 0,
    output reg wfi = 0,
    output reg [15:0] address = 0,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output wire rd,
    output wire wr,
    output reg [STAGE_WIDTH - 1:0] stage = 1,
    input wire interrupt,
    output reg in_interrupt = 0,
    input wire ready
);
    localparam STAGE_WIDTH = 4;

    // register names
    localparam A  = 0;
    localparam W  = 1;
    localparam X  = 2;
    localparam SP = 3;

    localparam NOP = 16'hFFFF;

    reg [15:0] current_instruction = NOP;
    reg [15:0] registers [0:3];
    reg [15:0] acc, saved_acc, saved_pc;
    reg [15:0] pc = 0;
    reg start = 0;

    wire halt, wfi_, reti, jmp, movrm, movmr, movrr, movrimm, mvl, add, sub, shl, shr, and_, or_, xor_;
    wire call_reg, call, br, loadpc, test, cmp;
    wire [15:0] value13_to_16, value9_to_16, value11_to_16;
    wire [2:0] opcode;
    wire [11:0] opcode12;
    wire load, store;
    wire [1:0] source_reg;
    wire [1:0] dest_reg;
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

    assign opcode = current_instruction[6:4];
    assign opcode12 = current_instruction[15:4];
    assign value11 = {current_instruction[1:0], current_instruction[15:7]};
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

    // format |offset,9bit|3'h0|offset,4bit|
    assign jmp = opcode == 0;
    // format |offset,9bit|3'h1|condition,4bit|
    assign br = opcode == 1;
    // format |data,9bit|3'h2|reg,2bit,data,2bit|
    assign mvl = opcode == 2;
    // format |offset,9bit|3'h3|dst,2bit,src,2bit|
    assign movmr = opcode == 3;
    // format |offset,9bit|3'h4|dst,2bit,src,2bit|
    assign movrm = opcode == 4;

    // format |9'h0|3'h5|XXXX|
    assign halt = opcode12 == 5;
    // format |9'h1|3'h5|XXXX|
    assign wfi_ = opcode12 == 12'hD;
    // format |9'h2|3'h5|XXXX|
    assign reti = opcode12 == 12'h15;

    // format |9'h3|3'h5|reg,2bit,XX|
    assign shr = opcode12 == 12'h1D;
    // format |9'h4|3'h5|reg,2bit,XX|
    assign shl = opcode12 == 12'h25;

    // format |9'h5|3'h5|dst,2bit,src,2bit|
    assign movrr = opcode12 == 12'h2D;

    // format |9'h6|3'h5|dst,2bit,src,2bit|
    assign add = opcode12 == 12'h35;
    // format |9'h7|3'h5|dst,2bit,src,2bit|
    assign sub = opcode12 == 12'h3D;
    // format |9'h8|3'h5|dst,2bit,src,2bit|
    assign and_ = opcode12 == 12'h45;
    // format |9'h9|3'h5|dst,2bit,src,2bit|
    assign or_ = opcode12 == 12'h4D;
    // format |9'hA|3'h5|dst,2bit,src,2bit|
    assign xor_ = opcode12 == 12'h55;
    // format |9'hB|3'h5|dst,2bit,src,2bit|
    assign test = opcode12 == 12'h5D;
    // format |9'hC|3'h5|dst,2bit,src,2bit|
    assign cmp = opcode12 == 12'h65;
    // format |9'hD|3'h5|dst,2bit,reg,2bit|
    assign call_reg = opcode12 == 12'h6D;

    // format |9'hE|3'h5|dst,2bit,XX|
    assign movrimm = opcode12 == 12'h75;

    // format |value,9bit|3'h6|XX|reg,2bit|
    assign loadpc = opcode == 6;
    // format |offset,9bit|3'h7|reg,2bit,offset,2bit|
    assign call = opcode == 7;

    assign load = movrm | loadpc;
    assign store = movmr | call | call_reg;

    assign clk2 = stage[1];
    assign clk4 = stage[3];

    assign rd = !go | !(clk2 | ((load | movrimm) & clk4));
    assign wr = !go | !(store & clk4);

    assign go = start & !hlt;

    assign value9_to_16 = {value9[8], value9[8], value9[8], value9[8], value9[8], value9[8], value9[8], value9};
    assign value11_to_16 = {value11[10], value11[10], value11[10], value11[10], value11[10], value11};
    assign value13_to_16 = {value13[12], value13[12], value13[12], value13};

    assign alu_op = shl | shr | add | sub | and_ | or_ | xor_;

    assign alu_op1 = registers[dest_reg];
    assign alu_op2 = registers[source_reg];

    always @(posedge clk) begin
        if (!reset)
            start <= 0;
        else if (stage[STAGE_WIDTH - 1])
            start <= 1;
    end

    always @(negedge clk) begin
        if (!reset)
            stage <= 1;
        else if (!wfi & next_stage)
            stage <= {stage[STAGE_WIDTH - 2:0], stage[STAGE_WIDTH - 1]};
    end

    always @(posedge clk) begin
        if (!reset) begin
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
                    if (interrupt & !in_interrupt) begin
                        in_interrupt <= 1;
                        wfi <= 0;
                        saved_pc <= pc;
                        saved_c <= c;
                        saved_acc <= acc;
                        pc <= 1;
                        address <= 1;
                    end
                    else begin
                        address <= pc;
                        wfi <= wfi_;
                    end
                end
                2: begin
                    next_stage <= ready;
                    current_instruction <= data_in;
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
                        movrimm: address <= pc + 1;
                        store: begin
                            if (call | call_reg) begin
                                address <= registers[dest_reg] - 1;
                                data_out <= pc + 1;
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
                    endcase
                end
                8: begin
                    case (1'b1)
                        loadpc: pc <= data_in;
                        movrm | movrimm: registers[dest_reg] <= data_in;
                        movrr: registers[dest_reg] <= registers[source_reg];
                        mvl: registers[dest_reg] <= value11_to_16;
                        alu_op: registers[dest_reg] <= acc;
                    endcase
                end
            endcase
        end
    end

endmodule
