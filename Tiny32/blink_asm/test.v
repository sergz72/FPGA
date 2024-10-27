module test;
    reg clk;
    wire nhlt, nerror, nwfi;
    wire [31:0] address;
    wire led;

    main
         m(.clk(clk), .nhlt(nhlt), .nerror(nerror), .nwfi(nwfi), .address(address), .led(led));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);
        $monitor("time=%t address=0x%x nhlt=%d nerror=%d nwfi=%d led=%d", $time, address, nhlt, nerror, nwfi, led);
        clk = 0;
        #1000
        $finish;
    end
endmodule
