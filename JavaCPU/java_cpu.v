module java_cpu
#(parameter DATA_STACK_BITS = 6, CALL_STACK_BITS = 9, ROM_BITS = 10)
(
    input wire clk,
    input wire nreset,
    output reg error = 0,
    output wire hlt,
    output wire wfi,
    output reg [31:0] mem_address,
    input wire [31:0] mem_data_in,
    output reg [31:0] mem_data_out,
    output reg mem_valid = 0,
    output reg mem_nwr = 1,
    input wire mem_ready,
    input wire [1:0] interrupt,
    output reg [1:0] interrupt_ack = 0
);
    localparam STATE_WIDTH          = 4;
    localparam STATE_FETCH          = 0;
    localparam STATE_DECODE         = 1;
    localparam STATE_FETCH2         = 2;
    localparam STATE_WAITREADY      = 3;
    localparam STATE_WFI            = 4;
    localparam STATE_INTERRUPT      = 5;
    localparam STATE_PUSH_TEMP      = 6;
    localparam STATE_PUSH_TEMP2     = 7;
    localparam STATE_PUSH_TEMP22    = 8;
    localparam STATE_PUSH_LOCAL     = 9;
    localparam STATE_RET            = 10;

    reg [63:0] data_stack[0:(1<<DATA_STACK_BITS)-1];
    reg [63:0] data_stack_wr_data, data_stack_value1, data_stack_value2;
    reg [DATA_STACK_BITS - 1:0] data_stack_pointer = 0;
    reg data_stack_nwr = 1;

    reg [63:0] call_stack[0:(1<<CALL_STACK_BITS)-1];
    reg [63:0] call_stack_wr_data, call_stack_value, local_value;
    reg [CALL_STACK_BITS - 1:0] call_stack_pointer = 0, call_stack_wr_address;
    reg [CALL_STACK_BITS - 1:0] local_pointer = 0;
    reg call_stack_nwr = 1;

    reg [STATE_WIDTH - 1:0] state = STATE_FETCH;

    reg [15:0] rom[0:(1<<ROM_BITS)-1];
    reg [15:0] immediate, pc_data, current_instruction = 0, address_data;
    wire [31:0] jmp_address, interrupt_address;
    reg [31:0] pc = 0, saved_pc;
    reg [63:0] temp, temp2;
    reg [31:0] address = 0;
    wire [1:0] interrupt_no;

    reg start = 0;

    wire push, dup, set, alu_op, jmp, get, call, ret, retn, br, br0, reti, drop, swap, rot, over;
    wire local_get, local_set, locals;
    wire eq, gt, z;
    
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
    assign retn = current_instruction == 7;
    assign hlt = current_instruction == 8;
    assign wfi = current_instruction == 9;
    assign br = current_instruction == 10;
    assign br0 = current_instruction == 11;
    assign reti = current_instruction == 12;
    assign drop = current_instruction == 13;
    assign swap = current_instruction == 14;
    assign rot = current_instruction == 15;
    assign over = current_instruction == 16;
    assign local_get = current_instruction == 17;
    assign local_set = current_instruction == 18;
    assign locals = current_instruction == 19;
    assign alu_op = current_instruction[15:4] == 12'hF;

    assign jmp_address = {pc_data, immediate};
    assign interrupt_no = interrupt[1] ? 2'b10 : {1'b0, interrupt[0]};
    assign interrupt_address = {{28{1'b0}}, interrupt_no, 2'b00};

    assign eq = data_stack_value2 == data_stack_value1;
    assign gt = $signed(data_stack_value2) > $signed(data_stack_value1);
    assign z = data_stack_value1 == 0;

    function [63:0] alu(input [3:0] op);
        case (op)
            0: alu = data_stack_value2 + data_stack_value1;
            1: alu = data_stack_value2 - data_stack_value1;
            2: alu = data_stack_value2 & data_stack_value1;
            3: alu = data_stack_value2 | data_stack_value1;
            4: alu = data_stack_value2 ^ data_stack_value1;
            5: alu = {{63{1'b0}}, eq};
            6: alu = {{63{1'b0}}, !eq};
            7: alu = {{63{1'b0}}, gt};
            8: alu = {{63{1'b0}}, eq | gt};
            9: alu = {{63{1'b0}}, !gt};
            10: alu = {{63{1'b0}}, !eq & !gt};
            11: alu = data_stack_value2 << data_stack_value1;
            12: alu = data_stack_value2 >> data_stack_value1;
            13: alu = data_stack_value2 >>> data_stack_value1;
            14: alu = {{63{1'b0}}, data_stack_value2[data_stack_value1[5:0]]};
            15: alu = $signed(data_stack_value2) * $signed(data_stack_value1);
            default: alu = {64{1'bx}};
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
        if (!call_stack_nwr)
            call_stack[call_stack_wr_address] <= call_stack_wr_data;
        else begin
            call_stack_value <= call_stack[call_stack_pointer];
            local_value <= call_stack[local_pointer];
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
            state <= STATE_FETCH;
            interrupt_ack <= 0;
        end
        else if (start & !error & !hlt) begin
            case (state)
                STATE_FETCH: begin
                    data_stack_nwr <= 1;
                    call_stack_nwr <= 1;
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
                    mem_address <= data_stack_value1[31:0];
                    mem_data_out <= data_stack_value2[31:0];
                    mem_valid <= set | get;
                    mem_nwr <= !set;
                    case (1'b1)
                        push | jmp | call | br | br0: begin
                            if ((!z & br) | (z & br0) | jmp | call | push) begin
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
                                call_stack_wr_data <= {32'h0, pc + 2};
                                call_stack_wr_address <= call_stack_pointer - 1;
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
                            temp2 <= data_stack_value2;
                            state <= STATE_PUSH_TEMP22;
                        end
                        rot: begin
                            data_stack_pointer <= data_stack_pointer + 2;
                            temp <= data_stack_value1;
                            temp2 <= data_stack_value2;
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
                        retn: begin
                            call_stack_pointer <= call_stack_pointer + pc_data[7:0];
                            state <= STATE_RET;
                        end
                        ret: begin
                            pc <= call_stack_value[31:0];
                            call_stack_pointer <= call_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        wfi: state <= STATE_WFI;
                        reti: begin
                            pc <= saved_pc;
                            interrupt_ack <= 0;
                            state <= STATE_FETCH;
                        end
                        local_get: begin
                            local_pointer <= call_stack_pointer + pc_data[7:0];
                            pc <= pc + 1;
                            state <= STATE_PUSH_LOCAL;
                        end
                        local_set: begin
                            call_stack_nwr <= 0;
                            call_stack_wr_data <= data_stack_value1;
                            call_stack_wr_address <= call_stack_pointer + pc_data[7:0];
                            data_stack_pointer <= data_stack_pointer + 1;
                            pc <= pc + 1;
                            state <= STATE_FETCH;
                        end
                        locals: begin
                            call_stack_pointer <= call_stack_pointer - pc_data[7:0];
                            pc <= pc + 1;
                            state <= STATE_FETCH;
                        end
                        default: error <= 1;
                    endcase
                end
                STATE_RET: begin
                    pc <= call_stack_value[31:0];
                    call_stack_pointer <= call_stack_pointer + 1;
                    state <= STATE_FETCH;
                end
                STATE_FETCH2: begin
                    call_stack_nwr <= 1;
                    state <= STATE_FETCH;
                    if (jmp | call | br | br0)
                        pc <= jmp_address;
                    else begin
                        pc <= pc + 1;
                        data_stack_nwr <= 0;
                        data_stack_wr_data <= {{32{jmp_address[31]}}, jmp_address};
                        data_stack_pointer <= data_stack_pointer - 1;
                    end
                end
                STATE_PUSH_LOCAL: begin
                    data_stack_nwr <= 0;
                    data_stack_wr_data <= local_value;
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
                            data_stack_wr_data <= {{32{mem_data_in[31]}}, mem_data_in};
                        end
                    end
                end
                STATE_WFI: begin
                    if (interrupt_no != 0)
                        state <= STATE_FETCH;
                end
                STATE_PUSH_TEMP22: begin
                    data_stack_wr_data <= temp2;
                    data_stack_pointer <= data_stack_pointer - 1;
                    state <= STATE_FETCH;
                end
                STATE_PUSH_TEMP: begin
                    data_stack_wr_data <= temp;
                    data_stack_pointer <= data_stack_pointer - 1;
                    state <= STATE_PUSH_TEMP22;
                end
                STATE_PUSH_TEMP2: begin
                    data_stack_nwr <= 0;
                    data_stack_wr_data <= temp2;
                    temp2 <= data_stack_value1;
                    state <= STATE_PUSH_TEMP;
                end
            endcase
        end
    end
endmodule