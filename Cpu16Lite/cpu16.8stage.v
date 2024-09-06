`include "alu.vh"

module cpu
#(parameter BITS = 16, CODE_BITS = 32, RAM_BITS = 10)
(
    input wire clk,
    input wire reset,
    input wire interrupt,
    // External flash interface
    output reg [BITS - 1:0] address,
    input wire [CODE_BITS - 1:0] data,
    output wire rd,
    // halt flag
    output reg hlt = 0,
    // error flag
    output reg error = 0,
    // IO interface
    output wire io_rd,
    output wire io_wr,
    output wire [BITS - 1:0] io_address,
    input wire [BITS - 1:0] io_data_in,
    output wire [BITS - 1:0] io_data_out,
    output reg [2:0] stage = 0,
    input wire ready
);
    localparam MICROCODE_WIDTH = 27;
    localparam RAM_ADDRESS_EXPAND_BITS = RAM_BITS - 8;
    localparam FLAGS_EXPAND_BITS = BITS - 3;

    wire clk1, clk2, clk4, clk5;
    //wire clk3, clk6, clk7;

    reg start = 0;
    
    reg [RAM_BITS - 1:0] sp;
    wire push, pop;
    reg [BITS-1:0] prev_address;

    //ALU related
    wire c, z;
    wire [BITS-1:0] alu_op1, alu_op2, alu_out;
    wire [`ALU_OPID_WIDTH - 1:0] alu_op_id;
    wire alu_clk, alu_clk_set, alu_op1_source;
    wire [1:0] alu_op2_source;

    // IO
    wire io_wr_set, io_rd_set, io_data_out_source;
    wire [1:0] io_address_source;

    // address
    wire [1:0] address_source;
    wire address_load;

    reg [CODE_BITS - 1:0] current_instruction = 0;

    reg [MICROCODE_WIDTH - 1:0] microcode [0:511];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 7;
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction2 = 0;

    // interrupt
    reg in_interrupt;
    wire int_start, in_interrupt_clear;

    // error flags
    wire hltf, errorf;

    wire condition_neg, condition_pass;
    wire [2:0] condition_temp, condition_flags;

    reg [BITS - 1:0] ram [0:(1<<RAM_BITS) - 1];
    reg [BITS - 1:0] ram_data1, ram_data2, ram_data3, ram_data4;
    wire ram_wr1_set, ram_wr2_set;
    wire ram_clk;
    wire [1:0] ram_wr1_dest;
    wire [2:0] ram_wr1_source;
    wire [1:0] ram_wr2_dest;
    wire [2:0] ram_wr2_source;
    reg ram_wr1 = 1;
    reg ram_wr2 = 1;
    wire [RAM_BITS - 1:0] ram_rd_address1, ram_rd_address2;
    wire [1:0] ram_rd_source1, ram_rd_source2, ram_rd_source3, ram_rd_source4;

    function [BITS - 1: 0] address_source_f(input [1:0] source);
        case (source)
            0: address_source_f = current_instruction[CODE_BITS - 1:BITS];
            1: address_source_f = ram_data1 + current_instruction[CODE_BITS - 1:BITS];
            2: address_source_f = ram_data3 + current_instruction[CODE_BITS - 1:BITS];
            3: address_source_f = io_data_in + current_instruction[CODE_BITS - 1:BITS];
        endcase
    endfunction

    function [RAM_BITS - 1:0] ram_wr_address1_f(input [1:0] source);
        case (source)
            0: ram_wr_address1_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[15:8]};
            1: ram_wr_address1_f = sp;
        endcase
    endfunction

    function [BITS - 1:0] ram_wr_source1_f(input [2:0] source);
        case (source)
            0: ram_wr_source1_f = alu_out;
            1: ram_wr_source1_f = current_instruction[CODE_BITS - 1:BITS]; // immediate
            2: ram_wr_source1_f = ram_data1 + {{8{1'b0}}, current_instruction[CODE_BITS - 1:24]};
            3: ram_wr_source1_f = ram_data1 + current_instruction[CODE_BITS - 1:BITS];
            4: ram_wr_source1_f = {{FLAGS_EXPAND_BITS{1'b0}}, alu_out[BITS - 1], c, z};
            5: ram_wr_source1_f = prev_address;
            default: ram_wr_source1_f = io_data_in;
        endcase
    endfunction

    function [RAM_BITS - 1:0] ram_wr_address2_f(input [1:0] source);
        case (source)
            0: ram_wr_address2_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[15:8]};
            1: ram_wr_address2_f = sp;
        endcase
    endfunction

    function [BITS - 1:0] ram_wr_source2_f(input [2:0] source);
        case (source)
            0: ram_wr_source2_f = alu_out;
            1: ram_wr_source2_f = current_instruction[CODE_BITS - 1:BITS]; // immediate
            2: ram_wr_source2_f = ram_data1 + {{8{1'b0}}, current_instruction[CODE_BITS - 1:24]};
            3: ram_wr_source2_f = ram_data1 + current_instruction[CODE_BITS - 1:BITS];
            4: ram_wr_source2_f = {{FLAGS_EXPAND_BITS{1'b0}}, alu_out[BITS - 1], c, z};
            5: ram_wr_source2_f = prev_address;
            default: ram_wr_source2_f = io_data_in;
        endcase
    endfunction

    function [RAM_BITS - 1:0] ram_rd_address1_f(input [1:0] source);
        case (source)
            0: ram_rd_address1_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[23:16]};
            1: ram_rd_address1_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[15:8]};
            default: ram_rd_address1_f = sp;
        endcase
    endfunction

    function [RAM_BITS - 1:0] ram_rd_address2_f(input [1:0] source);
        case (source)
            0: ram_rd_address2_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[31:24]};
            1: ram_rd_address2_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[23:16]};
            default: ram_rd_address2_f = sp;
        endcase
    endfunction

    function [RAM_BITS - 1:0] ram_rd_address3_f(input [1:0] source);
        case (source)
            0: ram_rd_address3_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[23:16]};
            1: ram_rd_address3_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[15:8]};
            default: ram_rd_address3_f = sp;
        endcase
    endfunction

    function [RAM_BITS - 1:0] ram_rd_address4_f(input [1:0] source);
        case (source)
            0: ram_rd_address4_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[31:24]};
            1: ram_rd_address4_f = {{RAM_ADDRESS_EXPAND_BITS{1'b0}}, current_instruction[23:16]};
            default: ram_rd_address4_f = sp;
        endcase
    endfunction

    function [BITS - 1:0] io_address_source_f(input [1:0] source);
        case (source)
            0: io_address_source_f = current_instruction[CODE_BITS - 1: 16];
            1: io_address_source_f = ram_data1 + {{8{1'b0}}, current_instruction[CODE_BITS - 1: 24]};
            default: io_address_source_f = ram_data3 + {{8{1'b0}}, current_instruction[CODE_BITS - 1: 24]};
        endcase
    endfunction

    function [BITS - 1:0] alu_op2_source_f(input [1:0] source);
        case (source)
            0: alu_op2_source_f = current_instruction[31:16];
            1: alu_op2_source_f = ram_data1;
            2: alu_op2_source_f = ram_data3;
            3: alu_op2_source_f = io_data_in;
        endcase
    endfunction

    alu #(.BITS(BITS))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .c(c), .z(z), .out(alu_out));

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    assign ram_rd_address1 = clk5 ? ram_rd_address3_f(ram_rd_source3) : ram_rd_address1_f(ram_rd_source1);
    assign ram_rd_address2 = clk5 ? ram_rd_address4_f(ram_rd_source4) : ram_rd_address2_f(ram_rd_source2);

    // instruction read start, ram write
    assign clk1 = start && stage[0] == 0 && stage[1] == 0 && stage[2] == 0;
    // instruction read, microcode read
    assign clk2 = start && stage[0] == 1 && stage[1] == 0 && stage[2] == 0;
    // ram read
    //assign clk3 = start && stage[0] == 0 && stage[1] == 1 && stage[2] == 0;
    // ram data copy
    assign clk4 = start && stage[0] == 1 && stage[1] == 1 && stage[2] == 0;
    // ram read
    assign clk5 = start && stage[0] == 0 && stage[1] == 0 && stage[2] == 1;
    // alu clk
    //assign clk6 = start && stage[0] == 1 && stage[1] == 0 && stage[2] == 1;
    // ram write
    //assign clk7 = start && stage[0] == 0 && stage[1] == 1 && stage[2] == 1;

    assign ram_clk = !hlt & start & !stage[0];
    
    assign int_start = interrupt == 1 && in_interrupt == 0;

    assign rd = error || hlt || !clk1;

    // in reset state:
    // io_rd = io_wr = 1
    // microinstruction 1
    assign io_rd_set = current_microinstruction[0];
    assign io_wr_set = current_microinstruction[1];
    assign address_load = current_microinstruction[2];
    // can be current_instruction[31:16] or registers[current_instruction[15:8]] + current_instruction[31:16]
    assign address_source = current_microinstruction[4:3];
    assign alu_clk_set = current_microinstruction[5];
    assign condition_neg = current_microinstruction[6];
    assign condition_flags = current_microinstruction[9:7];
    // can be registers[current_instruction[31:24]] or current_instruction[31:16]
    assign hltf = current_microinstruction[10];
    assign errorf = current_microinstruction[11];
    assign push = current_microinstruction[12];
    assign in_interrupt_clear = current_microinstruction[13];
    assign pop = current_microinstruction[14];
    assign ram_wr1_set = current_microinstruction[15];
    assign ram_wr2_set = current_microinstruction[16];
    assign ram_wr1_dest = current_microinstruction[18:17];
    assign ram_wr1_source = current_microinstruction[21:19];
    assign ram_wr2_dest = current_microinstruction[23:22];
    assign ram_wr2_source = current_microinstruction[26:24];
    // microinstruction 2
    assign ram_rd_source1 = current_microinstruction2[1:0];
    assign ram_rd_source2 = current_microinstruction2[3:2];
    assign ram_rd_source3 = current_microinstruction2[5:4];
    assign ram_rd_source4 = current_microinstruction2[7:6];
    assign io_data_out_source = current_microinstruction2[8];
    assign io_address_source = current_microinstruction2[10:9];
    assign alu_op1_source = current_microinstruction2[11];
    assign alu_op2_source = current_microinstruction2[13:12];

    assign alu_clk = alu_clk_set & clk5;
    assign alu_op_id = current_instruction[`ALU_OPID_WIDTH - 1:0];
    assign alu_op1 = alu_op1_source ? ram_data3 : ram_data1;
    assign alu_op2 = alu_op2_source_f(alu_op2_source);
    
    assign io_data_out = io_data_out_source ? ram_data3 : ram_data1;
    assign io_address = io_address_source_f(io_address_source);
    assign io_rd = io_rd_set | !(clk1 | clk4);
    assign io_wr = io_wr_set | !clk4;

    assign condition_temp = condition_flags & {c, z, alu_out[15]};
    assign condition_pass = (condition_temp[0] | condition_temp[1] | condition_temp[2]) ^ condition_neg;

    always @(negedge clk) begin
        if (error != 0)
            stage <= 0;
        else begin
            start <= reset;
            if (reset && ready) begin
                if (stage == 6) begin
                    start <= 1;
                    stage <= 0;
                end
                else
                    stage <= stage + 1;
            end
        end
    end

    always @(posedge clk2) begin
        if (error == 0 && hlt == 0) begin
            current_microinstruction <= microcode[{current_instruction[7:0], 1'b0}];
            current_microinstruction2 <= microcode[{current_instruction[7:0], 1'b1}];
        end
    end

    always @(posedge ram_clk) begin
        if (!ram_wr2)
            ram[ram_wr_address2_f(ram_wr2_dest)] <= ram_wr_source2_f(ram_wr2_source);
        else if (!ram_wr1)
            ram[ram_wr_address1_f(ram_wr1_dest)] <= ram_wr_source1_f(ram_wr1_source);
        else begin
            ram_data3 <= ram[ram_rd_address1];
            ram_data4 <= ram[ram_rd_address2];
        end
    end

    always @(posedge clk) begin
        if (reset == 0) begin
            in_interrupt <= 0;
            sp <= 0;
            address <= 0;
            hlt <= 0;
            error <= 0;
            current_instruction <= 0;
        end
        else if (ready == 1) begin
            if (start == 1 && error == 0) begin
                case (stage)
                    // instruction read
                    0: begin
                        if (int_start == 0) begin
                            if (hlt == 0)
                                current_instruction <= data;
                        end
                        else begin
                            current_instruction <= 'h00010020; // call 1
                            in_interrupt <= 1;
                            address <= address - 1;
                            hlt <= 0;
                        end
                    end
                    // microcode read
                    1: begin
                        ram_wr1 <= 1;
                        ram_wr2 <= 1;
                    end
                    //2: ram read
                    //ram data copy
                    3: begin
                        ram_data1 <= ram_data3;
                        ram_data2 <= ram_data4;
                    end
                    //4: ram read
                    // alu clk
                    5: begin
                        if (hlt == 0) begin
                            hlt <= hltf;
                            error <= errorf;
                            ram_wr1 <= !ram_wr1_set;
                            if ((address_load == 0) || (condition_pass == 0))
                                address <= address + 1;
                            else begin
                                if (pop) begin
                                    address <= ram_data1;
                                    sp <= sp + 1;
                                    if (in_interrupt_clear)
                                        in_interrupt <= 0;
                                end
                                else begin
                                    if (push) begin
                                        prev_address <= address + 1;
                                        sp <= sp - 1;
                                    end
                                    address <= address_source_f(address_source);
                                end
                            end
                        end
                    end
                    6: if (hlt == 0)
                            ram_wr2 <= !ram_wr2_set;

                endcase
            end
        end
    end

endmodule
