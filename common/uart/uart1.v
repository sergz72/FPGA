module uart1tx
#(parameter CLOCK_DIV = 234, CLOCK_COUNTER_BITS = 8) // 27 MHz clk, 115200 baud
(
    input wire clk,
    input wire nreset,
    output wire tx,
    input wire [7:0] data,
    input wire send,
    output reg busy = 0
);
    reg [CLOCK_COUNTER_BITS - 1:0] counter;
    reg [3:0] bit_counter = 0;
    reg [10:0] data_out = {11{1'h1}};

    assign tx = data_out[0];

    always @(posedge clk) begin
        if (!nreset) begin
            bit_counter <= 0;
            busy <= 0;
            data_out <= {11{1'h1}};
        end
        else if (send == 1) begin
            bit_counter <= 4'd11;
            data_out <= {1'b1, data[7:0], 2'b01};
            busy <= 1;
            counter <= 0;
        end
        else if (bit_counter != 0) begin
            if (counter == CLOCK_DIV - 1) begin
                counter <= 0;
                data_out <= {1'b1, data_out[10:1]};
                bit_counter <= bit_counter - 1;
            end
            else
                counter <= counter + 1;
        end
        else
            busy <= 0;
    end
endmodule

module uart1rx
#(parameter CLOCK_DIV = 234, CLOCK_COUNTER_BITS = 8) // 27 MHz clk, 115200 baud
(
    input wire clk,
    input wire nreset,
    input wire rx,
    output reg [7:0] data,
    output reg interrupt = 0,
    input wire interrupt_clear
);
    reg [CLOCK_COUNTER_BITS - 1:0] counter;
    reg [3:0] bit_counter = 0;
    reg start = 0;

    always @(posedge clk) begin
        if (!nreset) begin
            interrupt <= 0;
            start <= 0;
        end
        else if (start == 0) begin
            if (interrupt_clear)
                interrupt <= 0;
            if (!rx) begin
                start <= 1;
                counter <= CLOCK_DIV / 2 - 1;
            end
        end
        else begin
            if (counter != 0)
                counter <= counter - 1;
            else begin
                if (bit_counter == 0) begin
                    start <= !rx;
                    if (!rx) begin
                        counter <= CLOCK_DIV - 1;
                        bit_counter <= 9;
                    end
                end
                else begin
                    if (bit_counter != 1) begin
                        counter <= CLOCK_DIV - 1;
                        data <= {rx, data[7:1]};
                    end
                    else begin
                        // stop bit
                        if (rx)
                            interrupt <= 1;
                        start <= 0;
                    end
                    bit_counter <= bit_counter - 1;
                end
            end
        end
    end
endmodule
