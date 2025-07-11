module ws2812b
#(parameter COUNTER_0P4 = 4, COUNTER_0P8 = 8, MAX_ADDRESS = 0, COUNT_BITS = 1)
(
    input wire clk,
    input wire nreset,
    input wire [COUNT_BITS - 1:0] address,
    input wire [7:0] r,
    input wire [7:0] g,
    input wire [7:0] b,
    input wire mem_valid,
    output reg mem_ready = 0,
    output reg dout = 0
);
    reg [23:0] mem [0:(1<<COUNT_BITS) - 1];
    reg [23:0] current;
    reg [4:0] bit_counter;
    reg [8:0] one_counter;
    reg [8:0] zero_counter;
    reg [COUNT_BITS:0] current_address;
    reg busy = 0;
    reg prev_busy = 0;
    wire one_counter_nonzero;

    assign one_counter_nonzero = one_counter != 0;

    task init_counters;
        if (current[23] == 0) begin
            one_counter <= COUNTER_0P4;
            zero_counter <= COUNTER_0P8;
        end
        else begin
            one_counter <= COUNTER_0P8;
            zero_counter <= COUNTER_0P4;
        end
    endtask

    always @(posedge clk) begin
        mem_ready <= mem_valid;
        if (!nreset) begin
            busy <= 0;
            prev_busy <= 0;
        end
        else begin
            if (!prev_busy & busy)
                init_counters;
            else if (busy) begin
                dout <= one_counter_nonzero;
                if (one_counter_nonzero) begin
                    one_counter <= one_counter - 1;
                end
                else if (zero_counter != 0) begin
                    if (zero_counter == 2) begin
                        if (bit_counter == 23) begin
                            if (current_address == MAX_ADDRESS + 1)
                                busy <= 0;
                            else begin
                                bit_counter <= 0;
                                current <= mem[current_address[COUNT_BITS - 1:0]];
                                current_address <= current_address + 1;
                            end
                        end
                        else begin
                            current <= current << 1;
                            bit_counter <= bit_counter + 1;
                        end
                    end
                    if (zero_counter == 1) begin
                        init_counters;
                    end
                    else
                        zero_counter <= zero_counter - 1;
                end
            end
            else if (mem_valid) begin
                mem[address] <= {g, r, b};
                if (address == MAX_ADDRESS) begin
                    current_address <= 1;
                    current <= mem[0];
                    bit_counter <= 0;
                    dout <= 0;
                    busy <= 1;
                end
            end
        end
        prev_busy <= busy;
    end
endmodule
