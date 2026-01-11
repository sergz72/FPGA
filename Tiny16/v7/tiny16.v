module tiny16
#(parameter
  // 8k 8 bit words RAM
  RAM_BITS = 13
)
(
    input wire clk,
    input wire nreset,
    output reg error,
    output reg hlt,
    output reg wfi,
    output reg [7:0] address,
    input wire [15:0] data_in,
    output reg [15:0] data_out,
    output wire mem_valid,
    output wire nwr,
    input wire mem_ready,
    input wire interrupt,
    output reg in_interrupt
);
    localparam MICROCODE_SIZE = 512;
    localparam MICROCODE_LENGTH = 24;

    localparam STAGE_WIDTH = 3;

    localparam ALU_OP_CLR  = 0;
    localparam ALU_OP_SET  = 1;
    localparam ALU_OP_INC  = 2;
    localparam ALU_OP_DEC  = 3;
    localparam ALU_OP_NOT  = 4;
    localparam ALU_OP_NEG  = 5;
    localparam ALU_OP_SHL  = 6;
    localparam ALU_OP_SHR  = 7;
    localparam ALU_OP_ROL  = 8;
    localparam ALU_OP_ROR  = 9;
    localparam ALU_OP_CLC  = 10;
    localparam ALU_OP_STC  = 11;

    localparam ALU_OP_MOV  = 16;
    localparam ALU_OP_ADC  = 17;
    localparam ALU_OP_ADD  = 18;
    localparam ALU_OP_SBC  = 19;
    localparam ALU_OP_SUB  = 20;
    localparam ALU_OP_AND  = 21;
    localparam ALU_OP_OR   = 22;
    localparam ALU_OP_XOR  = 23;

    localparam ALU_OP_CMP  = 30;
    localparam ALU_OP_TEST = 31;

    localparam RAM_ADDR_SOURCE_NEXT = 1;
    localparam RAM_ADDR_SOURCE_SAVED = 2;
    localparam RAM_ADDR_SOURCE_IMMEDIATE = 3;
    localparam RAM_ADDR_SOURCE_BR = 4;
    localparam RAM_ADDR_SOURCE_REGISTER = 5;
    localparam RAM_ADDR_SOURCE_PC = 6;

    localparam PC_SOURCE_NEXT = 1;
    localparam PC_SOURCE_SAVED = 2;
    localparam PC_SOURCE_IMMEDIATE = 3;
    localparam PC_SOURCE_BR = 4;
    localparam PC_SOURCE_REGISTER = 5;

    localparam REGISTERS_WR_DATA_SOURCE_ACC = 0;
    localparam REGISTERS_WR_DATA_SOURCE_DATA_IN = 1;
    localparam REGISTERS_WR_DATA_SOURCE_SRC8 = 2;
    localparam REGISTERS_WR_DATA_SOURCE_SRCOP1 = 3;
    localparam REGISTERS_WR_DATA_SOURCE_PC = 4;
    
    reg [STAGE_WIDTH - 1:0] stage;
    wire stage_reset;
    reg start;

    reg [MICROCODE_LENGTH-1:0] microcode [0:MICROCODE_SIZE-1];
    reg [MICROCODE_LENGTH-1:0] current_microcode;
    reg [7:0] current_instruction;

    reg [15:0] registers [0:255];
    reg [15:0] registers_data, registers_data2, registers_data3;
    reg [RAM_BITS - 1:0] pc, saved_pc, old_pc;
    reg [7:0] registers_wr_addr;

    wire go;

    reg [7:0] ram [0:(1<<RAM_BITS)-1];
    reg [7:0] src;
    wire dst;
    wire [15:0] src8_to_15;
    reg [RAM_BITS - 1:0] ram_addr;
    wire ram_wr;
    wire [RAM_BITS - 1:0] br_pc, pcp1;

    reg c;
    wire z, n;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    reg interrupt_request;
    wire interrupt_enter;

    reg [15:0] acc;
    reg [7:0] op1;
    wire [15:0] srcop1;
    wire [15:0] alu_src;

    wire stage_reset_, hlt_, wfi_, registers_wr, error_, io;
    wire [2:0] ram_addr_source, pc_source, registers_wr_data_source;
    wire registers_wr_source_set;

    wire [4:0] alu_op;
    wire imm8, imm16, alu_clk;

    initial begin
        $readmemh("microcode.hex", microcode);
        $readmemh("asm/code.hex", ram);
    end

    assign z = acc == 0;
    assign n = acc[15];

    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign interrupt_enter = interrupt_request & !in_interrupt;

    assign go = start & !hlt & !error;

    assign srcop1 = {src, op1};

    assign alu_op = current_instruction[4:0];
    assign imm8 = current_instruction[5];
    assign imm16 = current_instruction[6];

    assign stage_reset_ = current_microcode[0];
    assign error_ = current_microcode[1];
    assign hlt_ = current_microcode[2];
    assign wfi_ = current_microcode[3];
    assign ram_addr_source = current_microcode[6:4];
    assign pc_source = current_microcode[9:7];
    assign registers_wr = current_microcode[10];
    assign registers_wr_source_set = current_microcode[11];
    assign ram_wr = current_microcode[12];
    assign mem_valid = current_microcode[13];
    assign nwr = current_microcode[14];
    assign io = current_microcode[15];
    assign alu_clk = current_microcode[16];
    assign registers_wr_data_source = current_microcode[19:17];
    assign dst = current_microcode[20];

    assign src8_to_15 = {{8{src[7]}}, src};

    assign pcp1 = pc + 1;

    assign br_pc = condition_pass ? pc + src8_to_15[RAM_BITS - 1:0] : pcp1;

    assign alu_src = imm8 ? src8_to_15 : imm16 ? srcop1 : registers_data2;

    assign stage_reset = ((stage == 0) && ((wfi & !interrupt_request) | interrupt_enter)) || stage_reset_;

    always @(posedge clk) begin
        if (!nreset) begin
            stage <= 0;
            start <= 0;
            interrupt_request <= 0;
        end
        else if (!mem_valid | mem_ready) begin
            stage <= stage_reset ? 0 : stage + 1;
            if (stage == 7)
                start <= 1;
            if (stage_reset || stage == 7)
                interrupt_request <= interrupt;
        end
    end

    always @(negedge clk) begin
        op1 <= src;
        if (ram_wr)
            ram[ram_addr] <= dst ? registers_data3[15:8] : registers_data2[7:0];
        else
            src <= ram[ram_addr];
    end

    function [15:0] registers_wr_data_f(input [2:0] source);
        case (source)
            REGISTERS_WR_DATA_SOURCE_DATA_IN: registers_wr_data_f = data_in;
            REGISTERS_WR_DATA_SOURCE_SRC8: registers_wr_data_f = src8_to_15;
            REGISTERS_WR_DATA_SOURCE_SRCOP1: registers_wr_data_f = srcop1;
            REGISTERS_WR_DATA_SOURCE_PC: registers_wr_data_f = {{16-RAM_BITS{1'b0}}, old_pc};
            default: registers_wr_data_f = acc;
        endcase
    endfunction
        
    always @(negedge clk) begin
        if (registers_wr)
            registers[registers_wr_addr] <= registers_wr_data_f(registers_wr_data_source);
        else begin
            registers_data3 <= registers_data2;
            registers_data2 <= registers_data;
            registers_data <= registers[src];
        end
    end

    always @(negedge clk) begin
        current_microcode <= microcode[{current_instruction[7:2], stage}];
    end

    always @(posedge clk) begin
        if (io) begin
            address <= src;
            data_out <= registers_data;
        end
        if (registers_wr_source_set)
            registers_wr_addr <= src;
        if (alu_clk) begin
            case (alu_op)
                ALU_OP_MOV: acc <= alu_src;
                ALU_OP_ADD, ALU_OP_ADC: {c, acc} <= registers_data + alu_src + {16'h0, alu_op == ALU_OP_ADC ? c : 1'b0};
                ALU_OP_SUB, ALU_OP_SBC, ALU_OP_CMP: {c, acc} <= registers_data - alu_src - {16'h0, alu_op == ALU_OP_SBC ? c : 1'b0};
                ALU_OP_AND, ALU_OP_TEST: acc <= registers_data & alu_src;
                ALU_OP_OR: acc <= registers_data | alu_src;
                ALU_OP_XOR: acc <= registers_data ^ alu_src;

                ALU_OP_CLR: acc <= 0;
                ALU_OP_SET: acc <= 16'hFFFF;
                ALU_OP_INC: acc <= registers_data + 1;
                ALU_OP_DEC: acc <= registers_data - 1;
                ALU_OP_NOT: acc <= ~registers_data;
                ALU_OP_NEG: acc <= -registers_data;
                ALU_OP_SHL: {c, acc} <= registers_data << 1;
                ALU_OP_SHR: {acc, c} <= {registers_data, 1'b0} >> 1;
                ALU_OP_ROL: {c, acc} <= {registers_data, c} << 1;
                ALU_OP_ROR: {acc, c} <= {c, registers_data} >> 1;
                ALU_OP_CLC: c <= 0;
                ALU_OP_STC: c <= 1;
                
                default: begin end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!nreset) begin
            error <= 0;
            hlt <= 0;
            wfi <= 0;
            in_interrupt <= 0;
            pc <= 0;
            ram_addr <= 0;
            current_instruction <= 0;
        end
        else if (go) begin
            if (stage == 0) begin
                if (interrupt_request)
                    wfi <= 0;
                if (interrupt_enter) begin
                    ram_addr <= 3;
                    pc <= 3;
                    saved_pc <= pc;
                    in_interrupt <= 1;
                end
                current_instruction <= src;
            end
            else
                wfi <= wfi_;
            hlt <= hlt_;
            error <= error_;
            if (pc_source == PC_SOURCE_SAVED)
                in_interrupt <= 0;
            case (ram_addr_source)
                RAM_ADDR_SOURCE_NEXT: ram_addr <= ram_addr + 1;
                RAM_ADDR_SOURCE_SAVED: ram_addr <= saved_pc;
                RAM_ADDR_SOURCE_IMMEDIATE: ram_addr <= srcop1[RAM_BITS - 1:0];
                RAM_ADDR_SOURCE_BR: ram_addr <= br_pc;
                RAM_ADDR_SOURCE_REGISTER: ram_addr <= registers_data[RAM_BITS - 1:0];
                RAM_ADDR_SOURCE_PC: ram_addr <= pc;
                default: begin end
            endcase
            case (pc_source)
                PC_SOURCE_NEXT: pc <= pcp1;
                PC_SOURCE_SAVED: pc <= saved_pc;
                PC_SOURCE_IMMEDIATE: pc <= srcop1[RAM_BITS - 1:0];
                PC_SOURCE_BR: pc <= br_pc;
                PC_SOURCE_REGISTER: pc <= registers_data[RAM_BITS - 1:0];
                default: begin end
            endcase
            old_pc <= pcp1;
        end
    end

endmodule
