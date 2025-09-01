`timescale 1 ns / 1 ps

module test;
    reg clk;
    wire ntrap;
    wire led;

    main #(.RESET_BIT(3))
         m(.clk(clk), .ntrap(ntrap), .led(led));
    always #1 clk = ~clk;

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t led=%d", $time, led);
        clk = 0;
        #1500000
        $finish;
    end
endmodule
