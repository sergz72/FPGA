module main_tb;
    wire nerror, nhlt, led;
    reg clk;

    main m(.clk(clk), .nerror(nerror), .nhlt(nhlt), .led(led));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nerror=%d nhlt=%d led=%d", $time, clk, nerror, nhlt, led);
        clk = 0;
        #10000
        $finish;
    end
endmodule
