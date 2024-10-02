`include "tiny32.vh"

/*

clk|stage|rd |wr |jmp|br     |alu|load|store
0  |0    |1  |1  |
1  |0    |1  |1  |interrupt handling
0  |1    |0  |1  |
1  |1    |0  |1  |instruction_load
   |     |   |   |instruction decode
0  |2    |1  |1/0|microcode load
1  |2    |1  |1/0|registers load
0  |3    |1/0|1  |may be alu_clk,
1  |3    |1/0|1  |set pc,may be registers_wr

*/

module tiny32
(
    input wire clk,
    input wire nreset,
    output reg hlt = 0,
    output reg error = 0,
    output reg wfi = 0,
    output wire [31:0] address,
    input wire [31:0] data_in,
    output wire [31:0] data_out,
    output wire nrd,
    output wire [3:0] nwr,
    input wire ready,
    input wire [7:0] interrupt,
    output reg [1:0] stage = 0
);
    localparam MICROCODE_WIDTH = 31;

    reg [31:0] current_instruction = 3;
    wire [9:0] op_id;
    wire [4:0] op;
    wire [1:0] func7;
    wire [2:0] func3;
    wire [11:0] imm12i, imm12s, imm12b;
    wire [19:0] imm20u, imm20j;
    wire [31:0] source_address, source_address2;
    wire [4:0] source1_reg, source2_reg;
    wire [4:0] dest_reg;

    reg start = 0;
    wire clk2, clk3, clk4;

    reg in_interrupt = 0;
    wire [3:0] interrupt_no;

    reg [31:0] pc, saved_pc;

    reg [7:0] op_decoder [0:1023];
    reg [7:0] op_decoder_result;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:255];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 7;
    wire load, set_pc;
    wire [3:0] store;
    wire [1:0] address_source;
    wire [1:0] pc_source;
    wire registers_wr_data_source;
    wire registers_wr;
    wire [31:0] registers_data_wr;
    wire err;
    wire in_interrupt_clear;
    wire alu_clk;
    wire [1:0] alu_op1_source;
    wire [2:0] alu_op2_source;
    wire data_load_signed;
    wire [4:0] data_shift;

    reg [31:0] registers [0:31];
    reg [31:0] source1_reg_data, source2_reg_data;

    wire [31:0] alu_op1, alu_op2;
    wire [4:0] alu_op;
    reg [31:0] alu_out, alu_out2;

    wire z;
    reg c;
    wire signed_lt;

    wire go, gowfi;
    
    initial begin
        $readmemh("decoder.mem", op_decoder);
        $readmemh("microcode.mem", microcode);
    end

    assign clk2 = stage == 1;
    assign clk3 = stage == 2;
    assign clk4 = stage == 3;

    assign source1_reg = current_instruction[19:15];
    assign source2_reg = current_instruction[24:20];
    assign dest_reg = current_instruction[11:7];
    assign op = data_in[6:2];
    assign func3 = data_in[14:12];
    assign func7 = func7_f(data_in[31:25]);
    assign imm12i = current_instruction[31:20];
    assign imm12s = {current_instruction[31:25], current_instruction[11:7]};
    assign imm12b = {current_instruction[31], current_instruction[7], current_instruction[30:25], current_instruction[11:8]};
    assign imm20u = current_instruction[31:12];
    assign imm20j = {current_instruction[31], current_instruction[19:12], current_instruction[20], current_instruction[30:21]};

    assign registers_wr = current_microinstruction[0];
    assign load = current_microinstruction[1];
    assign store = current_microinstruction[5:2];
    assign err = current_microinstruction[6];
    assign set_pc = current_microinstruction[7];
    assign pc_source = current_microinstruction[9:8];
    assign address_source = current_microinstruction[11:10];
    assign registers_wr_data_source = current_microinstruction[12];
    assign in_interrupt_clear = current_microinstruction[13];
    assign alu_clk = current_microinstruction[14];
    assign alu_op1_source = current_microinstruction[16:15];
    assign alu_op2_source = current_microinstruction[19:17];
    assign alu_op = current_microinstruction[24:20];
    assign data_load_signed = current_microinstruction[25];
    assign data_shift = current_microinstruction[30:26];

    assign op_id = {op, func3, func7};

    assign address = address_source_f(address_source);
    
    assign data_out = source2_reg_data;

    assign gowfi = start & ready & !error & !hlt;
    assign go = gowfi &  !wfi;

    assign nrd = !go | !(clk2 | (load & clk4));
    assign nwr = go & clk4 ? store : 4'b1111;

    assign registers_data_wr = registers_data_wr_f(registers_wr_data_source);

    assign source_address = source1_reg_data + { {20{imm12i[11]}}, imm12i };
    assign source_address2 = source1_reg_data + { {20{imm12s[11]}}, imm12s };

    assign interrupt_no = interrupt_no_f(interrupt);

    assign alu_op1 = alu_op1_f(alu_op1_source);
    assign alu_op2 = alu_op2_f(alu_op2_source);

    assign z = alu_out == 0;
    assign signed_lt = !z & ((source1_reg_data[31] & !source2_reg_data[31]) | (source1_reg_data[31] == source2_reg_data[31] & c));

    function [3:0] interrupt_no_f(input [7:0] source);
        casez (source)
            8'b1???????: interrupt_no_f = 4'h8;
            8'b01??????: interrupt_no_f = 4'h7;
            8'b001?????: interrupt_no_f = 4'h6;
            8'b0001????: interrupt_no_f = 4'h5;
            8'b00001???: interrupt_no_f = 4'h4;
            8'b000001??: interrupt_no_f = 4'h3;
            8'b0000001?: interrupt_no_f = 4'h2;
            8'b00000001: interrupt_no_f = 4'h1;
            8'b00000000: interrupt_no_f = 4'h0;
        endcase
    endfunction

    function [1:0] func7_f(input [6:0] source);
        case (source)
            7'b0000000: func7_f = 2'b00;
            7'b0000001: func7_f = 2'b01;
            7'b0100000: func7_f = 2'b10;
            default: func7_f = 2'b11;
        endcase
    endfunction

    function condition_f(input [2:0] source);
        case (source)
            0: condition_f = z;
            1: condition_f = !z;
            4: condition_f = c;
            5: condition_f = !c;
            6: condition_f = signed_lt;
            7: condition_f = !signed_lt;
            default: condition_f = 0;
        endcase
    endfunction

    function [31:0] pc_source_f1(input [1:0] source);
        case (source)
            0: pc_source_f1 = pc;
            1: pc_source_f1 = pc;
            2: pc_source_f1 = source1_reg_data;
            3: pc_source_f1 = saved_pc;
        endcase
    endfunction

    function [31:0] pc_source_f2(input [1:0] source);
        case (source)
            0: pc_source_f2 = condition_f(func3) ? { {19{imm12b[11]}}, imm12b, 1'b0 } : 4;
            1: pc_source_f2 = { {11{imm20j[19]}}, imm20j, 1'b0 };
            2: pc_source_f2 = { {19{imm12i[11]}}, imm12i, 1'b0 };
            3: pc_source_f2 = 0;
        endcase
    endfunction

    function [31:0] address_source_f(input [1:0] source);
        case (source)
            0: address_source_f = pc;
            1: address_source_f = source_address;
            default: address_source_f = source_address2;
        endcase
    endfunction

    function [31:0] alu_op1_f(input [1:0] source);
        case (source)
            0: alu_op1_f = source1_reg_data;
            1: alu_op1_f = {imm20u, 12'h0};
            default: alu_op1_f = 4;
        endcase
    endfunction

    function [31:0] alu_op2_f(input [2:0] source);
        case (source)
            0: alu_op2_f = {20'h0, imm12i};
            1: alu_op2_f = {{20{imm12i[11]}}, imm12i};
            2: alu_op2_f = source2_reg_data;
            3: alu_op2_f = {27'h0, source2_reg_data[4:0]};
            default: alu_op2_f = pc;
        endcase
    endfunction

    function [31:0] data_load_f(input source_signed, input [4:0] shift);
        data_load_f = source_signed ? data_in >>> shift : data_in >> shift;
    endfunction

    function [31:0] data_store_f(input [31:0] data, input [4:0] shift);
        data_store_f = data << shift;
    endfunction

    function [31:0] registers_data_wr_f(input source);
        case (source)
            0: registers_data_wr_f = data_load_f(data_load_signed, data_shift);
            1: registers_data_wr_f = alu_out;
        endcase
    endfunction

    always @(negedge clk3) begin
        if (alu_clk) begin
            case (alu_op)
                0: alu_out <= alu_op1 << alu_op2;
                1: alu_out <= alu_op1 >> alu_op2;
                2: alu_out <= alu_op1 >>> alu_op2;
                3: alu_out <= alu_op1 & alu_op2;
                4: alu_out <= alu_op1 | alu_op2;
                5: alu_out <= alu_op1 ^ alu_op2;
                6: alu_out <= {31'h0, c};
                7: alu_out <= {31'h0, signed_lt};
                8: alu_out <= alu_op1 + alu_op2;
                9: {c, alu_out} <= alu_op1 - alu_op2;
                10: {alu_out2, alu_out} <= alu_op1 * alu_op2;
                11: {alu_out, alu_out2} <= $signed(alu_op1) * $signed(alu_op2);
                12: {alu_out, alu_out2} <= $signed(alu_op1) * alu_op2;
                13: {alu_out, alu_out2} <= alu_op1 * alu_op2;
`ifndef NO_DIV
                14: alu_out <= $signed(alu_op1) / $signed(alu_op2);
                15: alu_out <= alu_op1 / alu_op2;
                16: alu_out <= $signed(alu_op1) % $signed(alu_op2);
                17: alu_out <= alu_op1 % alu_op2;
`endif
                default: alu_out <= 0;
            endcase
        end
    end

    always @(negedge clk) begin
        if (error)
            stage <= 0;
        else begin
            if (!nreset)
                start <= 0;
            else if (stage == 3)
                start <= 1;
            if (ready)
                stage <= stage + 1;
        end
    end

    always @(negedge clk) begin
        if (!nreset) begin
            hlt <= 0;
            error <= 0;
        end
        else begin
            if (go) begin
                if (clk2) begin
                    hlt <= op_decoder_result[7] | op_decoder_result[6];
                    error <= op_decoder_result[6] || pc[1:0] != 0;
                    current_microinstruction <= microcode[{op_decoder_result[5:0], source_address[1:0]}];
                end
                else if (clk3) begin
                    hlt <= err;
                    error <= err;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!nreset) begin
            current_instruction <= 3;
            in_interrupt <= 0;
            pc <= 0;
            wfi <= 0;
        end
        else begin
            case (stage)
                0: begin
                    if (gowfi) begin
                        if (interrupt_no != 0 && !in_interrupt) begin
                            in_interrupt <= 1;
                            wfi <= 0;
                            saved_pc <= pc;
                            pc <= {26'h0, interrupt_no, 2'b00};
                        end
                        if (in_interrupt_clear)
                            in_interrupt <= 0;
                    end
                end
                1: begin
                    if (go) begin
                        current_instruction <= data_in;
                        op_decoder_result <= data_in[1:0] != 2'b11 ? 8'b11000001 : op_decoder[op_id];
                    end
                end
                2: begin
                    if (go)
                        wfi <= op_decoder_result[5:0] == 0;
                end
                3: begin
                    if (go) begin
                        if (set_pc)
                            pc <= pc_source_f1(pc_source) + pc_source_f2(pc_source);
                        else
                            pc <= pc + 4;
                    end
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (clk4 & !registers_wr)
            registers[dest_reg] <= registers_data_wr;
        else if (clk3) begin
            source1_reg_data <= source1_reg == 0 ? 0 : registers[source1_reg];
            source2_reg_data <= source2_reg == 0 ? 0 : registers[source2_reg];
        end
    end
endmodule
