module forth_cpu
#(parameter DATA_STACK_BITS = 4, CALL_STACK_BITS = 4, WIDTH = 16, ROM_BITS = 8)
(
    input wire clk,
    input wire nreset,
    output reg error = 0,
    output reg hlt = 0,
    output reg wfi = 0,
    output reg [WIDTH - 1:0] mem_address,
    input wire [WIDTH - 1:0] mem_data_in,
    output reg [WIDTH - 1:0] mem_data_out,
    output reg mem_valid = 0,
    output reg mem_nwr = 1,
    input wire mem_ready
);
    localparam STATE_WIDTH     = 2;
    localparam STATE_FETCH     = 0;
    localparam STATE_DECODE    = 1;
    localparam STATE_FETCH2    = 2;
    localparam STATE_WAITREADY = 3;

    localparam PCADD = WIDTH - ROM_BITS;

    reg [WIDTH - 1:0] data_stack[0:(1<<DATA_STACK_BITS)-1];
    reg [WIDTH - 1:0] data_stack_wr_data, data_stack_value1, data_stack_value2;
    reg [DATA_STACK_BITS - 1:0] data_stack_pointer = 0;
    reg data_stack_nwr = 1;

    reg [WIDTH - 1:0] call_stack[0:(1<<CALL_STACK_BITS)-1];
    reg [WIDTH - 1:0] call_stack_wr_data, call_stack_value;
    reg [CALL_STACK_BITS - 1:0] call_stack_pointer = 0;
    reg call_stack_nwr = 1;

    reg [WIDTH/2 - 1:0] rom[0:(1<<ROM_BITS)-1];
    reg [ROM_BITS - 1:0] pc = 0;

    reg [STATE_WIDTH - 1:0] state = STATE_FETCH;
    reg [WIDTH/2 - 1:0] immediate, pc_data, current_instruction;
    wire [WIDTH - 1:0] jmp_address;

    reg start = 0;

    wire push, dup, set, alu_op, jmp, get, call, ret, hlt_, wfi_, br, eq;
    
    initial begin
        $readmemh("asm/code.hex", rom);
    end

    assign push = current_instruction == 0;
    assign dup = current_instruction == 1;
    assign set = current_instruction == 2;
    assign jmp = current_instruction == 3;
    assign get = current_instruction == 4;
    assign call = current_instruction == 6;
    assign ret = current_instruction == 7;
    assign hlt_ = current_instruction == 8;
    assign wfi_ = current_instruction == 9;
    assign br = current_instruction == 10;
    assign eq = current_instruction == 11;
    assign alu_op = current_instruction[7:4] == 4'hF;

    assign jmp_address = {pc_data, immediate};

    function [WIDTH - 1:0] alu(input [WIDTH - 1:0] op1, input [WIDTH - 1:0] op2);
        case (current_instruction[3:0])
            0: alu = op1 + op2;
            1: alu = op1 & op2;
            2: alu = op1 | op2;
            3: alu = op1 ^ op2;
            default: alu = op1 - op2;
        endcase
    endfunction

    always @(negedge clk) begin
        pc_data <= rom[pc];
        start <= nreset;
    end

    always @(negedge clk) begin
        if (!data_stack_nwr)
            data_stack[data_stack_pointer] <= data_stack_wr_data;
        else begin
            data_stack_value1 <= data_stack[data_stack_pointer];
            data_stack_value2 <= data_stack[data_stack_pointer+1];
        end
    end

    always @(negedge clk) begin
        if (!call_stack_nwr)
            call_stack[call_stack_pointer] <= call_stack_wr_data;
        else
            call_stack_value <= call_stack[call_stack_pointer];
    end

    always @(posedge clk) begin
        if (!nreset) begin
            error <= 0;
            hlt <= 0;
            hlt <= 0;
            pc <= 0;
            mem_valid <= 0;
            mem_nwr <= 1;
            data_stack_pointer <= 0;
            data_stack_nwr <= 1;
            call_stack_pointer <= 0;
            call_stack_nwr <= 1;
            state <= STATE_FETCH;
        end
        else if (start & !error & !hlt) begin
            case (state)
                STATE_FETCH: begin
                    data_stack_nwr <= 1;
                    current_instruction <= pc_data;
                    state <= STATE_DECODE;
                    pc <= pc + 1;
                end
                STATE_DECODE: begin
                    mem_address <= data_stack_value1;
                    mem_data_out <= data_stack_value2;
                    mem_valid <= set | get;
                    mem_nwr <= !set;
                    case (1'b1)
                        push | jmp | call | br: begin
                            immediate <= pc_data;
                            state <= STATE_FETCH2;
                            pc <= pc + 1;
                            if (call) begin
                                call_stack_nwr <= 0;
                                call_stack_wr_data <= {{PCADD{1'b0}}, pc + {{ROM_BITS-2{1'b0}}, 2'b11}};
                                call_stack_pointer <= call_stack_pointer - 1;
                            end
                        end
                        dup: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= data_stack_value1;
                            data_stack_pointer <= data_stack_pointer - 1;
                            state <= STATE_FETCH;
                        end
                        alu_op: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= alu(data_stack_value1, data_stack_value2);
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        set | get: begin
                            state <= STATE_WAITREADY;
                            data_stack_pointer <= data_stack_pointer + 1;
                        end
                        ret: begin
                            pc <= call_stack_value[ROM_BITS - 1:0];
                            call_stack_pointer <= call_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        hlt_: hlt <= 1;
                        default: error <= 1;
                    endcase
                end
                STATE_FETCH2: begin
                    call_stack_nwr <= 1;
                    if (jmp | call)
                        pc <= jmp_address[ROM_BITS - 1:0];
                    else begin
                        pc <= pc + 1;
                        data_stack_nwr <= 0;
                        data_stack_wr_data <= {pc_data, immediate};
                        data_stack_pointer <= data_stack_pointer - 1;
                    end
                    state <= STATE_FETCH;
                end
                STATE_WAITREADY: begin
                    if (mem_ready) begin
                        state <= STATE_FETCH;
                        mem_nwr <= 1;
                        mem_valid <= 0;
                        if (get) begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= mem_data_in;
                        end
                    end
                end
            endcase
        end
    end
endmodule
