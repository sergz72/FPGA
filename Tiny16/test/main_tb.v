module main_tb;
    wire nhlt, nwfi, led;
    reg clk;

    main #(.RESET_BIT(2), .TIMER_BIT(7), .COUNTER_BITS(8)) m(.clk(clk), .nhlt(nhlt), .nwfi(nwfi), .led(led));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nhlt=%d nwfi=%d led=%d", $time, clk, nhlt, nwfi, led);
        clk = 0;
        #10000
        $finish;
    end
endmodule
