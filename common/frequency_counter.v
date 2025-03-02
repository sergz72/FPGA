module frequency_counter
#(parameter CLK_COUNTER_WIDTH = 28, COUNTER_WIDTH = 28)
(
    input wire clk,
    input wire nreset,
    input wire iclk,
    input wire [CLK_COUNTER_WIDTH - 3:0] clk_frequency_div4,
    output reg [COUNTER_WIDTH - 1:0] code,
    output reg interrupt = 0,
    input wire interrupt_clear
);
    reg [CLK_COUNTER_WIDTH - 1:0] clk_counter = 0;
    reg [COUNTER_WIDTH - 1:0] counter = 0;
    reg reset = 0;
    reg stop = 0;
    reg [1:0] reset_counter = 0;

    always @(posedge iclk or posedge reset) begin
        if (reset == 1)
            counter <= 0;
        else if (stop == 0)
            counter <= counter + 1;
    end

    always @(posedge clk) begin
        if (!nreset) begin
            clk_counter <= 0;
            reset <= 0;
            stop <= 0;
            reset_counter <= 0;
        end
        else if (clk_counter[CLK_COUNTER_WIDTH - 1:2] == clk_frequency_div4) begin
            case (reset_counter)
                0: stop <= 1;
                1: code <= counter;
                2: reset <= 1;
                3: begin
                    stop <= 0;
                    reset <= 0;
                    clk_counter <= 0;
                    interrupt <= 1;
                end
            endcase
            reset_counter <= reset_counter + 1;
        end
        else begin
            if (interrupt_clear == 1)
                interrupt <= 0;
            clk_counter <= clk_counter + 1;
        end
    end
endmodule
