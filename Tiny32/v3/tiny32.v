`include "tiny32.vh"

/*

wait|stage|rd |wr |jmp|br     |alu|load|store
?   |0    |1  |1  |may be registers_wr,may be wfi, interrupt handling
?   |1    |0  |1  |instruction_load, may be wait, registers_load
0   |1    |1  |1  |instruction decode
?   |2    |1  |1  |may be alu_clk, may be wait
?   |3    |1/0|1/0|may be load/store, may be wait
0   |3    |1  |1  |set pc

*/

module tiny32
#(parameter RESET_PC = 32'h0, ISR_ADDRESS = 24'h0)
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
    output reg [7:0] interrupt_ack = 0,
    output reg [1:0] stage = 0
);
    localparam MICROCODE_WIDTH = 28;
    localparam NOP = 32'h00000013; // ADDI ZERO, 0

    reg [31:0] current_instruction = NOP;
    wire [9:0] op_id;
    wire [4:0] op;
    wire [1:0] func7;
    wire [2:0] func3;
    wire [11:0] imm12i, imm12s, imm12b;
    wire [19:0] imm20u, imm20j;
    wire [31:0] source_address_i, source_address_s;
    wire [4:0] source1_reg_in, source2_reg_in, source2_reg;
    wire [4:0] dest_reg;

    reg start = 0;
    wire stop, main_clk, clk1, clk2, clk3, clk4;
    reg next_stage = 1;
    reg next_stage_alu = 1;

    reg in_interrupt = 0;
    reg [7:0] interrupt_pending = 0;
    wire [3:0] interrupt_no;

    reg [31:0] pc, saved_pc;

    reg [31:0] data_load;

    wire [MICROCODE_WIDTH - 1:0] current_microinstruction;
    wire hlt_ , wfi_;
    wire load, set_pc;
    wire [3:0] store;
    wire [1:0] pc_source;
    wire [1:0] registers_wr_data_source;
    wire registers_wr;
    wire [31:0] registers_data_wr;
    wire err;
    wire alu_clk;
    wire [1:0] alu_op1_source;
    wire [2:0] alu_op2_source;
    wire [3:0] data_selector;

    reg [31:0] registers [0:31];
    reg [31:0] source1_reg_data, source2_reg_data;

    wire [31:0] alu_op1, alu_op2;
    wire [3:0] alu_op;
    reg [31:0] alu_out, alu_out2;

    wire z;
    reg c, dc1, dc2;
    wire signed_lt;

    wire nogo, go;

`ifndef NO_DIV
`ifndef HARD_DIV
    reg div_start = 0;
    reg div_signed = 0;
    wire div_ready;
    wire [31:0] quotient, remainder;

    div d(.clk(!clk), .nrst(nreset), .dividend(alu_op1), .divisor(alu_op2), .start(div_start), .signed_ope(div_signed),
            .quotient(quotient), .remainder(remainder), .ready(div_ready));
`endif
`endif

    instruction_decoder #(.MICROCODE_WIDTH(MICROCODE_WIDTH)) id (.instruction(current_instruction), .source_address_i(source_address_i[1:0]),
                          .source_address_s(source_address_s[1:0]), .decoded_instruction(current_microinstruction));

    assign stop = hlt | error;
    assign main_clk = stop | clk;
    assign nogo = stop | !start;
    assign go = !stop & start;

    assign clk1 = stage == 0;
    assign clk2 = stage == 1;
    assign clk3 = stage == 2;
    assign clk4 = stage == 3;

    assign nrd = nogo | !(clk2 | (load & clk4));
    assign nwr = go & clk4 ? store : 4'b1111;

    assign source1_reg_in = data_in[19:15];
    assign source2_reg_in = data_in[24:20];
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
    assign registers_wr_data_source = current_microinstruction[11:10];
    assign alu_clk = current_microinstruction[12];
    assign alu_op1_source = current_microinstruction[14:13];
    assign alu_op2_source = current_microinstruction[17:15];
    assign alu_op = current_microinstruction[21:18];
    assign data_selector = current_microinstruction[25:22];
    assign hlt_ = current_microinstruction[26];
    assign wfi_ = current_microinstruction[27];

    assign op_id = {op, func3, func7};

    // stage 2,3
    assign address = stage[1] & (load || store != 4'b1111) ? (load ? source_address_i : source_address_s) : pc;
    
    assign data_out = source2_reg_data << {data_selector[1:0], 3'b000};

    assign source_address_i = source1_reg_data + { {20{imm12i[11]}}, imm12i };
    assign source_address_s = source1_reg_data + { {20{imm12s[11]}}, imm12s };

    assign interrupt_no = interrupt_no_f(interrupt_pending);

    assign alu_op1 = alu_op1_f(alu_op1_source);
    assign alu_op2 = alu_op2_f(alu_op2_source);

    assign registers_data_wr = registers_data_wr_f(registers_wr_data_source);

    assign z = alu_out == 0;
    assign signed_lt = !z & ((alu_op1[31] & !alu_op2[31]) | ((alu_op1[31] == alu_op2[31]) & c));

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
            4: condition_f = signed_lt;
            5: condition_f = !signed_lt;
            6: condition_f = c;
            7: condition_f = !c;
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
            2: pc_source_f2 = { {20{imm12i[11]}}, imm12i };
            3: pc_source_f2 = 0;
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
            4: alu_op2_f = pc;
            5: alu_op2_f = 0;
            default: alu_op2_f = {27'h0, source2_reg};
        endcase
    endfunction

    function [31:0] data_load_f(input [3:0] source);
        case (source)
            0: data_load_f = {{24{data_load[7]}}, data_load[7:0]};
            1: data_load_f = {24'h0, data_load[7:0]};
            2: data_load_f = {{24{data_load[15]}}, data_load[15:8]};
            3: data_load_f = {24'h0, data_load[15:8]};
            4: data_load_f = {{24{data_load[23]}}, data_load[23:16]};
            5: data_load_f = {24'h0, data_load[23:16]};
            6: data_load_f = {{24{data_load[31]}}, data_load[31:24]};
            7: data_load_f = {24'h0, data_load[31:24]};
            8: data_load_f = {{16{data_load[15]}}, data_load[15:0]};
            9: data_load_f = {16'h0, data_load[15:0]};
            10: data_load_f = {{16{data_load[31]}}, data_load[31:16]};
            11: data_load_f = {16'h0, data_load[31:16]};
            default: data_load_f = data_load;
        endcase
    endfunction

    function [31:0] registers_data_wr_f(input [1:0] source);
        case (source)
            0: registers_data_wr_f = data_load_f(data_selector);
            1: registers_data_wr_f = alu_out;
            2: registers_data_wr_f = {31'h0, c};
            3: registers_data_wr_f = {31'h0, signed_lt};
        endcase
    endfunction

    always @(posedge main_clk) begin
        if (!nreset)
            next_stage_alu <= 1;
        else if (clk3 & alu_clk) begin
            case (alu_op)
                0: alu_out <= alu_op1 << alu_op2;
                1: alu_out <= alu_op1 >> alu_op2;
                2: alu_out <= $signed(alu_op1) >>> alu_op2;
                3: alu_out <= alu_op1 & alu_op2;
                4: alu_out <= alu_op1 | alu_op2;
                5: alu_out <= alu_op1 ^ alu_op2;
                6: alu_out <= alu_op1 + alu_op2;
                7: {c, alu_out} <= alu_op1 - alu_op2;
`ifndef NO_MUL
                8: {alu_out2, alu_out} <= alu_op1 * alu_op2;
                9: {alu_out, alu_out2} <= $signed(alu_op1) * $signed(alu_op2);
                10: {dc1, dc2, alu_out, alu_out2} <= $signed({alu_op1[31], alu_op1}) * $signed({1'b0, alu_op2});
                11: {alu_out, alu_out2} <= alu_op1 * alu_op2;
`endif
`ifndef NO_DIV
`ifdef HARD_DIV
                12: alu_out <= $signed(alu_op1) / $signed(alu_op2);
                13: alu_out <= alu_op1 / alu_op2;
`else
                12: begin
                    if (next_stage_alu) begin
                        div_signed <= 1;
                        next_stage_alu <= 0;
                        div_start <= 1;
                    end
                    else begin
                        next_stage_alu <= div_ready;
                        alu_out <= quotient;
                        div_start <= 0;
                    end
                end
                13: begin
                    if (next_stage_alu) begin
                        div_signed <= 0;
                        next_stage_alu <= 0;
                        div_start <= 1;
                    end
                    else begin
                        next_stage_alu <= div_ready;
                        alu_out <= quotient;
                        div_start <= 0;
                    end
                end
`endif
`ifdef HARD_REM
                14: alu_out <= $signed(alu_op1) % $signed(alu_op2);
`elsif HARD_REM_USING_DIV
                14: alu_out <= $signed(alu_op1) - ($signed(alu_op1) / $signed(alu_op2)) * $signed(alu_op2);
`else
                14: begin
                    if (next_stage_alu) begin
                        div_signed <= 1;
                        next_stage_alu <= 0;
                        div_start <= 1;
                    end
                    else begin
                        next_stage_alu <= div_ready;
                        alu_out <= remainder;
                        div_start <= 0;
                    end
                end
`endif
`ifdef HARD_REM
                15: alu_out <= alu_op1 % alu_op2;
`elsif HARD_REM_USING_DIV
                15: alu_out <= alu_op1 - (alu_op1 / alu_op2) * alu_op2;
`else
                15: begin
                    if (next_stage_alu) begin
                        div_signed <= 0;
                        next_stage_alu <= 0;
                        div_start <= 1;
                    end
                    else begin
                        next_stage_alu <= div_ready;
                        alu_out <= remainder;
                        div_start <= 0;
                    end
                end
`endif
`endif
                default: alu_out <= 0;
            endcase
        end
    end

    always @(negedge main_clk) begin
        if (!nreset) begin
            start <= 0;
            interrupt_pending <= 0;
        end
        else begin
            interrupt_pending <= interrupt;
            if (stage == 3)
                start <= 1;
            if (next_stage & next_stage_alu)
                stage <= stage + 1;
        end
    end

    always @(posedge main_clk) begin
        if (!nreset) begin
            current_instruction <= NOP;
            in_interrupt <= 0;
            interrupt_ack <= 0;
            pc <= RESET_PC;
            wfi <= 0;
            next_stage <= 1;
            hlt <= 0;
            error <= 0;
        end
        else if (start) begin
            case (stage)
                0: begin
                    error <= pc[1:0] != 0;
                    if (interrupt_no != 0 && !in_interrupt) begin
                        in_interrupt <= 1;
                        interrupt_ack <= interrupt_pending;
                        wfi <= 0;
                        saved_pc <= pc;
                        pc <= {ISR_ADDRESS, 2'b00, interrupt_no, 2'b00};
                        next_stage <= 1;
                    end
                    else
                        next_stage <= !wfi;
                end
                1: begin
                    if (ready) begin
                        current_instruction <= data_in;
                        next_stage <= 1;
                    end
                    else
                        next_stage <= 0;
                end
                2: begin
                    hlt <= hlt_;
                    error <= err;
                end
                3: begin
                    if (ready) begin
                        data_load <= data_in;
                        next_stage <= 1;

                        if (set_pc) begin
                            if (pc_source == 2'b11) begin // reti command
                                in_interrupt <= 0;
                                interrupt_ack <= 0;
                            end
                            pc <= pc_source_f1(pc_source) + pc_source_f2(pc_source);
                        end
                        else
                            pc <= pc + 4;
                    end
                    else
                        next_stage <= 0;
                    wfi <= wfi_;
                end
            endcase
        end
    end

    always @(posedge main_clk) begin
        if (clk1 & !registers_wr)
            registers[dest_reg] <= registers_data_wr;
        else if (clk2) begin
            source1_reg_data <= source1_reg_in == 0 ? 0 : registers[source1_reg_in];
            source2_reg_data <= source2_reg_in == 0 ? 0 : registers[source2_reg_in];
        end
    end
endmodule
