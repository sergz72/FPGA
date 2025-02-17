module main_tb;
    wire nerror, nhlt, nwfi, led;
    reg clk;

    main m(.clk(clk), .nerror(nerror), .nhlt(nhlt), .nwfi(nwfi), .led(led));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nerror=%d nhlt=%d nwfi=%d led=%d", $time, clk, nerror, nhlt, nwfi, led);
        clk = 0;
        #1000000
        $finish;
    end
endmodule
