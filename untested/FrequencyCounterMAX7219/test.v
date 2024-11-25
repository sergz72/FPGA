module frequencyCounterMax7219_tb;
    reg clk, iclk, reset;
    wire clko, dout, load;

    frequencyCounterMax7219 #(.RESET_VALUE_DIV2(28'd10000))
        fc(.clk(clk), .iclk(iclk), .reset(reset), .clko(clko), .dout(dout), .load(load));

    always #1 clk = ~clk;
    always #2 iclk = ~iclk;

    initial begin
        $monitor("time=%t reset=%d clko=%d dout=%d load=%d", $time, reset, clko, dout, load);
        clk = 0;
        iclk = 0;
        reset = 1;
        #10
        reset = 0;
        #10
        reset = 1;
        #100000
        $finish;
    end
endmodule
