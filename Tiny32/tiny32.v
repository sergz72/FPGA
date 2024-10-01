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
    output wire [3:0] wr,
    input wire ready,
    input wire [7:0] interrupt,
    output reg [1:0] stage = 0,
    output reg [4:0] substage = 1
);
    localparam MICROCODE_WIDTH = 21;
    localparam INT = 25'h0;
    localparam INT_OP = 8'h0;

    reg [31:0] current_instruction = 3;
    reg start = 0;
    wire stage_reset;
    wire clk1, clk2, clk3, clk4, clk5;

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

    reg [MICROCODE_WIDTH - 1:0] microcode [0:1023];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 7;

    reg [31:0] registers [0:31];
    wire [31:0] registers_data_wr;
    reg [31:0] source1_reg_data, source2_reg_data;
    wire [32:0] source_sub;
    wire registers_wr;

    wire [4:0] source1_reg, source2_reg;
    wire [4:0] dest_reg;
    wire go;
    wire load, set_pc, save_pc;
    wire [1:0] address_source;
    wire [2:0] pc_source;
    wire [4:0] registers_wr_data_source;

    wire halt, err;
    
    initial begin
        $readmemh("decoder.mem", op_decoder);
        $readmemh("microcode.mem", microcode);
    end

    assign clk1 = substage[0];
    assign clk2 = substage[1];
    assign clk3 = substage[2];
    assign clk4 = substage[3];
    assign clk5 = substage[4];

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

    assign registers_wr = current_microinstruction[0];
    assign load = current_microinstruction[1];
    assign wr = current_microinstruction[5:2];
    assign err = current_microinstruction[6];
    assign set_pc = current_microinstruction[7];
    assign pc_source = current_microinstruction[10:8];
    assign address_source = current_microinstruction[12:11];
    assign registers_wr_data_source = current_microinstruction[17:13];
    assign stage_reset = current_microinstruction[18];
    assign in_interrupt_clear = current_microinstruction[19];
    assign save_pc = current_microinstruction[20];

    assign op_id = {func7, func3, op, condition_f(func3)};

    assign address = address_source_f(address_source);
    
    assign data_out = source2_reg_data;

    assign go = start & ready & !error & !hlt;

    assign rd = (!start | error | hlt) | ((stage != 0) && !load);

    assign registers_data_wr = registers_data_wr_f(registers_wr_data_source);

    assign source_address = source1_reg_data + { {20{imm12i[11]}}, imm12i };
    assign source_address2 = source1_reg_data + { {20{imm12s[11]}}, imm12s };

    assign source_sub = source1_reg_data - source2_reg_data;

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
            0: condition_f = source_sub == 0;
            1: condition_f = source_sub != 0;
            4: condition_f = source_sub[32];
            5: condition_f = !source_sub[32];
            6: condition_f = $signed(source1_reg_data) < $signed(source2_reg_data);
            7: condition_f = $signed(source1_reg_data) >= $signed(source2_reg_data);
            default: condition_f = 0;
        endcase
    endfunction

    function [31:0] pc_source_f(input [2:0] source);
        case (source)
            0: pc_source_f = pc + 4;
            1: pc_source_f = pc + 4 + { {19{imm12b[11]}}, imm12b, 1'b0 };
            2: pc_source_f = pc + 4 + { {11{imm20j[19]}}, imm20j, 1'b0 };
            3: pc_source_f = source1_reg_data + { {19{imm12b[11]}}, imm12b, 1'b0 };
            default: pc_source_f = saved_pc;
        endcase
    endfunction

    function [31:0] address_source_f(input [1:0] source);
        case (source)
            0: address_source_f = pc;
            1: address_source_f = source_address;
            default: address_source_f = source_address2;
        endcase
    endfunction

    function [31:0] registers_data_wr_f(input [4:0] source);
        case (source)
            0: registers_data_wr_f = data_in;
            1: registers_data_wr_f = { {24{data_in[7]}}, data_in[7:0] };
            2: registers_data_wr_f = { {16{data_in[15]}}, data_in[15:0] };
            3: registers_data_wr_f = {24'h0, data_in[7:0]};
            4: registers_data_wr_f = {16'h0, data_in[15:0]};
            5: registers_data_wr_f = source_address;
            6: registers_data_wr_f = source1_reg_data << imm12i;
            7: registers_data_wr_f = source1_reg_data >> imm12i;
            8: registers_data_wr_f = source1_reg_data >>> imm12i;
            9: registers_data_wr_f = source1_reg_data & { {20{imm12i[11]}}, imm12i };
            10: registers_data_wr_f = source1_reg_data | { {20{imm12i[11]}}, imm12i };
            11: registers_data_wr_f = source1_reg_data ^ { {20{imm12i[11]}}, imm12i };
            12: registers_data_wr_f = {imm20u, 12'h0} + pc + 4;
            13: registers_data_wr_f = {31'h0, source1_reg_data < { {20{imm12i[11]}}, imm12i }};
            14: registers_data_wr_f = {31'h0, $signed(source1_reg_data) < $signed({ {20{imm12i[11]}}, imm12i })};
            15: registers_data_wr_f = source1_reg_data + source2_reg_data;
            16: registers_data_wr_f = source_sub[31:0];
            17: registers_data_wr_f = source1_reg_data << source2_reg_data[4:0];
            18: registers_data_wr_f = source1_reg_data >> source2_reg_data[4:0];
            19: registers_data_wr_f = source1_reg_data >>> source2_reg_data[4:0];
            20: registers_data_wr_f = source1_reg_data & source2_reg_data;
            21: registers_data_wr_f = source1_reg_data | source2_reg_data;
            22: registers_data_wr_f = source1_reg_data ^ source2_reg_data;
            23: registers_data_wr_f = {imm20u, 12'h0};
            default: registers_data_wr_f = pc + 4;
        endcase
    endfunction

    always @(posedge clk) begin
        substage <= {substage[3:0], substage[4]};
    end

    always @(posedge clk1) begin
        if (error | stage_reset)
            stage <= 0;
        else begin
            if (!reset)
                start <= 0;
            else if (stage == 3)
                start <= 1;
            if (ready)
                stage <= stage + 1;
        end
    end

    always @(posedge clk2) begin
        if (reset == 0) begin
            current_instruction <= 3;
            in_interrupt <= 0;
        end
        else begin
            if (go) begin
                if (stage == 0) begin
                    if (interrupt_no != 0 && !in_interrupt) begin
                        in_interrupt <= 1;
                        current_instruction <= {interrupt_no, INT};
                    end
                    else
                        current_instruction <= data_in;
                end
                else begin
                    if (in_interrupt_clear)
                        in_interrupt <= 0;
                end
            end
        end
    end

    always @(posedge clk3) begin
        if (go)
            op_decoder_result <= current_instruction[1:0] != 2'b11 ? 8'b11000001 : op_decoder[op_id];
    end

    always @(posedge clk4) begin
        if (go)
            current_microinstruction <= microcode[{op_decoder_result[5:0], source_address[1:0], stage}];
    end

    always @(posedge clk5) begin
        if (registers_wr == 0)
            registers[dest_reg] <= registers_data_wr;
        source1_reg_data <= source1_reg == 0 ? 0 : registers[source1_reg];
        source2_reg_data <= source2_reg == 0 ? 0 : registers[source2_reg];
    end

    always @(posedge clk5) begin
        if (reset == 0) begin
            pc <= 0;
            hlt <= 0;
            error <= 0;
            wfi <= 0;
        end
        else begin
            if (go) begin
                hlt <= op_decoder_result[7];
                error <= op_decoder_result[6] || pc[1:0] != 0;
                wfi <= op_decoder_result[5:0] == 0;
                if (save_pc)
                    saved_pc <= pc + 4;
                if (set_pc)
                    pc <= pc_source_f(pc_source);
            end
        end
    end
endmodule
