module main_tb;
    wire nhlt, nerror, led;
    reg clk;

    main #(.ROM_BITS(8)) m(.clk(clk), .nhlt(nhlt), .nerror(nerror), .led(led));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nhlt=%d nerror=%d led=%d", $time, clk, nhlt, nerror, led);
        clk = 0;
        #1000
        $finish;
    end
endmodule
