module test;
    wire hlt, error, wfi, led;
    reg clk;

    main #(.TIMER_BITS(10), .RESET_DELAY_BIT(3)) m(.clk(clk), .wfi(wfi), .error(error), .hlt(hlt), .led(led));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);
        $monitor("time=%t clk=%d hlt=%d error=%d wfi=%d led=%d",
                 $time, clk, hlt, error, wfi, led);
        clk = 0;
        #100000
        $finish;
    end

endmodule
