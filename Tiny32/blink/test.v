module test;
    reg clk;
    wire hlt, error, wfi;
    wire [31:0] address;
    wire led;

    main #(.TIMER_BITS(10), .RESET_DELAY_BIT(4), .CPU_CLOCK_BIT(1))
         m(.clk(clk), .hlt(hlt), .error(error), .wfi(wfi), .address(address), .led(led));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);
        $monitor("time=%t address=0x%x hlt=%d error=%d wfi=%d led=%d", $time, address, hlt, error, wfi, led);
        clk = 0;
        #300000
        $finish;
    end
endmodule
