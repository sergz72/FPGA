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
    localparam COUNTER_MAX = COUNTER_0P4 + COUNTER_0P8 - 1;

    reg [23:0] mem [0:(1<<COUNT_BITS) - 1];
    reg [23:0] current;
    reg [4:0] bit_counter;
    reg [8:0] counter;
    reg [COUNT_BITS:0] current_address;
    reg busy = 0;

    always @(posedge clk) begin
        mem_ready <= mem_valid;
        if (!nreset) begin
            busy <= 0;
            dout <= 0;
        end
        else begin
            if (mem_valid) begin
                mem[address] <= {g, r, b};
                if (address == MAX_ADDRESS) begin
                    current_address <= 0;
                    bit_counter <= 23;
                    busy <= 1;
                    counter <= COUNTER_MAX;
                end
            end
            else begin
                if (busy) begin
                    case (counter)
                        0: dout <= 1;
                        COUNTER_0P4: begin
                            if (!current[23])
                                dout <= 0;
                        end
                        COUNTER_0P8: dout <= 0;
                        COUNTER_MAX: begin
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
                        default: begin end
                    endcase
                    counter <= counter == COUNTER_MAX ? 0 : counter + 1;
                end
            end
        end
    end
endmodule
