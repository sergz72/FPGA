module main_tb;
    wire nerror, nhlt, nwfi, led, tx, rx, busy;
    reg clk, send, nreset;
    reg [7:0] tx_data;

    main m(.clk(clk), .nerror(nerror), .nhlt(nhlt), .nwfi(nwfi), .led(led), .tx(tx), .rx(rx));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(rx), .data(tx_data), .send(send), .busy(busy), .nreset(nreset));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nerror=%d nhlt=%d nwfi=%d led=%d tx=%d rx=%d", $time, clk, nerror, nhlt, nwfi, led, tx, rx);
        clk = 0;
        nreset = 0;
        #2000
        nreset = 1;
        tx_data = 8'h69; 
        #5
        send = 1;
        #5
        send = 0;
        #1000
        tx_data = 8'h0D;
        #5
        send = 1;
        #5
        send = 0;
        #3000000
        $finish;
    end
endmodule
