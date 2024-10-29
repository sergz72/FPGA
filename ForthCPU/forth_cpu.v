module forth_cpu
#(parameter DATA_STACK_BITS = 4, CALL_STACK_BITS = 4, WIDTH = 16, ROM_BITS = 8)
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
    localparam STATE_WIDTH      = 3;
    localparam STATE_FETCH      = 0;
    localparam STATE_DECODE     = 1;
    localparam STATE_FETCH2     = 2;
    localparam STATE_WAITREADY  = 3;
    localparam STATE_WFI        = 4;
    localparam STATE_INTERRUPT  = 5;

    reg [WIDTH - 1:0] data_stack[0:(1<<DATA_STACK_BITS)-1];
    reg [WIDTH - 1:0] data_stack_wr_data, data_stack_value1, data_stack_value2;
    reg [DATA_STACK_BITS - 1:0] data_stack_pointer = 0;
    reg data_stack_nwr = 1;

    reg [WIDTH - 1:0] call_stack[0:(1<<CALL_STACK_BITS)-1];
    reg [WIDTH - 1:0] call_stack_wr_data, call_stack_value;
    reg [CALL_STACK_BITS - 1:0] call_stack_pointer = 0;
    reg call_stack_nwr = 1;

    reg [STATE_WIDTH - 1:0] state = STATE_FETCH;

    reg [WIDTH/2 - 1:0] rom[0:(1<<ROM_BITS)-1];
    reg [WIDTH/2 - 1:0] immediate, pc_data, current_instruction = 0, address_data;
    wire [WIDTH - 1:0] jmp_address, interrupt_address;
    reg [WIDTH - 1:0] pc = 0, saved_pc;
    reg [WIDTH - 1:0] address = 0;
    wire [1:0] interrupt_no;

    reg start = 0;

    wire push, dup, set, alu_op, jmp, get, call, ret, br, br0, reti;
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
    assign hlt = current_instruction == 7;
    assign wfi = current_instruction == 8;
    assign br = current_instruction == 9;
    assign br0 = current_instruction == 10;
    assign reti = current_instruction == 11;
    assign drop = current_instruction == 12;
    assign alu_op = current_instruction[7:4] == 4'hF;

    assign jmp_address = {pc_data, immediate};
    assign interrupt_no = interrupt[1] ? 2'b10 : {1'b0, interrupt[0]};
    assign interrupt_address = {{WIDTH-4{1'b0}}, interrupt_no, 2'b00};

    assign eq = data_stack_value2 == data_stack_value1;
    assign gt = data_stack_value2 > data_stack_value1;
    assign z = data_stack_value1 == 0;

    function [WIDTH - 1:0] alu(input [3:0] op);
        case (op)
            0: alu = data_stack_value2 + data_stack_value1;
            1: alu = data_stack_value2 & data_stack_value1;
            2: alu = data_stack_value2 | data_stack_value1;
            3: alu = data_stack_value2 ^ data_stack_value1;
            4: alu = {{WIDTH-1{1'b0}}, gt};
            5: alu = {{WIDTH-1{1'b0}}, eq | gt};
            6: alu = {{WIDTH-1{1'b0}}, !gt};
            7: alu = {{WIDTH-1{1'b0}}, !eq & !gt};
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
        if (!call_stack_nwr)
            call_stack[call_stack_pointer] <= call_stack_wr_data;
        else
            call_stack_value <= call_stack[call_stack_pointer];
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
                    if (interrupt_no != 0) begin
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
                        drop: begin
                            call_stack_pointer <= call_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        alu_op: begin
                            data_stack_nwr <= 0;
                            data_stack_wr_data <= alu(current_instruction[3:0]);
                            data_stack_pointer <= data_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        set | get: begin
                            state <= STATE_WAITREADY;
                            data_stack_pointer <= data_stack_pointer + 1;
                        end
                        ret: begin
                            pc <= call_stack_value;
                            call_stack_pointer <= call_stack_pointer + 1;
                            state <= STATE_FETCH;
                        end
                        wfi: state <= STATE_WFI;
                        reti: begin
                            pc <= saved_pc;
                            state <= STATE_FETCH;
                        end
                        default: error <= 1;
                    endcase
                end
                STATE_FETCH2: begin
                    call_stack_nwr <= 1;
                    if (jmp | call | br | br0)
                        pc <= jmp_address;
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
                STATE_WFI: begin
                    if (interrupt_no != 0)
                        state <= STATE_FETCH;
                end
            endcase
        end
    end
endmodule
