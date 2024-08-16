module frequency_counter
#(parameter CLK_COUNTER_WIDTH = 28, COUNTER_WIDTH = 28)
(
    input wire clk,
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
        if (clk_counter[CLK_COUNTER_WIDTH - 1:2] == clk_frequency_div4) begin
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

module frequency_counter_tb;
    reg clk, iclk;
    wire [27:0] code;
    wire interrupt;
    reg interrupt_clear;

    frequency_counter fc(.clk(clk), .iclk(iclk), .clk_frequency_div4(26'd100), .code(code), .interrupt(interrupt), .interrupt_clear(interrupt_clear));

    always #2 clk = ~clk;
    always #1 iclk = ~iclk;

    initial begin
        $monitor("time=%t code=%d interrupt=%d", $time, code, interrupt);
        clk = 0;
        iclk = 0;
        interrupt_clear = 0;
        #1700
        interrupt_clear = 1;
        #20
        interrupt_clear = 0;
        #1700
        interrupt_clear = 1;
        #20
        interrupt_clear = 0;
        $finish;
    end
endmodule
