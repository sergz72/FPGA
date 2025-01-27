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
