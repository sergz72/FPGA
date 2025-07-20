module test;
    reg clk;
    wire hlt, error, wfi;
    wire led;
    wire tx, rx;
    reg [7:0] data_in;
    wire interrupt;
    reg interrupt_clear, nreset;
    reg send;
    wire busy;

    main #(.TIMER_BITS(10), .RESET_DELAY_BIT(3), .UART_CLOCK_DIV(8), .UART_CLOCK_COUNTER_BITS(4))
         m(.clk(clk), .wfi(wfi), .error(error), .hlt(hlt), .led(led), .tx(tx), .rx(rx));

    uart1tx #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4)) utx(.clk(clk), .tx(rx), .data(data_in), .send(send), .busy(busy), .nreset(nreset));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t led=%d rx=%d tx=%d", $time, led, rx, tx);
        clk = 0;
        data_in = 8'h5A;
        send = 0;
        interrupt_clear = 0;
        nreset = 0;
        #100
        nreset = 1;
        #5
        send = 1;
        #5
        send = 0;
        #200
        interrupt_clear = 1;
        #5
        interrupt_clear = 0;
        data_in = 8'hA5;
        send = 1;
        #5
        send = 0;
        #200
        interrupt_clear = 1;
        #1500000
        $finish;
    end
endmodule
