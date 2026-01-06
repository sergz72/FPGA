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
    output wire [15:0] address,
    input wire [15:0] data_in,
    output wire [15:0] data_out,
    output wire mem_valid,
    output wire nwr,
    input wire mem_ready,
    input wire interrupt,
    output reg in_interrupt
);
    localparam MICROCODE_SIZE = 512;
    localparam MICROCODE_LENGTH = 32;

    localparam SP = 127;

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

    localparam SRC_ADDR_SOURCE_NEXT = 1;
    localparam SRC_ADDR_SOURCE_SAVED = 2;
    localparam SRC_ADDR_SOURCE_IMMEDIATE = 3;

    localparam PC_SOURCE_NEXT = 1;
    localparam PC_SOURCE_SAVED = 2;
    localparam PC_SOURCE_IMMEDIATE = 3;

    localparam REGISTERS_WR_SOURCE_OP1 = 1;
    localparam REGISTERS_WR_SOURCE_SRC = 2;
    
    reg [STAGE_WIDTH - 1:0] stage;
    reg stage_reset;
    reg start;

    reg [MICROCODE_LENGTH-1:0] microcode [0:MICROCODE_SIZE-1];
    reg [MICROCODE_LENGTH-1:0] current_microcode;
    reg [7:0] current_instruction;

    reg [15:0] registers [0:127];
    reg [15:0] registers_data, registers_data2;
    reg [15:0] pc, saved_pc, sp;
    reg [6:0] registers_wr_addr;

    wire go;

    reg [7:0] ram [0:(1<<RAM_BITS)-1];
    reg [7:0] src, dst;
    reg [RAM_BITS - 1:0] src_addr, dst_addr;
    wire ram_wr;

    reg c;
    wire z, n;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    reg interrupt_request;
    wire interrupt_enter;

    reg [15:0] acc;
    reg [7:0] op1, op2;
    wire [15:0] op12;
    wire [15:0] alu_src;

    wire stage_reset_, hlt_, wfi_, registers_wr, error_;
    wire [1:0] src_addr_source, pc_source, registers_wr_source;

    wire [4:0] alu_op;
    wire imm8, imm16, is_alu_op;

    wire mem_valid_;

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

    assign op12 = {op1, op2};

    assign alu_op = current_instruction[4:0];
    assign imm8 = current_instruction[5];
    assign imm16 = current_instruction[6];
    assign is_alu_op = current_instruction[7];

    assign stage_reset_ = current_microcode[0];
    assign error_ = current_microcode[1];
    assign hlt_ = current_microcode[2];
    assign wfi_ = current_microcode[3];
    assign src_addr_source = current_microcode[5:4];
    assign pc_source = current_microcode[7:6];
    assign registers_wr = current_microcode[8];
    assign registers_wr_source = current_microcode[10:9];
    assign ram_wr = current_microcode[11];
    assign mem_valid = current_microcode[12];
    assign nwr = current_microcode[13];

    assign alu_src = imm8 ? {{8{op1[7]}}, op1} : imm16 ? op12 : registers_data2;

    always @(posedge clk) begin
        if (!nreset) begin
            stage <= 0;
            start <= 0;
            interrupt_request <= 0;
        end
        else if (!mem_valid | mem_ready) begin
            stage <= stage_reset | stage_reset_ ? 0 : stage + 1;
            if (stage == 7)
                start <= 1;
            if (stage_reset || stage_reset_ || stage == 7)
                interrupt_request <= interrupt;
        end
    end

    always @(negedge clk) begin
        op2 <= op1;
        op1 <= src;
        if (ram_wr)
            ram[dst_addr] <= dst;
        else
            src <= ram[src_addr];
    end

    always @(negedge clk) begin
        if (registers_wr)
            registers[registers_wr_addr] <= acc;
        else begin
            sp <= registers[SP];
            registers_data2 <= registers_data;
            registers_data <= registers[src[6:0]];
        end
    end

    always @(negedge clk) begin
        current_microcode <= microcode[{current_instruction[7:2], stage}];
    end

    always @(posedge clk) begin
        if (!nreset) begin
            error <= 0;
            hlt <= 0;
            stage_reset <= 0;
            pc <= 0;
            src_addr <= 0;
            current_instruction <= 0;
        end
        else if (go) begin
            if (stage == 0) begin
                stage_reset <= (wfi & !interrupt_request) | interrupt_enter;
                if (interrupt_request)
                    wfi <= 0;
                if (interrupt_enter) begin
                    src_addr <= 3;
                    pc <= 3;
                    saved_pc <= pc;
                    in_interrupt <= 1;
                end
                current_instruction <= src;
                if (mem_ready)
                    mem_valid <= 0;
            end
            hlt <= hlt_;
            wfi <= wfi_;
            error <= error_;
            case (src_addr_source)
                SRC_ADDR_SOURCE_NEXT: src_addr <= src_addr + 1;
                SRC_ADDR_SOURCE_SAVED: src_addr <= saved_pc[RAM_BITS-1:0];
                SRC_ADDR_SOURCE_IMMEDIATE: src_addr <= op12[RAM_BITS-1:0];
                default: begin end
            endcase
            case (pc_source)
                PC_SOURCE_NEXT: pc <= pc + 1;
                PC_SOURCE_SAVED: pc <= saved_pc;
                PC_SOURCE_IMMEDIATE: pc <= op12;
                default: begin end
            endcase
            case (registers_wr_source)
                REGISTERS_WR_SOURCE_OP1: registers_wr_addr <= op1[6:0];
                REGISTERS_WR_SOURCE_SRC: registers_wr_addr <= src[6:0];
                default: registers_wr_addr <= 0;
            endcase
            if (is_alu_op) begin
                case (alu_op)
                    ALU_OP_MOV: acc <= alu_src;
                    ALU_OP_ADD, ALU_OP_ADC: {acc, c} <= registers_data + alu_src + (alu_op == ALU_OP_ADD ? adc ? c : 0);
                    ALU_OP_SUB, ALU_OP_SBC, ALU_OP_CMP: {acc, c} <= registers_data - alu_src - (alu_op == ALU_OP_SBC ? c : 0);
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
                    ALU_OP_SHR: {acc, c} <= registers_data >> 1;
                    ALU_OP_ROL: {c, acc} <= {registers_data, c} << 1;
                    ALU_OP_ROR: {acc, c} <= {c, registers_data} >> 1;
                    default: begin end
                endcase
            end
        end
    end

endmodule
