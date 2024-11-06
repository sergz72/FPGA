module main_tb;
    wire nerror, nhlt, nwfi, led, tx, rx, busy;
    wire scl_io0, sda_io0, scl_io1, sda_io1;
    reg clk, send, nreset;
    reg [7:0] tx_data;

    main #(.I2C_PORTS_BITS(1)) m(.clk(clk), .nerror(nerror), .nhlt(nhlt), .nwfi(nwfi), .led(led), .tx(tx), .rx(rx), .scl_io({scl_io1, scl_io0}), .sda_io({sda_io1, sda_io0}));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(rx), .data(tx_data), .send(send), .busy(busy), .nreset(nreset));

    pullup(scl_io0);
    pullup(sda_io0);
    pullup(scl_io1);
    pullup(sda_io1);

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nerror=%d nhlt=%d nwfi=%d led=%d tx=%d rx=%d scl_io0=%d sda_io0=%d scl_io1=%d sda_io1=%d", $time, clk, nerror, nhlt, nwfi, led, tx, rx,
                  scl_io0, sda_io0, scl_io1, sda_io1);
        clk = 0;
        nreset = 0;
        #200
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
        #200000
        $finish;
    end
endmodule
