`include "tiny32.vh"

module tiny32
#(parameter
  // 1k 32 bit words RAM
  RAM_BITS = 10,
  // 1k 32 bit words ROM
  ROM_BITS = 10
)
(
    input wire clk,
    input wire nreset,
    output reg hlt,
    output reg error,
    output reg wfi,
    output reg [31:0] io_address,
    input wire [31:0] io_data_in,
    output reg [31:0] io_data_out,
    output reg io_req,
    output reg io_nwr,
    input wire io_ready,
    input wire [7:0] interrupt,
    output reg [7:0] interrupt_ack
);
    localparam OP_LOAD    = 3;
    localparam OP_SPECIAL = 11;
    localparam OP_ALU19   = 19;
    localparam OP_AUIPC   = 23;
    localparam OP_STORE   = 35;
    localparam OP_ALU51   = 51;
    localparam OP_LUI     = 55;
    localparam OP_BR      = 99;
    localparam OP_JALR    = 103;
    localparam OP_JAL     = 111;

    localparam FUNC3_WFI  = 0;
    localparam FUNC3_RETI = 1;
    localparam FUNC3_HLT  = 2;
    localparam FUNC3_IN   = 3;
    localparam FUNC3_OUT  = 4;

    localparam FUNC3_SLB = 0;
    localparam FUNC3_SLH = 1;
    localparam FUNC3_SLW = 2;
    localparam FUNC3_LBU = 4;
    localparam FUNC3_LHU = 5;

    localparam STAGE_WIDTH = 4;

    localparam MEMORY_SELECTOR_START_BIT = 30;
    localparam RESET_PC = 32'h40000000;
    localparam ISR_ADDRESS = 24'h400000;

    reg [STAGE_WIDTH-1:0] stage;
    reg start;
    reg stage_reset;

    reg [31:0] current_instruction;
    wire [6:0] op, op_in, func7;
    wire [2:0] func3_in, func3;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    wire rom_selected, ram_selected;
    wire enter_interrupt;
    wire [31:0] mem_rdata;
    reg [3:0] mem_nwr;
    wire [ROM_BITS-1:0] rom_address;
    wire [RAM_BITS-1:0] ram_address;
    reg [31:0] rom_rdata, ram_rdata, data_out, mem_data_saved;

    reg in_interrupt;
    reg [3:0] interrupt_no;
    wire [31:0] source_address, isr_address;

    reg [31:0] pc, saved_pc;
    wire [31:0] address;

    reg registers_wr;
    reg [31:0] registers_data_wr;
    reg [31:0] registers [0:31];
    reg [31:0] source1_reg_data, source2_reg_data;
    wire [4:0] source1_reg, source2_reg;
    wire [4:0] dest_reg;

    wire [11:0] imm12i, imm12s, imm12b;
    wire [19:0] imm20u_in, imm20j_in;
    wire [31:0] imm12i_sign_extended, imm20u_shifted_in;

    wire [31:0] alu_op2, acc;
    wire z, c, signed_lt;
    reg dc1, dc2;
    reg [31:0] alu_out2;

    reg load_store;

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    assign op_in = rom_rdata[6:0];
    assign op = current_instruction[6:0];
    assign func3_in = mem_rdata[14:12];
    assign func3 = current_instruction[14:12];
    assign func7 = current_instruction[31:25];

    assign rom_selected = address[31:MEMORY_SELECTOR_START_BIT] === 1;
    assign ram_selected = address[31:MEMORY_SELECTOR_START_BIT] === 2;
    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];
    assign mem_rdata = rom_selected ? rom_rdata : ram_rdata;

    assign address = load_store ? source_address : pc;

    assign enter_interrupt = interrupt_no != 0 && !in_interrupt;
    assign isr_address = {ISR_ADDRESS, 2'b00, interrupt_no, 2'b00};

    assign source1_reg = mem_rdata[19:15];
    assign source2_reg = mem_rdata[24:20];
    assign dest_reg = current_instruction[11:7];

    assign imm20u_in = mem_rdata[31:12];
    assign imm20u_shifted_in = {imm20u_in, 12'h0};
    assign imm20j_in = {mem_rdata[31], mem_rdata[19:12], mem_rdata[20], mem_rdata[30:21]};
    assign imm12i = current_instruction[31:20];
    assign imm12i_sign_extended = {{20{imm12i[11]}}, imm12i};
    assign imm12s = {current_instruction[31:25], current_instruction[11:7]};
    assign imm12b = {current_instruction[31], current_instruction[7], current_instruction[30:25], current_instruction[11:8]};

    assign source_address = source1_reg_data + (current_instruction[6:0] == 3 ? imm12i_sign_extended : { {20{imm12s[11]}}, imm12s });

    assign {c, acc} = source1_reg_data - alu_op2;
    assign z = acc == 0;

    assign alu_op2 = op == OP_ALU19 ? imm12i_sign_extended : source2_reg_data;
    assign signed_lt = !z & ((source1_reg_data[31] & !alu_op2[31]) | ((source1_reg_data[31] == alu_op2[31]) & c));

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

    function [7:0] interrupt_ack_f(input [3:0] source);
        casez (source)
            0: interrupt_ack_f = 0;
            1: interrupt_ack_f = 1;
            2: interrupt_ack_f = 2;
            3: interrupt_ack_f = 4;
            4: interrupt_ack_f = 8;
            5: interrupt_ack_f = 16;
            6: interrupt_ack_f = 32;
            7: interrupt_ack_f = 64;
            default: interrupt_ack_f = 128;
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

    function [3:0] store_f(input [1:0] addr);
        case (addr)
            0: store_f = 4'b1110;
            1: store_f = 4'b1101;
            2: store_f = 4'b1011;
            3: store_f = 4'b0111;
        endcase
    endfunction

    function [31:0] data_load_byte_signed(input [1:0] addr);
        case (addr)
            0: data_load_byte_signed = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
            1: data_load_byte_signed = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
            2: data_load_byte_signed = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
            3: data_load_byte_signed = {{24{mem_rdata[31]}}, mem_rdata[31:24]};
        endcase
    endfunction

    function [31:0] data_load_byte_unsigned(input [1:0] addr);
        case (addr)
            0: data_load_byte_unsigned = {24'h0, mem_rdata[7:0]};
            1: data_load_byte_unsigned = {24'h0, mem_rdata[15:8]};
            2: data_load_byte_unsigned = {24'h0, mem_rdata[23:16]};
            3: data_load_byte_unsigned = {24'h0, mem_rdata[31:24]};
        endcase
    endfunction

    function [31:0] load_f(input [2:0] func);
        case (func)
            FUNC3_SLB: load_f = data_load_byte_signed(source_address[1:0]);
            FUNC3_SLH: load_f = source_address[1] ? {{16{mem_rdata[31]}}, mem_rdata[31:16]} : {{16{mem_rdata[15]}}, mem_rdata[15:0]};
            FUNC3_SLW: load_f = mem_rdata;
            FUNC3_LBU: load_f = data_load_byte_unsigned(source_address[1:0]);
            default: load_f = source_address[1] ? {16'h0, mem_rdata[31:16]} : {16'h0, mem_rdata[15:0]};
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
        if (!nreset)
            interrupt_no <= 0;
        else
            interrupt_no <= interrupt_no_f(interrupt);
    end

    always @(negedge clk) begin
        if (ram_selected) begin
            if (!mem_nwr[0])
                ram1[ram_address] <= data_out[7:0];
            if (!mem_nwr[1])
                ram2[ram_address] <= data_out[15:8];
            if (!mem_nwr[2])
                ram3[ram_address] <= data_out[23:16];
            if (!mem_nwr[3])
                ram4[ram_address] <= data_out[31:24];
        end
        ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        rom_rdata <= rom[rom_address];
    end

    always @(posedge clk) begin
        if (!nreset) begin
            pc <= RESET_PC;
            stage_reset <= 0;
            error <= 0;
            hlt <= 0;
            wfi <= 0;
            interrupt_ack <= 0;
            io_req <= 0;
            registers_wr <= 0;
            in_interrupt <= 0;
            io_nwr <= 1;
            mem_nwr <= 4'b1111;
            load_store <= 0;
        end
        else if (start & !error & !hlt) begin
            case (stage)
                1: begin
                    if ((io_req & !io_ready) | (wfi & !enter_interrupt)) begin
                        stage_reset <= 1;
                    end
                    else begin
                        if (registers_wr)
                            registers[dest_reg] <= io_req ? io_data_in : (op == OP_LOAD ? mem_data_saved : registers_data_wr);
                        wfi <= 0;
                        io_req <= 0;
                        io_nwr <= 1;
                        if (enter_interrupt) begin
                            in_interrupt <= 1;
                            saved_pc <= pc;
                            pc <= isr_address;
                            stage_reset <= 1;
                            registers_wr <= 0;
                            interrupt_ack <= interrupt_ack_f(interrupt_no);
                        end
                        else begin
                            error <= !rom_selected;
                            current_instruction <= rom_rdata;
                            registers_wr <= op_in == OP_AUIPC || op_in == OP_LUI || op_in == OP_JAL;
                            case (op_in)
                                OP_SPECIAL: begin
                                    case (func3_in)
                                        // wfi
                                        FUNC3_WFI: begin
                                            wfi <= 1;
                                            pc <= pc + 4;
                                            stage_reset <= 1;
                                        end
                                        // reti
                                        FUNC3_RETI: begin
                                            in_interrupt <= 0;
                                            interrupt_ack <= 0;
                                            pc <= saved_pc;
                                            stage_reset <= 1;
                                        end
                                        // hlt
                                        FUNC3_HLT: hlt <= 1;
                                        default: stage_reset <= 0;
                                    endcase
                                end
                                //auipc
                                //lui
                                OP_AUIPC, OP_LUI: begin
                                    registers_data_wr <= op_in == OP_AUIPC ? pc + imm20u_shifted_in : imm20u_shifted_in;
                                    pc <= pc + 4;
                                    stage_reset <= 1;
                                end
                                //jal
                                OP_JAL: begin
                                    registers_data_wr <= pc + 4;
                                    pc <= pc + { {11{imm20j_in[19]}}, imm20j_in, 1'b0 };
                                    stage_reset <= 1;
                                end
                                default: stage_reset <= 0;
                            endcase
                        end
                    end
                end
                2: begin
                    source1_reg_data <= source1_reg == 0 ? 0 : registers[source1_reg];
                    source2_reg_data <= source2_reg == 0 ? 0 : registers[source2_reg];
                end
                4: begin
                    pc <= op == OP_JALR ? source1_reg_data + imm12i_sign_extended :
                        (op == OP_BR && condition_f(func3) ? pc + { {19{imm12b[11]}}, imm12b, 1'b0 } : pc + 4);
                    case (op)
                        OP_LOAD, OP_STORE: begin
                            load_store <= 1;
                            if (op == OP_STORE) begin
                                case (func3)
                                    FUNC3_SLB: data_out <= data_out_byte(source_address[1:0]);
                                    FUNC3_SLH: data_out <= source_address[1] ? {source2_reg_data[15:0], 16'h0} : {16'h0, source2_reg_data[15:0]};
                                    default: data_out <= source2_reg_data;
                                endcase
                                case (func3)
                                    FUNC3_SLB: mem_nwr <= store_f(source_address[1:0]);
                                    FUNC3_SLH: mem_nwr <= source_address[1] ? 4'b0011 : 4'b1100;
                                    default: mem_nwr <= 0;
                                endcase
                            end
                        end
                        OP_SPECIAL: begin
                            if (func3 == FUNC3_IN || func3 == FUNC3_OUT) begin
                                io_nwr <= func3 == FUNC3_IN;
                                registers_wr <= func3 == FUNC3_IN;
                                io_req <= 1;
                                io_address <= source1_reg_data;
                                io_data_out <= source2_reg_data;
                                stage_reset <= 1;
                            end
                        end
                        OP_ALU19: begin
                            registers_wr <= 1;
                            stage_reset <= 1;
                            case (func3)
                                0: registers_data_wr <= source1_reg_data + imm12i_sign_extended;
                                1: registers_data_wr <= source1_reg_data << imm12i_sign_extended[4:0];
                                //slti
                                2: registers_data_wr <= {31'h0, signed_lt};
                                3: registers_data_wr <= {31'h0, c};
                                4: registers_data_wr <= source1_reg_data ^ imm12i_sign_extended;
                                5: begin
                                    case (func7)
                                        //srl
                                        7'h00: registers_data_wr <= source1_reg_data >> imm12i_sign_extended[4:0];
                                        //sra
                                        7'h20: registers_data_wr <= $signed(source1_reg_data) >>> imm12i_sign_extended[4:0];
                                        default: error <= 1;
                                    endcase
                                end
                                6: registers_data_wr <= source1_reg_data | alu_op2;
                                7: registers_data_wr <= source1_reg_data & alu_op2;
                            endcase
                        end
                        OP_ALU51: begin
                            registers_wr <= 1;
                            stage_reset <= 1;
                            case (func3)
                                0: begin
                                    case (func7)
                                        //add
                                        7'h00: registers_data_wr <= source1_reg_data + source2_reg_data;
`ifdef MUL                              // mul  
                                        7'h01: {alu_out2, registers_data_wr} <= source1_reg_data * source2_reg_data;
`endif                                  //sub
                                        7'h20: registers_data_wr <= source1_reg_data - source2_reg_data;
                                        default: error <= 1;
                                    endcase
                                end
                                1: begin
                                    case (func7)
                                        // sll
                                        7'h00: registers_data_wr <= source1_reg_data << source2_reg_data[4:0];
`ifdef MUL                              // mulh
                                        7'h01: {registers_data_wr, alu_out2} <= $signed(source1_reg_data) * $signed(source2_reg_data);
`endif
                                        default: error <= 1;
                                    endcase
                                end
                                2: begin
                                    case (func7)
                                        //slt
                                        7'h00: registers_data_wr <= {31'h0, signed_lt};
`ifdef MUL                              // mulhsu    
                                        7'h01: {dc1, dc2, registers_data_wr,alu_out2} <= $signed({source1_reg_data[31], source1_reg_data}) * $signed({1'b0, source2_reg_data});
`endif
                                        default: error <= 1;
                                    endcase
                                end
                                3: begin
                                    case (func7)
                                        //sltu
                                        7'h00: registers_data_wr <={31'h0, c};
`ifdef MUL                              // mulhu    
                                        7'h01: {registers_data_wr, alu_out2} <= source1_reg_data * source2_reg_data;
`endif
                                        default: error <= 1;
                                    endcase
                                end
                                4: begin
                                    case (func7)
                                        //xor
                                        7'h00: registers_data_wr <= source1_reg_data ^ source2_reg_data;
                                        default: error <= 1;
                                    endcase
                                end
                                5: begin
                                    case (func7)
                                        //srl
                                        7'h00: registers_data_wr <= source1_reg_data >> source2_reg_data[4:0];
                                        //sra
                                        7'h20: registers_data_wr <= $signed(source1_reg_data) >>> source2_reg_data[4:0];
                                        default: error <= 1;
                                    endcase
                                end
                                6: begin
                                    case (func7)
                                        //or
                                        7'h00: registers_data_wr <= source1_reg_data | source2_reg_data;
                                        default: error <= 1;
                                    endcase
                                end
                                7: begin
                                    case (func7)
                                        //and
                                        7'h00: registers_data_wr <= source1_reg_data & source2_reg_data;
                                        default: error <= 1;
                                    endcase
                                end
                            endcase
                        end
                        OP_BR: stage_reset <= 1;
                        OP_JALR: begin
                            registers_wr <= 1;
                            registers_data_wr <= pc + 4;
                            stage_reset <= 1;
                        end
                        default: begin end
                    endcase
                end
                8: begin
                    load_store <= 0;
                    mem_nwr <= 4'b1111;
                    mem_data_saved <= load_f(func3);
                    registers_wr <= op == OP_LOAD;
                end
            endcase
        end
    end
endmodule
