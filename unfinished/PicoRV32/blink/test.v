`timescale 1 ns / 1 ps

module test;
    reg clk;
    wire ntrap;
    wire led;
    wire tx, rx;

    main #(.RESET_BIT(3), .TIMER_BITS(9))
         m(.clk(clk), .ntrap(ntrap), .led(led), .tx(tx), .rx(rx));
    always #1 clk = ~clk;

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t led=%d", $time, led);
        clk = 0;
        #500000
        $finish;
    end
endmodule
