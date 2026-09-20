module frequency_counter_tb;
    reg clk, iclk, nreset;
    wire [27:0] code;
    wire interrupt;
    reg interrupt_clear;

    frequency_counter fc(.clk(clk), .nreset(nreset), .iclk(iclk), .clk_frequency_minus1(28'd99), .code(code), .interrupt(interrupt), .interrupt_clear(interrupt_clear));

    always #2 clk = ~clk;
    always #1 iclk = ~iclk;

    initial begin
        $monitor("time=%t nreset=%d code=%d interrupt=%d", $time, nreset, code, interrupt);
        clk = 0;
        iclk = 0;
        interrupt_clear = 0;
        nreset = 0;
        #10
        nreset = 1;
        #500
        interrupt_clear = 1;
        #20
        interrupt_clear = 0;
        #500
        interrupt_clear = 1;
        #20
        interrupt_clear = 0;
        $finish;
    end
endmodule
