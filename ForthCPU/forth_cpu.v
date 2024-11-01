module forth_cpu
#(parameter DATA_STACK_BITS = 6, CALL_STACK_BITS = 6, WIDTH = 16, ROM_BITS = 8, PARAMETER_STACK_BITS = 9)
(
    input wire clk,
    input wire nreset,
    output reg error = 0,
    output wire hlt,
    output wire wfi,
    output reg [WIDTH - 1:0] mem_address,
    input wire [WIDTH - 1:0] mem_data_in,
    output reg [WIDTH - 1:0] mem_data_out,
    output reg mem_valid = 0,
    output reg mem_nwr = 1,
    input wire mem_ready,
    input wire [1:0] interrupt,
    output reg [1:0] interrupt_ack = 0
);
    localparam STATE_WIDTH      = 4;
    localparam STATE_FETCH      = 0;
    localparam STATE_DECODE     = 1;
    localparam STATE_FETCH2     = 2;
    localparam STATE_WAITREADY  = 3;
    localparam STATE_WFI        = 4;
    localparam STATE_INTERRUPT  = 5;
    localparam STATE_PUSH_TEMP  = 6;
    localparam STATE_SAVE_TEMP  = 7;
    localparam STATE_PUSH_TEMP2 = 8;
    localparam STATE_PUSH_REG   = 9;
    localparam STATE_LOOP       = 10;

    reg [WIDTH - 1:0] data_stack[0:(1<<DATA_STACK_BITS)-1];
    reg [WIDTH - 1:0] data_stack_wr_data, data_stack_value1, data_stack_value2;
    reg [DATA_STACK_BITS - 1:0] data_stack_pointer = 0;
    reg data_stack_nwr = 1;

    reg [WIDTH - 1:0] call_stack[0:(1<<CALL_STACK_BITS)-1];
    reg [WIDTH - 1:0] call_stack_wr_data, call_stack_value;
    reg [CALL_STACK_BITS - 1:0] call_stack_pointer = 0;
    reg call_stack_nwr = 1;

    reg [WIDTH - 1:0] parameter_stack[0:(1<<PARAMETER_STACK_BITS)-1];
    reg [WIDTH - 1:0] parameter_stack_wr_data, parameter_stack_value1, parameter_stack_value2, reg_value;
    reg [PARAMETER_STACK_BITS - 1:0] parameter_stack_pointer = 0, parameter_stack_wr_address;
    reg [PARAMETER_STACK_BITS - 1:0] reg_pointer = 0;
    reg parameter_stack_nwr = 1;

    reg [STATE_WIDTH - 1:0] state = STATE_FETCH;

    reg [WIDTH/2 - 1:0] rom[0:(1<<ROM_BITS)-1];
    reg [WIDTH/2 - 1:0] immediate, pc_data, current_instruction = 0, address_data;
    wire [WIDTH - 1:0] jmp_address, interrupt_address;
    reg [WIDTH - 1:0] pc = 0, saved_pc, temp, temp2;
    reg [WIDTH - 1:0] address = 0;
    wire [1:0] interrupt_no;

    reg start = 0;

    wire push, dup, set, alu_op, jmp, get, call, ret, br, br0, reti, drop, swap, rot, over, loop;
    wire pstack_add, pstack_get, pstack_push, pstack_get_reg, pstack_set_reg;
    wire eq, gt, z, pstack_ge;
    
    initial begin
        $readmemh("asm/code.hex", rom);
    end

    assign push = current_instruction == 0;
    assign dup = current_instruction == 1;
    assign set = current_instruction == 2;
    assign jmp = current_instruction == 3;
    assign get = current_instruction == 4;
    assign call = current_instruction == 5;
    assign ret = current_instruction == 6;
    assign hlt = current_instruction == 7;
    assign wfi = current_instruction == 8;
    assign br = current_instruction == 9;
    assign br0 = current_instruction == 10;
    assign reti = current_instruction == 11;
    assign drop = current_instruction == 12;
    assign swap = current_instruction == 13;
    assign rot = current_instruction == 14;
    assign over = current_instruction == 15;
    assign loop = current_instruction == 16;
    assign pstack_push = current_instruction == 17;
    assign pstack_get = current_instruction == 18;
    assign pstack_get_reg = current_instruction == 19;
    assign pstack_set_reg = current_instruction == 20;
    assign alu_op = current_instruction[7:4] == 4'hF;

    assign jmp_address = {pc_data, immediate};
    assign interrupt_no = interrupt[1] ? 2'b10 : {1'b0, interrupt[0]};
    assign interrupt_address = {{WIDTH-4{1'b0}}, interrupt_no, 2'b00};

    assign eq = data_stack_value2 == data_stack_value1;
    assign gt = data_stack_value2 > data_stack_value1;
    assign z = data_stack_value1 == 0;
    assign pstack_ge = parameter_stack_value2 >= parameter_stack_value1;

    function [WIDTH - 1:0] alu(input [3:0] op);
        case (op)
            0: alu = data_stack_value2 + data_stack_value1;
            1: alu = data_stack_value2 & data_stack_value1;
            2: alu = data_stack_value2 | data_stack_value1;
            3: alu = data_stack_value2 ^ data_stack_value1;
            4: alu = {{WIDTH-1{1'b0}}, eq};
            5: alu = {{WIDTH-1{1'b0}}, !eq};
            6: alu = {{WIDTH-1{1'b0}}, gt};
            7: alu = {{WIDTH-1{1'b0}}, eq | gt};
            8: alu = {{WIDTH-1{1'b0}}, !gt};
            9: alu = {{WIDTH-1{1'b0}}, !eq & !gt};
            10: alu = data_stack_value2 << data_stack_value1;
            11: alu = data_stack_value2 >> data_stack_value1;
            12: alu = data_stack_value2 * data_stack_value1;
            13: alu = data_stack_value2 / data_stack_value1;
            14: alu = data_stack_value2 % data_stack_value1;
            default: alu = data_stack_value2 - data_stack_value1;
        endcase
    endfunction

    always @(negedge clk) begin
        pc_data <= rom[pc[ROM_BITS - 1:0]];
        address_data <= rom[address[ROM_BITS - 1:0]];
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

    always @(negedge clk) begin
        if (!parameter_stack_nwr)
            parameter_stack[parameter_stack_wr_address] <= parameter_stack_wr_data;
        else begin
            parameter_stack_value1 <= parameter_stack[parameter_stack_pointer];
            parameter_stack_value2 <= parameter_stack[parameter_stack_pointer+1];
            reg_value <= parameter_stack[reg_pointer];
        end
    end

    always @(posedge clk) begin
        if (!nreset) begin
            error <= 0;
            current_instruction <= 0;
            pc <= 0;
            address <= 0;
            mem_valid <= 0;
            mem_nwr <= 1;
            data_stack_pointer <= 0;
            data_stack_nwr <= 1;
            call_stack_pointer <= 0;
            call_stack_nwr <= 1;
            parameter_stack_pointer <= 0;
            parameter_stack_nwr <= 1;
            state <= STATE_FETCH;
            interrupt_ack <= 0;
        end
        else if (start & !error & !hlt) begin
            case (state)
                STATE_FETCH: begin
                    data_stack_nwr <= 1;
                    parameter_stack_nwr <= 1;
                    if (interrupt_no != 0 & interrupt_ack == 0) begin
                        saved_pc <= pc;
                        address <= interrupt_address;
                        interrupt_ack <= interrupt_no;
                        state <= STATE_INTERRUPT;
                    end
                    else begin
                        current_instruction <= pc_data;
                        state <= STATE_DECODE;
                        pc <= pc + 1;
                    end
                end
                STATE_INTERRUPT: begin
                    current_instruction <= address_data;
                    pc <= address + 1;
                    state <= STATE_DECODE;
                end
                STATE_DECODE: begin
                    mem_address <= data_stack_value1;
                    mem_data_out <= data_stack_value2;
                    mem_valid <= set | get;
                    mem_nwr <= !set;
                    case (1'b1)
                        push | jmp | call | br | br0 | pstack_get | pstack_get_reg | pstack_set_reg: begin
                            if ((!z & br) | (z & br0) | jmp | call | push | pstack_get | pstack_get_reg | pstack_set_reg) begin
                                immediate <= pc_data;
                                state <= STATE_FETCH2;
                                pc <= pc + 1;
                            end
                            else begin
                                pc <= pc + 2;
                                state <= STATE_FETCH;
                            end
                            if (br | br0)
                                data_stack_pointer <= data_stack_pointer + 1;
                            if (call) begin
                                call_stack_nwr <= 0;
                                call_stack_wr_data <= pc + 2;
                                call_stack_pointer <= call_stack_pointer - 1;
                            end
                        end
                        dup: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= data_stack_value1;
                            data_stack_pointer <= data_stack_pointer - 1;
                            state <= STATE_FETCH;
                        end
                        over: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= data_stack_value2;
                            data_stack_pointer <= data_stack_pointer - 1;
                            state <= STATE_FETCH;
                        end
                        drop: begin
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        swap: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= data_stack_value1;
                            data_stack_pointer <= data_stack_pointer + 1;
                            temp <= data_stack_value2;
                            state <= STATE_PUSH_TEMP;
                        end
                        rot: begin
                            data_stack_pointer <= data_stack_pointer + 2;
                            temp <= data_stack_value2;
                            temp2 <= data_stack_value1;
                            state <= STATE_PUSH_TEMP2;
                        end
                        alu_op: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= alu(current_instruction[3:0]);
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        set: begin
                            state <= STATE_WAITREADY;
                            data_stack_pointer <= data_stack_pointer + 2;
                        end
                        get: state <= STATE_WAITREADY;
                        ret: begin
                            pc <= call_stack_value;
                            call_stack_pointer <= call_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        wfi: state <= STATE_WFI;
                        reti: begin
                            pc <= saved_pc;
                            interrupt_ack <= 0;
                            state <= STATE_FETCH;
                        end
                        pstack_push: begin
                            parameter_stack_nwr <= 0;
                            parameter_stack_wr_data <= data_stack_value1;
                            parameter_stack_wr_address <= parameter_stack_pointer - 1;
                            parameter_stack_pointer <= parameter_stack_pointer - 1;
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        loop: begin
                            parameter_stack_nwr <= 0;
                            parameter_stack_wr_data <= data_stack_value1 + parameter_stack_value2;
                            parameter_stack_wr_address <= parameter_stack_pointer + 1;
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_LOOP;
                        end
                        default: error <= 1;
                    endcase
                end
                STATE_LOOP: begin
                    if (pstack_ge) begin
                        state <= STATE_FETCH;
                        pc <= pc + 2;
                    end
                    else begin
                        immediate <= pc_data;
                        state <= STATE_FETCH2;
                        pc <= pc + 1;
                    end
                end
                STATE_FETCH2: begin
                    call_stack_nwr <= 1;
                    pc <= jmp | call | br | br0 | loop ? jmp_address : pc + 1;
                    case (1'b1)
                        push: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= jmp_address;
                            data_stack_pointer <= data_stack_pointer - 1;
                            state <= STATE_FETCH;
                        end
                        pstack_get: begin
                            reg_pointer <= parameter_stack_pointer + jmp_address[PARAMETER_STACK_BITS - 1:0];
                            state <= STATE_PUSH_REG;
                        end
                        pstack_get_reg: begin
                            reg_pointer <= jmp_address[PARAMETER_STACK_BITS - 1:0];
                            state <= STATE_PUSH_REG;
                        end
                        pstack_set_reg: begin
                            parameter_stack_nwr <= 0;
                            parameter_stack_wr_data <= data_stack_value1;
                            parameter_stack_wr_address <= jmp_address[PARAMETER_STACK_BITS - 1:0];
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                    endcase
                end
                STATE_PUSH_REG: begin
                    data_stack_nwr <= 0;
                    data_stack_wr_data <= reg_value;
                    data_stack_pointer <= data_stack_pointer - 1;
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
                STATE_WFI: begin
                    if (interrupt_no != 0)
                        state <= STATE_FETCH;
                end
                STATE_PUSH_TEMP: begin
                    data_stack_wr_data <= temp;
                    data_stack_pointer <= data_stack_pointer - 1;
                    state <= STATE_FETCH;
                end
                STATE_PUSH_TEMP2: begin
                    data_stack_wr_data <= temp2;
                    data_stack_pointer <= data_stack_pointer - 1;
                    state <= STATE_PUSH_TEMP;
                end
                STATE_SAVE_TEMP: begin
                    data_stack_nwr <= 0;
                    data_stack_wr_data <= temp;
                    temp <= data_stack_value1;
                    state <= STATE_PUSH_TEMP2;
                end
            endcase
        end
    end
endmodule
