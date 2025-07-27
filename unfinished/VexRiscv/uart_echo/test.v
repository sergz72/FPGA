module test;
    wire nerror, nwfi, led, rx, tx;
    reg clk;
    reg [7:0] data_in;
    wire interrupt;
    reg interrupt_clear, nreset;
    reg send;
    wire busy;

    main #(.RESET_BIT(3), .MHZ_TIMER_BITS(2), .MHZ_TIMER_VALUE(2), .UART_CLOCK_DIV(8), .UART_CLOCK_COUNTER_BITS(4))
        m(.clk(clk), .nwfi(nwfi), .nerror(nerror), .led(led), .rx(rx), .tx(tx));

    uart1tx #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4)) utx(.clk(clk), .tx(rx), .data(data_in), .send(send), .busy(busy), .nreset(nreset));

    always #1 clk <= ~clk;
    
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
        #150000
        $finish;
    end

endmodule
