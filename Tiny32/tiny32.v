module tiny32
(
    input wire clk,
    input wire reset,
    output reg hlt = 0,
    output reg error = 0,
    output reg wfi = 0,
    output wire [31:0] address,
    input wire [31:0] data_in,
    output wire [31:0] data_out,
    output wire rd,
    output reg [3:0] wr = 4'b1111,
    input wire ready,
    input wire [7:0] interrupt,
    output reg [2:0] stage = 0
);
    localparam MICROCODE_WIDTH = 22;
    localparam INT = 25'h0;
    localparam INT_OP = 8'h0;

    reg [31:0] current_instruction = 3;
    reg start = 0;
    reg [2:0] stage_reset = 7;
    wire [2:0] last_stage;

    reg in_interrupt = 0;
    wire in_interrupt_clear;
    wire [6:0] interrupt_no;

    reg [31:0] pc, saved_pc;

    reg [7:0] op_decoder [0:2047];
    reg [7:0] op_decoder_result;
    wire [10:0] op_id;
    wire [4:0] op;
    wire [1:0] func7;
    wire [2:0] func3;
    wire [11:0] imm12i, imm12s, imm12b;
    wire [19:0] imm20u, imm20j;
    wire [31:0] source_address, source_address2;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:255];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 7;

    reg [31:0] registers [0:31];
    wire [31:0] registers_data_wr;
    reg [31:0] source1_reg_data, source2_reg_data;
    reg registers_wr = 1;
    wire registers_wr_flag;

    wire [4:0] source1_reg, source2_reg;
    wire [4:0] dest_reg;
    wire go;
    wire load, save_pc, set_pc;
    wire [3:0] store;
    wire [1:0] address_source;
    wire [2:0] pc_source;
    wire [4:0] registers_wr_data_source;

    wire err;
    
    initial begin
        $readmemh("decoder.mem", op_decoder);
        $readmemh("microcode.mem", microcode);
    end

    assign source1_reg = current_instruction[19:15];
    assign source2_reg = current_instruction[24:20];
    assign dest_reg = current_instruction[11:7];
    assign op = current_instruction[6:2];
    assign func3 = current_instruction[14:12];
    assign func7 = func7_f(current_instruction[31:25]);
    assign imm12i = current_instruction[31:20];
    assign imm12s = {current_instruction[31:25], current_instruction[11:7]};
    assign imm12b = {current_instruction[31], current_instruction[7], current_instruction[30:25], current_instruction[11:8]};
    assign imm20u = current_instruction[31:12];
    assign imm20j = {current_instruction[31], current_instruction[19:12], current_instruction[20], current_instruction[30:21]};

    assign registers_wr_flag = current_microinstruction[0];
    assign load = current_microinstruction[1];
    assign store = current_microinstruction[5:2];
    assign err = current_microinstruction[6];
    assign set_pc = current_microinstruction[7];
    assign pc_source = current_microinstruction[9:8];
    assign address_source = current_microinstruction[11:10];
    assign registers_wr_data_source = current_microinstruction[16:12];
    assign last_stage = current_microinstruction[19:17];
    assign in_interrupt_clear = current_microinstruction[20];
    assign save_pc = current_microinstruction[21];

    assign op_id = {func7, func3, op, condition_f(func3)};

    assign address = address_source_f(address_source);
    
    assign data_out = source2_reg_data;

    assign go = start & ready & !error & !hlt & !wfi;

    assign rd = !go | (stage[2:1] != 0 && !(load & stage[2:1] == 2));

    assign registers_data_wr = registers_data_wr_f(registers_wr_data_source);

    assign source_address = source1_reg_data + { {20{imm12i[11]}}, imm12i };
    assign source_address2 = source1_reg_data + { {20{imm12s[11]}}, imm12s };

    assign interrupt_no = interrupt_no_f(interrupt);

    function [6:0] interrupt_no_f(input [7:0] source);
        casez (source)
            8'b1???????: interrupt_no_f = 7'h8;
            8'b01??????: interrupt_no_f = 7'h7;
            8'b001?????: interrupt_no_f = 7'h6;
            8'b0001????: interrupt_no_f = 7'h5;
            8'b00001???: interrupt_no_f = 7'h4;
            8'b000001??: interrupt_no_f = 7'h3;
            8'b0000001?: interrupt_no_f = 7'h2;
            8'b00000001: interrupt_no_f = 7'h1;
            8'b00000000: interrupt_no_f = 7'h0;
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
            0: condition_f = source1_reg_data == source2_reg_data;
            1: condition_f = source1_reg_data != source2_reg_data;
            4: condition_f = source1_reg_data < source2_reg_data;
            5: condition_f = source1_reg_data >= source2_reg_data;
            6: condition_f = $signed(source1_reg_data) < $signed(source2_reg_data);
            7: condition_f = $signed(source1_reg_data) >= $signed(source2_reg_data);
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
            0: pc_source_f2 = { {19{imm12b[11]}}, imm12b, 1'b0 };
            1: pc_source_f2 = { {11{imm20j[19]}}, imm20j, 1'b0 };
            2: pc_source_f2 = { {19{imm12b[11]}}, imm12b, 1'b0 };
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
            default: alu_op1_f = 0;
        endcase
    endfunction

    function [31:0] alu_op2_f(input [1:0] source);
        case (source)
            0: alu_op2_f = {20'h0, imm12i};
            1: alu_op2_f = {20{imm12i[11]}}, imm12i};
            2: alu_op2_f = source2_reg_data;
            3: alu_op2_f = {27'h0, source2_reg_data[4:0]};
            default: alu_op2_f = pc;
        endcase
    endfunction

    function [31:0] data_load_f(input source_signed, input[3:0] shift);
        data_load_f = source_signed ? data_in >>> shift : data_in >> shift;
    endfunction

    function [31:0] data_store_f(input [31:0] data, input shift);
        data_store_f = data << shift;
    endfunction

    function [31:0] registers_data_wr_f(input source);
        case (source)
            0: registers_data_wr_f = data_load_f(data_load_signed, data_shift);
            1: registers_data_wr_f = alu_out;
        endcase
    endfunction

    always (negedge clk) begin
        case (alu_op)
            0: alu_out <= alu_op1 << alu_op2;
            1: alu_out <= alu_op1 >> alu_op2;
            2: alu_out <= alu_op1 >>> alu_op2;
            3: alu_out <= alu_op1 & alu_op2;
            4: alu_out <= alu_op1 | alu_op2;
            5: alu_out <= alu_op1 ^ alu_op2;
            6: alu_out <= {31'h0, alu_op1 < alu_op2};
            7: alu_out <= {31'h0, $signed(alu_op1) < $signed(alu_op2)};
            8: alu_out <= alu_op1 + alu_op2;
            9: alu_out <= alu_op1 - alu_op2;
        endcase
    end

    always @(negedge clk) begin
        if (error)
            stage <= 0;
        else begin
            if (!reset)
                start <= 0;
            else if (stage == 7)
                start <= 1;
            if (ready) begin
                if (stage == stage_reset)
                    stage <= 0;
                else
                    stage <= stage + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            current_instruction <= 3;
            in_interrupt <= 0;
            registers_wr <= 1;
            pc <= 0;
            hlt <= 0;
            error <= 0;
            wfi <= 0;
            stage_reset <= 7;
            wr <= 4'b1111;
        end
        else begin
            case (stage)
                0: begin
                    wr <= 4'b1111;
                    registers_wr <= 1;
                    if (in_interrupt_clear)
                        in_interrupt <= 0;
                end
                1: begin
                    if (interrupt_no != 0 && !in_interrupt) begin
                        in_interrupt <= 1;
                        current_instruction <= {interrupt_no, INT};
                    end
                    else
                        current_instruction <= data_in;
                end
                2: begin
                    if (go) begin
                        op_decoder_result <= current_instruction[1:0] != 2'b11 ? 8'b11000001 : op_decoder[op_id];
                        pc <= pc + 4;
                    end
                end
                3: begin
                    if (go) begin
                        hlt <= op_decoder_result[7];
                        error <= op_decoder_result[6] || pc[1:0] != 0;
                        wfi <= op_decoder_result[5:0] == 0;

                        current_microinstruction <= microcode[{op_decoder_result[5:0], source_address[1:0]}];
                    end
                end
                4: begin
                    if (go) begin
                        error <= err;
                        registers_wr <= registers_wr_flag;
                        wr <= store;
                        stage_reset <= last_stage;
                        if (save_pc)
                            saved_pc <= pc;
                        if (set_pc)
                            pc <= pc_source_f1(pc_source) + pc_source_f2(pc_source);
                    end
                end
            endcase
        end
    end

    always @(negedge clk) begin
        if (registers_wr == 0)
            registers[dest_reg] <= registers_data_wr;
        source1_reg_data <= source1_reg == 0 ? 0 : registers[source1_reg];
        source2_reg_data <= source2_reg == 0 ? 0 : registers[source2_reg];
    end
endmodule
