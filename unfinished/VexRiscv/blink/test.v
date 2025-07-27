module test;
    wire nerror, nwfi, led;
    reg clk;

    main #(.RESET_BIT(3), .MHZ_TIMER_BITS(2), .MHZ_TIMER_VALUE(2))
        m(.clk(clk), .nwfi(nwfi), .nerror(nerror), .led(led));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);
        $monitor("time=%t clk=%d nerror=%d nwfi=%d led=%d",
                 $time, clk, nerror, nwfi, led);
        clk = 0;
        #100000
        $finish;
    end

endmodule
