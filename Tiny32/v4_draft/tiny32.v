`include "tiny32.vh"

module tiny32
#(parameter RESET_PC = 32'h0, ISR_ADDRESS = 24'h0)
(
    input wire clk,
    input wire nreset,
    output reg hlt = 0,
    output reg error = 0,
    output wire wfi,
    output reg [31:0] address,
    input wire [31:0] data_in,
    output reg [31:0] data_out,
    output reg mem_valid = 0,
    output reg [3:0] mem_nwr,
    input wire mem_ready,
    input wire [7:0] interrupt,
    output reg [7:0] interrupt_ack = 0,
    output reg [2:0] stage = 0
);
    localparam STAGE_IREAD        = 0;
    localparam STAGE_DECODE       = 1;
    localparam STAGE_WAITNOTREADY = 2;
    localparam STAGE_WAITREADY    = 3;
    localparam STAGE_WFI          = 4;

    localparam ALU_OP_ADD   = 0;
    localparam ALU_OP_SLL   = 1;
    localparam ALU_OP_SUB   = 2;
    localparam ALU_OP_XOR   = 3;
    localparam ALU_OP_SRL   = 4;
    localparam ALU_OP_SRA   = 5;
    localparam ALU_OP_OR    = 6;
    localparam ALU_OP_AND   = 7;
    localparam ALU_OP_MUL   = 8;
    localparam ALU_OP_MULS  = 9;
    localparam ALU_OP_MULSU = 10;
    localparam ALU_OP_DIV   = 11;
    localparam ALU_OP_DIVU  = 12;
    localparam ALU_OP_REM   = 13;
    localparam ALU_OP_REMU  = 14;

    wire lb, lh, lw, lbu, lhu, alu_immediate, auipc, sb, sh, sw, alu_clk, alu_clk_no_br, lui, br, jalr, jal, reti, slt, sltu;
    wire alu_clk_no_br_slt_sltu, wfi_, hlt_;
    wire [2:0] func3;
    wire [6:0] op, func7;
    wire op3, op35, op11, op19, op99, op51, slt_op;
    wire load, store;

    reg [31:0] current_instruction;
    wire [11:0] imm12i, imm12s, imm12b;
    wire [19:0] imm20u, imm20j;
    wire [31:0] source_address, isr_address;
    wire [4:0] source1_reg_in, source2_reg_in;
    wire [4:0] dest_reg;
    wire [31:0] imm12i_sign_extended, imm20u_shifted;

    reg in_interrupt = 0;
    wire [3:0] interrupt_no;

    reg [31:0] pc, saved_pc, saved_pc2;

    reg registers_wr = 1;
    reg [31:0] registers_data_wr;

    reg [31:0] registers [0:31];
    reg [31:0] source1_reg_data, source2_reg_data;

    wire [31:0] alu_op2;
    wire [3:0] alu_op;
    wire [6:0] alu_op_id;
    wire mulhu;
    reg [31:0] alu_out, alu_out2;

    wire z;
    reg c, dc1, dc2;
    wire signed_lt;

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

    assign op = data_in[6:0];
    assign func3 = data_in[14:12];
    assign func7 = data_in[31:25];
    assign source1_reg_in = data_in[19:15];
    assign source2_reg_in = data_in[24:20];

    assign dest_reg = current_instruction[11:7];
    assign imm12i = current_instruction[31:20];
    assign imm12s = {current_instruction[31:25], current_instruction[11:7]};
    assign imm12b = {current_instruction[31], current_instruction[7], current_instruction[30:25], current_instruction[11:8]};
    assign imm20u = current_instruction[31:12];
    assign imm20j = {current_instruction[31], current_instruction[19:12], current_instruction[20], current_instruction[30:21]};

    assign op3 = op == 3;
    assign op11 = op == 11;
    assign op19 = op == 19;
    assign op35 = op == 35;
    assign op99 = op == 99;
    assign op51 = op == 51;

    assign alu_clk_no_br = op19 || op51;
    assign alu_clk_no_br_slt_sltu = alu_clk_no_br & !slt & !sltu;
    
    assign interrupt_no = interrupt_no_f(interrupt);

    assign alu_op2 = alu_immediate ? imm12i_sign_extended : source2_reg_data;

    assign z = alu_out == 0;
    assign signed_lt = !z & ((source1_reg_data[31] & !alu_op2[31]) | ((source1_reg_data[31] == alu_op2[31]) & c));

    assign imm12i_sign_extended = {{20{imm12i[11]}}, imm12i};
    assign imm20u_shifted = {imm20u, 12'h0};

    assign alu_op_id = {op99,func3,op19,func7[5],func7[0]};

    assign source_address = source1_reg_data + (current_instruction[6:0] == 3 ? imm12i_sign_extended : { {20{imm12s[11]}}, imm12s });

    assign isr_address = {ISR_ADDRESS, 2'b00, interrupt_no, 2'b00};

    assign slt_op = op19 | (op51 & !func7[5] & !func7[0]);

    assign load = op3;
    assign lb = op3 && func3 == 0;
    assign lh = op3 && func3 == 1;
    assign lw = op3 && func3 == 2;
    assign lbu = op3 && func3 == 4;
    assign lhu = op3 && func3 == 5;

    assign alu_immediate = op19;

    assign auipc = op == 23;

    assign store = op35;
    assign sb = op35 && func3 == 0;
    assign sh = op35 && func3 == 1;
    assign sw = op35 && func3 == 2;

    assign alu_clk = alu_clk_no_br | op99;

    assign lui = op == 55;

    assign br = op99;

    assign jalr = op == 103;
    assign jal = op == 111;

    assign wfi_ <= op11 && func3 == 0;
    assign reti = op11 && func3 == 1;
    assign hlt_ = op11 && func3 == 2;

    assign mulhu = alu_op_id == 7'b0011001;
    assign slt = func3 == 2 && slt_op;
    assign sltu = func3 == 3 && slt_op;

    assign alu_op = alu_op_f(alu_op_id);

    function [3:0] alu_op_f(input [6:0] source);
        casez (source)
            7'b00001??: alu_op_f = ALU_OP_ADD;
            7'b0000000: alu_op_f = ALU_OP_ADD;
            7'b0000001: alu_op_f = ALU_OP_MUL;

            7'b00011??: alu_op_f = ALU_OP_SLL;
            7'b0001000: alu_op_f = ALU_OP_SLL;
            7'b0001001: alu_op_f = ALU_OP_MULS;

            7'b0010001: alu_op_f = ALU_OP_MULSU;

            7'b0011001: alu_op_f = ALU_OP_MUL;

            7'b01001??: alu_op_f = ALU_OP_XOR;
            7'b0100000: alu_op_f = ALU_OP_XOR;
            7'b0100001: alu_op_f = ALU_OP_DIV;

            7'b0101?00: alu_op_f = ALU_OP_SRL;
            7'b0101?10: alu_op_f = ALU_OP_SRA;
            7'b0101001: alu_op_f = ALU_OP_DIVU;

            7'b01101??: alu_op_f = ALU_OP_OR;
            7'b0110000: alu_op_f = ALU_OP_OR;
            7'b0110001: alu_op_f = ALU_OP_REM;

            7'b01111??: alu_op_f = ALU_OP_AND;
            7'b0111000: alu_op_f = ALU_OP_AND;
            7'b0111001: alu_op_f = ALU_OP_REMU;

            default: alu_op_f = ALU_OP_SUB;
        endcase
    endfunction


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

    always @(posedge clk) begin
        if (!nreset)
            next_stage_alu <= 1;
        else if (start & clk3 & alu_clk) begin
            case (alu_op)
                ALU_OP_SLL: alu_out <= source1_reg_data << alu_op2[4:0];
                ALU_OP_SRL: alu_out <= source1_reg_data >> alu_op2[4:0];
                ALU_OP_SRA: alu_out <= $signed(source1_reg_data) >>> alu_op2[4:0];
                ALU_OP_AND: alu_out <= source1_reg_data & alu_op2;
                ALU_OP_OR: alu_out <= source1_reg_data | alu_op2;
                ALU_OP_XOR: alu_out <= source1_reg_data ^ alu_op2;
                ALU_OP_ADD: alu_out <= source1_reg_data + alu_op2;
                ALU_OP_SUB: {c, alu_out} <= source1_reg_data - alu_op2;
`ifndef NO_MUL
                ALU_OP_MUL: {alu_out2, alu_out} <= source1_reg_data * alu_op2;
                ALU_OP_MULS: {alu_out, alu_out2} <= $signed(source1_reg_data) * $signed(alu_op2);
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

    always @(posedge clk) begin
        if (!nreset) begin
            current_instruction <= NOP;
            in_interrupt <= 0;
            interrupt_ack <= 0;
            address <= RESET_PC;
            saved_pc2 <= RESET_PC;
            wfi <= 0;
            mem_valid <= 0;
            error <= 0;
            hlt <= 0;
            registers_wr <= 1;
        end
        else if (!error & !hlt) begin
            case (stage)
                STAGE_IREAD: begin
                    registers_wr <= 1;

                    error <= saved_pc2[1:0] != 0;
                    if (interrupt_no != 0 && !in_interrupt) begin
                        in_interrupt <= 1;
                        interrupt_ack <= interrupt_no;
                        saved_pc <= saved_pc2;
                        pc <= isr_address;
                        address <= isr_address;
                        next_stage <= 1;
                    end
                    else begin
                        pc <= saved_pc2;
                        address <= saved_pc2;
                    end
                    mem_valid <= 1;
                    mem_nwr <= 4'b1111;
                    stage <= STAGE_DECODE;
                end
                STAGE_DECODE: begin
                    if (mem_ready) begin
                        mem_valid <= 0;

                        error <= (!lb & !lh &!lw & !lbu & !lhu & !alu_clk & !auipc & ! sb & !sh & !sw & !lui & !jalr & !jal & !hlt_ & !wfi_ & !reti) |
                                ((lh | lhu | sh) & source_address[0]) | ((lw | sw) && source_address[1:0] != 0);
                        
                        current_instruction <= data_in;

                        wfi <= wfi_;
                        hlt <= hlt_;

                        registers_wr <= !(auipc | lui | jalr);

                        case (1'b1)
                            load | store: stage <= STAGE_WAITNOTREADY;
                            wfi_: stage <= STAGE_WFI;
                            auipc | lui | reti | br | jalr | jal: stage <= STAGE_IREAD;
                        endcase
                        case (1'b1)
                            auipc: registers_data_wr <= pc + imm20u_shifted;
                            lui: registers_data_wr <= imm20u_shifted;
                            jalr | jal: registers_data_wr <= pc + 4;
                        endcase
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
                end
                STAGE_WAITNOTREADY: begin
                    if (!mem_ready) begin
                        mem_valid <= 1;
                        address <= source_address;

                        case (1'b1)
                            sb: data_out <= data_out_byte(source_address[1:0]);
                            sh: data_out <= source_address[1] ? {source2_reg_data[15:0], 16'h0} : {16'h0, source2_reg_data[15:0]};
                            sw: data_out <= source2_reg_data;
                        endcase
                        case (1'b1)
                            sb: mem_nwr <= store_f(source_address[1:0]);
                            sh: mem_nwr <= source_address[1] ? 4'b0011 : 4'b1100;
                            sw: mem_nwr <= 0;
                            default: mem_nwr <= 4'b1111;
                        endcase

                        stage <= STAGE_WAITREADY;
                    end
                end
                STAGE_WAITREADY: begin
                    if (mem_ready) begin
                        mem_valid <= 0;

                        registers_wr <= store;

                        case (1'b1)
                            lb: registers_data_wr <= data_load_byte_signed(source_address[1:0]);
                            lh: registers_data_wr <= source_address[1] ? {{16{data_in[31]}}, data_in[31:16]} : {{16{data_in[15]}}, data_in[15:0]};
                            lw: registers_data_wr <= data_in;
                            lbu: registers_data_wr <= data_load_byte_unsigned(source_address[1:0]);
                            default: registers_data_wr <= source_address[1] ? {16'h0, data_in[31:16]} : {16'h0, data_in[15:0]};
                        endcase

                        stage <= STAGE_IREAD;
                    end
                end
                STAGE_WFI: begin
                    if (interrupt_no != 0)
                        stage <= STAGE_IREAD;
                end
                3: begin
                    case (1'b1)
                        alu_clk_no_br_slt_sltu: registers_data_wr <= mulhu ? alu_out2 : alu_out;
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

    always @(posedge clk) begin
        if (!registers_wr)
            registers[dest_reg] <= registers_data_wr;
        else begin
            source1_reg_data <= source1_reg_in == 0 ? 0 : registers[source1_reg_in];
            source2_reg_data <= source2_reg_in == 0 ? 0 : registers[source2_reg_in];
        end
    end
endmodule
