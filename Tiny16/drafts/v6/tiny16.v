`include "tiny16.vh"
module tiny16
#(parameter
  // 4k 16 bit words RAM
  RAM_BITS = 12
)
(
    input wire clk,
    input wire nreset,
    output reg hlt = 0,
    output reg wfi = 0,
    output wire [15:0] address,
    input wire [15:0] data_in,
    output wire [15:0] data_out,
    output reg mem_valid = 0,
    output wire nwr,
    input wire mem_ready,
    input wire interrupt,
    output reg in_interrupt = 0
);
    localparam STAGE_WIDTH = 4;
    localparam EIGHT_TO_RAM_BITS = RAM_BITS - 8;
    localparam REGISTER_BITS = 4;

    localparam ALU_OP_ADC  = 0;
    localparam ALU_OP_ADD  = 1;
    localparam ALU_OP_SBC  = 2;
    localparam ALU_OP_SUB  = 3;
    localparam ALU_OP_CMP  = 4;
    localparam ALU_OP_AND  = 5;
    localparam ALU_OP_TEST = 6;
    localparam ALU_OP_OR   = 7;
    localparam ALU_OP_XOR  = 8;
    localparam ALU_OP_SHL  = 9;
    localparam ALU_OP_SHR  = 10;
    localparam ALU_OP_ROL  = 11;
    localparam ALU_OP_ROR  = 12;
    localparam ALU_OP_MUL  = 15;

    localparam NOP = 16'h4400; // mov A, A

    reg [STAGE_WIDTH - 1:0] stage = 1;
    reg stage_reset = 0;

    reg [15:0] current_instruction;
    reg [15:0] registers [0:(1 << REGISTER_BITS) - 1];
    reg [15:0] acc;
`ifdef NUL
    reg [15:0] acc2;
`endif    
    reg [15:0] pc, saved_pc, sp;
    reg start = 0;
    wire [REGISTER_BITS - 1:0] src_reg, dst_reg, src_reg2;
    reg [15:0]  reg_src, reg_src2;
    reg registers_wr;
    reg [REGISTER_BITS - 1:0] registers_wr_addr;
    reg [15:0] registers_wr_data;
    wire [15:0] spm1;

    wire [2:0] opcode;
    wire [6:0] opcode7;
    wire [1:0] opcode2;
    wire [12:0] offset13;
    wire [8:0] offset9;
    wire [5:0] alu_data6;
    wire [7:0] addr8;
    wire [3:0] alu_op;
    wire br, jmp, movi, movrr, aluop, aluopi, call, movmr, movrm, in, out, halt, wfi_, ret, reti, loadsp;
    wire push, pop;
`ifdef RCALL
    wire rcall;
`endif        
`ifdef LOADPC
    wire loadpc;
`endif        
    wire go;

    reg [15:0] ram [0:(1<<RAM_BITS)-1];
    reg [RAM_BITS - 1:0] src_addr, dst_addr;
    reg [15:0] src, dst;
    reg ram_wr;

    reg c;
    wire z, n;

    wire [2:0] condition, condition_temp;
    wire condition_neg, condition_pass;

    reg alu_clk;
    wire [15:0] alu_src;

    reg interrupt_request = 0;
    wire interrupt_enter;

    initial begin
        $readmemh("asm/code.hex", ram);
    end

    assign z = acc == 0;
    assign n = acc[15];

    assign opcode = current_instruction[15:13];
    assign opcode7 = current_instruction[15:9];
    assign opcode2 = current_instruction[15:14];
    assign offset13 = current_instruction[12:0];
    assign offset9 = current_instruction[12:4];
    assign condition = current_instruction[2:0];
    assign condition_neg = current_instruction[3];
    assign src_reg = src[REGISTER_BITS*2-1:REGISTER_BITS];
    assign src_reg2 = src[REGISTER_BITS-1:0];
    assign dst_reg = current_instruction[REGISTER_BITS-1:0];
    assign addr8 = current_instruction[11:4];
    assign alu_op = current_instruction[11:8];
    assign alu_data6 = {current_instruction[13:12], current_instruction[7:4]};

    assign condition_temp = condition & {c, z, n};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    assign nwr = in;
    assign address = reg_src;
    assign data_out = reg_src2;

    assign alu_src = aluopi ? {{10{alu_data6[5]}}, alu_data6} : reg_src;

    assign spm1 = sp - 1;

    assign interrupt_enter = interrupt_request & !in_interrupt;

    // format |3'h0|offset,9bit|condition,4bit|
    assign br = opcode == 0;
    // format |3'h1|offset,13bit|
    assign jmp = opcode == 1;
    // format |3'h2|0000|9'h?|
    assign halt = opcode7 == 7'h20;
    // format |3'h2|0001|9'h?|
    assign wfi_ = opcode7 == 7'h21;
    // format |3'h2|0010|?|src,4bit|dst,4bit|
    assign movrr = opcode7 == 7'h22;
    // format |3'h2|0011|9'h?|
    assign ret = opcode7 == 7'h23;
    // format |3'h2|0100|9'h?|
    assign reti = opcode7 == 7'h24;
    // format |3'h2|0101|5'h?|src,4bit|
    assign loadsp = opcode7 == 7'h25;
    // format |3'h2|0110|?|src,4bit|4'h?|
    assign push = opcode7 == 7'h26;
    // format |4'h2|0111|5'h?|src,4bit|
    assign pop = opcode7 == 7'h27;
    // format |3'h2|1000|src,4bit|dst,4bit|
    assign movmr = opcode7 == 7'h28;
    // format |3'h2|1001|src,4bit|dst,4bit|
    assign movrm = opcode7 == 7'h29;
    // format |3'h2|1010|addr_reg,4bit|dst,4bit|
    assign in = opcode7 == 7'h2A;
    // format |4'hA|1011|addr_reg,4bit|src,4bit|
    assign out = opcode7 == 7'h2B;
`ifdef LOADPC
    // format |3'h2|1100|5'h?|src,4bit|
    assign loadpc = opcode7 == 7'h2C;
`endif    
`ifdef RCALL
    // format |3'h2|1101|5'h?|src,4bit|
    assign rcall = opcode7 == 7'h2D;
`endif    
    // format |3'h3|?|alu_op,4bit|src,4bit|dst,4bit|
    assign aluop = opcode == 3;
    // format |3'h4|offset,13bit|
    assign call = opcode == 4;
    // format |3'h5|addr,8bit|dst,4bit|
    assign movi = opcode == 5;
    // format |2'h3|data,2bit|alu_op,4bit|data,4bit|dst,4bit|
    assign aluopi = opcode2 == 3;

    assign go = start & !hlt;

    always @(negedge clk) begin
        if (!nreset) begin
            stage <= 1;
            start <= 0;
        end
        else if (stage_reset)
            stage <= 1;
        else begin
            if (stage[STAGE_WIDTH-1])
                start <= 1;
            stage <= {stage[STAGE_WIDTH - 2:0], stage[STAGE_WIDTH - 1]};
        end
    end

    always @(negedge clk) begin
        if (ram_wr)
            ram[dst_addr] <= dst;
        else
            src <= ram[src_addr];
    end

    always @(negedge clk) begin
        if (alu_clk) begin
            case (alu_op)
                ALU_OP_ADD,ALU_OP_ADC: {c, acc} <= alu_src + reg_src2 + {16'h0, alu_op == ALU_OP_ADC ? c : 1'b0};
                ALU_OP_SUB,ALU_OP_SBC,ALU_OP_CMP: {c, acc} <= alu_src - reg_src2 - {16'h0, alu_op == ALU_OP_SBC ? c : 1'b0};
                ALU_OP_AND,ALU_OP_TEST: acc <= alu_src & reg_src2;
                ALU_OP_OR: acc <= alu_src | reg_src2;
                ALU_OP_XOR: acc <= alu_src ^ reg_src2;
                ALU_OP_SHL,ALU_OP_ROL: {c, acc} <= {alu_src, alu_op == ALU_OP_ROL ? c : 1'b0};
                ALU_OP_SHR,ALU_OP_ROR: {acc, c} <= {alu_op == ALU_OP_ROR ? c : 1'b0, alu_src[14:0]};
`ifdef MUL
                ALU_OP_MUL: {acc2, acc} <= alu_src * reg_src2;
`endif
            endcase
        end
    end

    always @(negedge clk) begin
        interrupt_request <= nreset ? interrupt : 0;
    end

    always @(posedge clk) begin
        if (!nreset) begin
            pc <= 0;
            current_instruction <= NOP;
            hlt <= 0;
            stage_reset <= 0;
            ram_wr <= 0;
            mem_valid <= 0;
            alu_clk <= 0;
            registers_wr <= 0;
        end
        else if (go) begin
            case (stage)
                1: begin
                    if ((mem_valid & !mem_ready) | (wfi & !interrupt_request)) begin
                        stage_reset <= 1;
                    end
                    else begin
                        wfi <= 0;
                        if (registers_wr)
                            registers[registers_wr_addr] <= in ? data_in : registers_wr_data;
                        src_addr <= interrupt_enter ? 1 : pc[RAM_BITS - 1:0];
                        if (interrupt_enter) begin
                            pc <= 1;
                            saved_pc <= pc;
                            in_interrupt <= 1;
                        end
                        stage_reset <= 0;
                        ram_wr <= 0;
                        mem_valid <= 0;
                        registers_wr <= 0;
                    end
                end
                2: begin
                    current_instruction <= src;
                    reg_src <= registers[src_reg];
                    reg_src2 <= registers[src_reg2];
                end
                4: begin
                    mem_valid <= in | out;
                    src_addr <= ret ? sp[RAM_BITS-1:0] : (movi ? {{EIGHT_TO_RAM_BITS{1'h0}}, addr8} : reg_src[RAM_BITS-1:0]);
                    registers_wr_addr <= dst_reg;
                    registers_wr <= movrr | in;
`ifdef RCALL                    
                    ram_wr <= movrm | call | rcall | push;
`else
                    ram_wr <= movrm | call | push;
`endif                    
                    dst <= movrm | push ? reg_src : pc;
                    dst_addr <= movrm ? reg_src2[RAM_BITS-1:0] : spm1[RAM_BITS-1:0];
`ifdef LOADPC
                    pc <= rcall | loadpc ? reg_src2 : (jmp | call ? pc + { {3{offset13[12]}}, offset13 } : (br & condition_pass ? pc + { {7{offset9[8]}}, offset9 } : pc + 1));
`else
`ifdef RCALL
                    pc <= rcall ? reg_src2 : (jmp | call ? pc + { {3{offset13[12]}}, offset13 } : (br & condition_pass ? pc + { {7{offset9[8]}}, offset9 } : pc + 1));
`else                    
                    pc <= jmp | call ? pc + { {3{offset13[12]}}, offset13 } : (br & condition_pass ? pc + { {7{offset9[8]}}, offset9 } : pc + 1);
`endif
`endif
                    case (1'b1)
`ifdef RCALL
                        call | rcall | push: sp <= spm1;
`else                        
                        call | push: sp <= spm1;
`endif
                        halt: hlt <= 1;
                        wfi_: wfi <= 1;
                        movrr: registers_wr_data <= reg_src;
                        aluop | aluopi: alu_clk <= 1;
                        loadsp: sp <= reg_src2;
                    endcase
                    stage_reset <= halt | jmp | wfi_ | br | movrr | movrm | out | in | call | loadsp | push | (aluop && ((alu_op == ALU_OP_CMP) || (alu_op == ALU_OP_TEST)))
`ifdef RCALL
                    | rcall
`endif                    
`ifdef LOADPC
                    | loadpc
`endif
                    ;                    
                end
                8: begin
                    registers_wr_addr <= dst_reg;
                    registers_wr <= movmr | aluop | aluopi | movi | pop;
                    if (ret | pop)
                        sp <= sp + 1;
                    case (1'b1)
                        ret: pc <= src;
                        reti: begin
                            pc <= saved_pc;
                            in_interrupt <= 0;
                        end
                        movmr | movi | pop: registers_wr_data <= src;
                        aluop | aluopi: registers_wr_data <= acc;
                    endcase
                    alu_clk <= 0;
                end
            endcase
        end
    end
endmodule
