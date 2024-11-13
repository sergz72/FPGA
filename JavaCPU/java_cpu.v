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
    localparam STATE_WIDTH           = 5;
    localparam STATE_FETCH           = 0;
    localparam STATE_DECODE          = 1;
    localparam STATE_FETCH2          = 2;
    localparam STATE_FETCH3          = 3;
    localparam STATE_FETCH4          = 4;
    localparam STATE_WAITREADY       = 5;
    localparam STATE_WAITREADY_LONG  = 6;
    localparam STATE_WAITREADY_LONG2 = 7;
    localparam STATE_WFI             = 8;
    localparam STATE_INTERRUPT       = 9;
    localparam STATE_PUSH_TEMP       = 10;
    localparam STATE_PUSH_TEMP2      = 11;
    localparam STATE_PUSH_TEMP22     = 12;
    localparam STATE_PUSH_LOCAL      = 13;
    localparam STATE_RET             = 14;
    localparam STATE_INC_LOCAL       = 15;
    localparam STATE_WAITNOTREADY    = 16;

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
    reg [15:0] immediate, immediate2, immediate3, pc_data, current_instruction = 0, address_data;
    wire [31:0] jmp_address, interrupt_address;
    reg [31:0] pc = 0, saved_pc;
    reg [63:0] temp, temp2;
    reg [31:0] temp32;
    reg [31:0] address = 0;
    wire [1:0] interrupt_no;
    wire [7:0] opcode;

    reg start = 0;

    wire push, push_long, dup, set, set_long, alu_op, get, get_long, call, call_indirect, jmp, ret, retn, reti, fetch;
    wire neg, inc, nop, ifcmp, if_, drop, drop2, swap, rot, over, local_get, local_set, locals, get_data_stack_pointer;
    wire arrayp, arrayp2, bipush, sipush;
    wire eq, gt, lt, n, z, z2, condition_neg, condition_cmp_pass, condition_pass;
    wire [1:0] condition_flags, condition_cmp_temp, condition_temp;
    
    initial begin
        $readmemh("asm/code.hex", rom);
    end

    assign opcode = current_instruction[15:8];

    assign push = opcode == 0;
    assign push_long = opcode == 1;
    assign dup = opcode == 2;
    assign set = opcode == 3;
    assign set_long = opcode == 4;
    assign jmp = opcode == 5;
    assign get = opcode == 6;
    assign get_long = opcode == 7;
    assign call = opcode == 8;
    assign call_indirect = opcode == 9;
    assign ret = opcode == 10;
    assign retn = opcode == 11;
    assign hlt = opcode == 12;
    assign wfi = opcode == 13;
    assign neg = opcode == 14;
    assign inc = opcode == 15;
    assign reti = opcode == 16;
    assign drop = opcode == 17;
    assign drop2 = opcode == 18;
    assign swap = opcode == 19;
    assign rot = opcode == 20;
    assign over = opcode == 21;
    assign local_get = opcode == 22;
    assign local_set = opcode == 23;
    assign locals = opcode == 24;
    assign nop = opcode == 25;
    assign get_data_stack_pointer = opcode == 26;
    assign ifcmp = opcode == 27;
    assign if_ = opcode == 28;
    assign alu_op = opcode == 29;
    assign arrayp = opcode == 30;
    assign arrayp2 = opcode == 31;
    assign bipush = opcode == 32;
    assign sipush = opcode == 33;

    assign jmp_address = {pc_data, immediate};
    assign interrupt_no = interrupt[1] ? 2'b10 : {1'b0, interrupt[0]};
    assign interrupt_address = {{28{1'b0}}, interrupt_no, 2'b00};

    assign eq = data_stack_value2 == data_stack_value1;
    assign gt = $signed(data_stack_value2) > $signed(data_stack_value1);
    assign lt = !eq & !gt;
    assign z = data_stack_value1 == 0;
    assign z2 = data_stack_value2 == 0;
    assign n = data_stack_value1[63];

    assign condition_neg = current_instruction[2];
    assign condition_flags = current_instruction[1:0];

    assign condition_cmp_temp = condition_flags & {gt, eq};
    assign condition_cmp_pass = (condition_cmp_temp[0] | condition_cmp_temp[1]) ^ condition_neg;

    assign condition_temp = condition_flags & {n, z};
    assign condition_pass = (condition_temp[0] | condition_temp[1]) ^ condition_neg;

    assign fetch = set | set_long | get_long | get | call_indirect;

    function [63:0] alu(input [3:0] op);
        case (op)
            0: alu = data_stack_value2 + data_stack_value1;
            1: alu = data_stack_value2 - data_stack_value1;
            2: alu = data_stack_value2 & data_stack_value1;
            3: alu = data_stack_value2 | data_stack_value1;
            4: alu = data_stack_value2 ^ data_stack_value1;
            5: alu = data_stack_value2 << data_stack_value1[5:0];
            6: alu = data_stack_value2 >> data_stack_value1[5:0]; // llshr
            7: alu = {32'h0, data_stack_value2[31:0] >> data_stack_value1[4:0]}; // ilshr
            8: alu = data_stack_value2 >>> data_stack_value1[5:0]; // ashr
            9: alu = {{63{1'b0}}, data_stack_value2[data_stack_value1[5:0]]};
            10: alu = $signed(data_stack_value2) * $signed(data_stack_value1);
            11: alu = {{63{lt}}, !eq}; // cmp
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
                    mem_address <= data_stack_value1[31:0] + (call_indirect ? {24'h0, current_instruction[7:0]} : 0);
                    mem_data_out <= data_stack_value2[31:0];
                    mem_valid <= fetch;
                    mem_nwr <= !set & !set_long;
                    if (fetch)
                        error <= z; // null pointer check
                    case (1'b1)
                        if_ | ifcmp | jmp: begin
                            pc <= pc + ((if_ & condition_pass) | (ifcmp & condition_cmp_pass) | jmp ? {{16{pc_data[15]}}, pc_data} : 1);
                            state <= STATE_FETCH;
                            data_stack_pointer <= data_stack_pointer + (ifcmp ? 2 : (if_ ? 1 : 0));
                        end
                        push | push_long | call | call_indirect: begin
                            if (call | push | push_long) begin
                                immediate <= pc_data;
                                state <= STATE_FETCH2;
                                pc <= pc + 1;
                            end
                            else begin // call_indirect
                                data_stack_pointer <= data_stack_pointer + 1;
                                state <= STATE_WAITREADY;
                            end
                            if (call | call_indirect) begin
                                call_stack_nwr <= 0;
                                call_stack_wr_data <= {32'h0, pc + (call ? 2 : 0)};
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
                        drop2: begin
                            data_stack_pointer <= data_stack_pointer + 2;
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
                        set_long: state <= STATE_WAITREADY_LONG;
                        get: state <= STATE_WAITREADY;
                        get_long: state <= STATE_WAITREADY_LONG;
                        retn: begin
                            call_stack_pointer <= call_stack_pointer + current_instruction[7:0];
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
                            call_stack_pointer <= call_stack_pointer + current_instruction[7:0];
                            state <= STATE_FETCH;
                        end
                        local_get: begin
                            local_pointer <= call_stack_pointer + current_instruction[7:0];
                            state <= STATE_PUSH_LOCAL;
                        end
                        local_set: begin
                            call_stack_nwr <= 0;
                            call_stack_wr_data <= data_stack_value1;
                            call_stack_wr_address <= call_stack_pointer + current_instruction[7:0];
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        locals: begin
                            call_stack_pointer <= call_stack_pointer - current_instruction[7:0];
                            state <= STATE_FETCH;
                        end
                        neg: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= -data_stack_value1;
                            state <= STATE_FETCH;
                        end
                        inc: begin
                            local_pointer <= call_stack_pointer + current_instruction[7:0];
                            immediate <= pc_data;
                            pc <= pc + 1;
                            state <= STATE_INC_LOCAL;
                        end
                        get_data_stack_pointer: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= {{64-DATA_STACK_BITS{1'b0}}, data_stack_pointer};
                            data_stack_pointer <= data_stack_pointer - 1;
                            state <= STATE_FETCH;
                        end
                        nop: state <= STATE_FETCH;
                        arrayp | arrayp2: begin
                            error <= z2;
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= data_stack_value2 + (arrayp ? data_stack_value1 : data_stack_value1 << 1);
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        bipush: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= {{56{current_instruction[7]}}, current_instruction[7:0]};
                            data_stack_pointer <= data_stack_pointer - 1;
                            state <= STATE_FETCH;
                        end
                        sipush: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= {{48{pc_data[15]}}, pc_data};
                            data_stack_pointer <= data_stack_pointer - 1;
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
                    case (1'b1)
                        call: begin
                            pc <= jmp_address;
                            state <= STATE_FETCH;
                        end
                        push_long: begin
                            immediate2 <= pc_data;
                            pc <= pc + 1;
                            state <= STATE_FETCH3;
                        end
                        default: begin
                            pc <= pc + 1;
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= {{32{jmp_address[31]}}, jmp_address};
                            data_stack_pointer <= data_stack_pointer - 1;
                            state <= STATE_FETCH;
                        end
                    endcase
                end
                STATE_FETCH3: begin
                    immediate3 <= pc_data;
                    pc <= pc + 1;
                    state <= STATE_FETCH4;
                end
                STATE_FETCH4: begin
                    pc <= pc + 1;
                    data_stack_nwr <= 0;
                    data_stack_wr_data <= {pc_data, immediate3, immediate2, immediate};
                    data_stack_pointer <= data_stack_pointer - 1;
                    state <= STATE_FETCH;
                end
                STATE_PUSH_LOCAL: begin
                    data_stack_nwr <= 0;
                    data_stack_wr_data <= local_value;
                    data_stack_pointer <= data_stack_pointer - 1;
                    state <= STATE_FETCH;
                end
                STATE_INC_LOCAL: begin
                    call_stack_nwr <= 0;
                    call_stack_wr_data <= local_value + {{48{immediate[15]}}, immediate};
                    call_stack_wr_address <= local_pointer;
                    state <= STATE_FETCH;
                end
                STATE_WAITREADY: begin
                    if (mem_ready) begin
                        if (call_indirect)
                            pc <= mem_data_in;
                        state <= STATE_FETCH;
                        mem_nwr <= 1;
                        mem_valid <= 0;
                        if (get) begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= {{32{mem_data_in[31]}}, mem_data_in};
                        end
                    end
                end
                STATE_WAITREADY_LONG: begin
                    if (mem_ready) begin
                        if (get_long)
                            temp32 <= mem_data_in;
                        mem_valid <= 0;
                        state <= STATE_WAITNOTREADY;
                    end
                end
                STATE_WAITNOTREADY: begin
                    if (!mem_ready) begin
                        mem_valid <= 1;
                        mem_address <= mem_address + 1;
                        mem_data_out <= data_stack_value2[63:32];
                        state <= STATE_WAITREADY_LONG2;
                        if (set_long)
                           data_stack_pointer <= data_stack_pointer + 2;
                    end
                end
                STATE_WAITREADY_LONG2: begin
                    if (mem_ready) begin
                        state <= STATE_FETCH;
                        mem_nwr <= 1;
                        mem_valid <= 0;
                        if (get_long) begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= {mem_data_in, temp32};
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
