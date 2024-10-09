module main_tb;
    wire nhlt, led;
    reg clk;

    main #(.ROM_BITS(8), .CPU_CLOCK_BIT(0), .RESET_BIT(3), .COUNTER_BITS(4)) m(.clk(clk), .nhlt(nhlt), .led(led));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nhlt=%d led=%d", $time, clk, nhlt, led);
        clk = 0;
        #1000
        $finish;
    end
endmodule
