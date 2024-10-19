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
    output reg [31:0] data_out,
    output wire nrd,
    output wire [3:0] nwr,
    input wire ready,
    input wire [7:0] interrupt,
    output reg [7:0] interrupt_ack = 0,
    output reg [1:0] stage = 0
);
    localparam ALU_OP_ADD   = 0;
    localparam ALU_OP_SLL   = 1;
    localparam ALU_OP_SUB   = 2;
    localparam ALU_OP_XOR   = 3;
    localparam ALU_OP_SRL   = 4;
    localparam ALU_OP_SRA   = 5;
    localparam ALU_OP_OR    = 6;
    localparam ALU_OP_AND   = 7;
    localparam ALU_OP_MUL   = 8;
    localparam ALU_OP_MULU  = 9;
    localparam ALU_OP_MULSU = 10;
    localparam ALU_OP_DIV   = 11;
    localparam ALU_OP_DIVU  = 12;
    localparam ALU_OP_REM   = 13;
    localparam ALU_OP_REMU  = 14;

    reg lb, lh, lw, lbu, lhu, alu_immediate, auipc, sb, sh, sw, alu_clk, lui, br, jalr, jal, reti, slt, sltu;
    reg wfi_;
    wire [2:0] func3_in, func3;
    wire [6:0] op, func7_in;
    wire op3, op35, op11, op19;
    reg load, store_;
    reg [3:0] store;

    reg [31:0] current_instruction;
    wire [11:0] imm12i, imm12s, imm12b;
    wire [19:0] imm20u, imm20j;
    wire [31:0] source_address;
    wire [4:0] source1_reg_in, source2_reg_in;
    wire [4:0] dest_reg;
    wire [31:0] imm12i_sign_extended, imm20u_shifted;

    reg start = 0;
    wire stop, main_clk, clk1, clk2, clk3, clk4;
    reg next_stage = 1;
    reg next_stage_alu = 1;

    reg in_interrupt = 0;
    reg [7:0] interrupt_pending = 0;
    wire [3:0] interrupt_no;

    reg [31:0] pc, saved_pc, saved_pc2;

    wire registers_wr;
    reg [31:0] registers_data_wr;

    reg [31:0] registers [0:31];
    reg [31:0] source1_reg_data, source2_reg_data;

    wire [31:0] alu_op2;
    reg [3:0] alu_op;
    wire [5:0] alu_op_id;
    reg mulhu;
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

    div d(.clk(!clk), .nrst(nreset), .dividend(source1_reg_data), .divisor(alu_op2), .start(div_start), .signed_ope(div_signed),
            .quotient(quotient), .remainder(remainder), .ready(div_ready));
`endif
`endif

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

    assign op = data_in[6:0];
    assign func3_in = data_in[14:12];
    assign func7_in = data_in[31:25];
    assign source1_reg_in = data_in[19:15];
    assign source2_reg_in = data_in[24:20];

    assign func3 = current_instruction[14:12];
    assign dest_reg = current_instruction[11:7];
    assign imm12i = current_instruction[31:20];
    assign imm12s = {current_instruction[31:25], current_instruction[11:7]};
    assign imm12b = {current_instruction[31], current_instruction[7], current_instruction[30:25], current_instruction[11:8]};
    assign imm20u = current_instruction[31:12];
    assign imm20j = {current_instruction[31], current_instruction[19:12], current_instruction[20], current_instruction[30:21]};

    assign op3 = op === 3;
    assign op11 = op === 11;
    assign op19 = op === 19;
    assign op35 = op === 35;

    assign registers_wr = store_ | br | reti | hlt | wfi_;

    // stage 2,3
    assign address = stage[1] & (load || store != 4'b1111) ? source_address : pc;
    
    assign interrupt_no = interrupt_no_f(interrupt_pending);

    assign alu_op2 = alu_immediate ? imm12i_sign_extended : source2_reg_data;

    assign z = alu_out == 0;
    assign signed_lt = !z & ((source1_reg_data[31] & !alu_op2[31]) | ((source1_reg_data[31] == alu_op2[31]) & c));

    assign imm12i_sign_extended = {{20{imm12i[11]}}, imm12i};
    assign imm20u_shifted = {imm20u, 12'h0};

    assign alu_op_id = {func3_in,op19,func7_in[5],func7_in[0]};

    assign source_address = source1_reg_data + (current_instruction[6:0] == 3 ? imm12i_sign_extended : { {20{imm12s[11]}}, imm12s });

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

    function [31:0] data_load_byte_signed(input [1:0] addr);
        case (addr)
            0: data_load_byte_signed = {{24{data_in[7]}}, data_in[7:0]};
            1: data_load_byte_signed = {{24{data_in[15]}}, data_in[15:8]};
            2: data_load_byte_signed = {{24{data_in[23]}}, data_in[23:16]};
            3: data_load_byte_signed = {{24{data_in[31]}}, data_in[31:24]};
        endcase
    endfunction

    function [31:0] data_out_byte(input [1:0] addr);
        case (addr)
            0: data_out_byte = {24'h0, source2_reg_data[7:0]};
            1: data_out_byte = {16'h0, source2_reg_data[7:0], 8'h0};
            2: data_out_byte = {8'h0, source2_reg_data[7:0], 16'h0};
            3: data_out_byte = {source2_reg_data[7:0], 24'h0};
        endcase
    endfunction

    function [31:0] data_load_byte_unsigned(input [1:0] addr);
        case (addr)
            0: data_load_byte_unsigned = {24'h0, data_in[7:0]};
            1: data_load_byte_unsigned = {24'h0, data_in[15:8]};
            2: data_load_byte_unsigned = {24'h0, data_in[23:16]};
            3: data_load_byte_unsigned = {24'h0, data_in[31:24]};
        endcase
    endfunction

    function [3:0] store_f(input [1:0] addr);
        case (addr)
            0: store_f = 4'b1110;
            1: store_f = 4'b1101;
            2: store_f = 4'b1011;
            3: store_f = 4'b0111;
        endcase
    endfunction

    always @(posedge main_clk) begin
        if (!nreset)
            next_stage_alu <= 1;
        else if (clk3 & alu_clk) begin
            case (alu_op)
                ALU_OP_SLL: alu_out <= source1_reg_data << alu_op2[4:0];
                ALU_OP_SRL: alu_out <= source1_reg_data >> alu_op2[4:0];
                ALU_OP_SRA: alu_out <= $signed(source1_reg_data) >>> alu_op2;
                ALU_OP_AND: alu_out <= source1_reg_data & alu_op2;
                ALU_OP_OR: alu_out <= source1_reg_data | alu_op2;
                ALU_OP_XOR: alu_out <= source1_reg_data ^ alu_op2;
                ALU_OP_ADD: alu_out <= source1_reg_data + alu_op2;
                ALU_OP_SUB: {c, alu_out} <= source1_reg_data - alu_op2;
`ifndef NO_MUL
                ALU_OP_MULU: {alu_out2, alu_out} <= source1_reg_data * alu_op2;
                ALU_OP_MUL: {alu_out, alu_out2} <= $signed(source1_reg_data) * $signed(alu_op2);
                ALU_OP_MULSU: {dc1, dc2, alu_out, alu_out2} <= $signed({source1_reg_data[31], source1_reg_data}) * $signed({1'b0, alu_op2});
`endif
`ifndef NO_DIV
`ifdef HARD_DIV
                ALU_OP_DIV: alu_out <= $signed(source1_reg_data) / $signed(alu_op2);
                ALU_OP_DIVU: alu_out <= source1_reg_data / alu_op2;
`else
                ALU_OP_DIV: begin
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
                ALU_OP_DIVU: begin
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
                ALU_OP_REM: alu_out <= $signed(source1_reg_data) % $signed(alu_op2);
`elsif HARD_REM_USING_DIV
                ALU_OP_REM: alu_out <= $signed(source1_reg_data) - ($signed(source1_reg_data) / $signed(alu_op2)) * $signed(alu_op2);
`else
                ALU_OP_REM: begin
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
                ALU_OP_REMU: alu_out <= source1_reg_data % alu_op2;
`elsif HARD_REM_USING_DIV
                ALU_OP_REMU: alu_out <= source1_reg_data - (source1_reg_data / alu_op2) * alu_op2;
`else
                ALU_OP_REMU: begin
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
                        saved_pc <= saved_pc2;
                        pc <= {ISR_ADDRESS, 2'b00, interrupt_no, 2'b00};
                        next_stage <= 1;
                    end
                    else begin
                        next_stage <= !wfi;
                        pc <= saved_pc2;
                    end
                end
                1: begin
                    if (ready) begin
                        current_instruction <= data_in;

                        load <= op3;
                        lb <= op3 && func3_in === 0;
                        lh <= op3 && func3_in === 1;
                        lw <= op3 && func3_in === 2;
                        lbu <= op3 && func3_in === 4;
                        lhu <= op3 && func3_in === 5;

                        alu_immediate <= op19;

                        auipc <= op == 23;

                        store_ <= op35;
                        sb <= op35 && func3_in === 0;
                        sh <= op35 && func3_in === 1;
                        sw <= op35 && func3_in === 2;

                        alu_clk <= op19 || op === 51;

                        lui <= op == 55;

                        br <= op == 99;

                        jalr <= op == 103;
                        jal <= op == 111;

                        wfi_ <= op11 && func3_in === 0;
                        reti <= op11 && func3_in === 1;
                        hlt <= op11 && func3_in === 2;

                        mulhu <= alu_op_id === 6'b011001;
                        slt <= alu_clk && func3_in == 2;
                        sltu <= alu_clk && func3_in == 3;

                        casez (alu_op_id)
                            6'b000010: alu_op <= ALU_OP_SUB;
                            6'b000001: alu_op <= ALU_OP_MUL;

                            6'b0011??: alu_op <= ALU_OP_SLL;
                            6'b001000: alu_op <= ALU_OP_SLL;
                            6'b001001: alu_op <= ALU_OP_MUL;

                            6'b0101??: alu_op <= ALU_OP_SUB;
                            6'b010000: alu_op <= ALU_OP_SUB;
                            6'b010001: alu_op <= ALU_OP_MULSU;

                            6'b0111??: alu_op <= ALU_OP_SUB;
                            6'b011000: alu_op <= ALU_OP_SUB;
                            6'b011001: alu_op <= ALU_OP_MULU;

                            6'b1001??: alu_op <= ALU_OP_XOR;
                            6'b100000: alu_op <= ALU_OP_XOR;
                            6'b100001: alu_op <= ALU_OP_DIV;

                            6'b1011??: alu_op <= ALU_OP_SRL;
                            6'b101000: alu_op <= ALU_OP_SRL;
                            6'b101010: alu_op <= ALU_OP_SRA;
                            6'b101001: alu_op <= ALU_OP_DIVU;

                            6'b1101??: alu_op <= ALU_OP_OR;
                            6'b110000: alu_op <= ALU_OP_OR;
                            6'b110001: alu_op <= ALU_OP_REM;

                            6'b1111??: alu_op <= ALU_OP_AND;
                            6'b111000: alu_op <= ALU_OP_AND;
                            6'b111001: alu_op <= ALU_OP_REMU;

                            default: alu_op <= ALU_OP_ADD;
                        endcase

                        next_stage <= 1;
                    end
                    else
                        next_stage <= 0;
                end
                2: begin
                    error <= (!lb & !lh &!lw & !lbu & !lhu & !alu_clk & !auipc & ! sb & !sh & !sw & !lui & !br & !jalr & !jal & !hlt & !wfi_ & !reti) |
                            ((lh | lhu | sh) & source_address[0]) | ((lw | sw) && source_address[1:0] != 0);
                    case (1'b1)
                        sb: data_out <= data_out_byte(source_address[1:0]);
                        sh: data_out <= source_address[1] ? {source2_reg_data[15:0], 16'h0} : {16'h0, source2_reg_data[15:0]};
                        sw: data_out <= source2_reg_data;
                    endcase
                    case (1'b1)
                        sb: store <= store_f(source_address[1:0]);
                        sh: store <= source_address[1] ? 4'b0011 : 4'b1100;
                        sw: store <= 0;
                        default: store <= 4'b1111;
                    endcase
                end
                3: begin
                    case (1'b1)
                        alu_clk: registers_data_wr <= mulhu ? alu_out2 : alu_out;
                        lb: registers_data_wr <= data_load_byte_signed(source_address[1:0]);
                        lh: registers_data_wr <= source_address[1] ? {{16{data_in[31]}}, data_in[31:16]} : {{16{data_in[15]}}, data_in[15:0]};
                        lw: registers_data_wr <= data_in;
                        lbu: registers_data_wr <= data_load_byte_unsigned(source_address[1:0]);
                        lhu: registers_data_wr <= source_address[1] ? {16'h0, data_in[31:16]} : {16'h0, data_in[15:0]};
                        sltu: registers_data_wr <= {31'h0, c};
                        slt: registers_data_wr <= {31'h0, signed_lt};
                        auipc: registers_data_wr <= pc + imm20u_shifted;
                        lui: registers_data_wr <= imm20u_shifted;
                        jalr | jal: registers_data_wr <= pc + 4;
                    endcase
                    if (ready) begin
                        next_stage <= 1;
                        case (1'b1)
                            reti: begin
                                saved_pc2 <= saved_pc;
                                in_interrupt <= 0;
                                interrupt_ack <= 0;
                            end
                            br: saved_pc2 <= pc + (condition_f(func3) ? { {19{imm12b[11]}}, imm12b, 1'b0 } : 4);
                            jalr: saved_pc2 <= source1_reg_data + imm12i_sign_extended;
                            jal: saved_pc2 <= pc + { {11{imm20j[19]}}, imm20j, 1'b0 };
                            default: saved_pc2 <= pc + 4;
                        endcase
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
