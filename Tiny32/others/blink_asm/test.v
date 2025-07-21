module test;
    reg clk;
    wire nhlt, nerror, nwfi;
    wire [31:0] address;
    wire led;

    wire tx, rx, busy;
    reg send;
    reg [7:0] tx_data;
    wire [7:0] data_out;
    wire interrupt;
    reg interrupt_clear, nreset;

    main
         m(.clk(clk), .nhlt(nhlt), .nerror(nerror), .nwfi(nwfi), .address(address), .led(led), .tx(tx), .rx(rx));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(rx), .data(tx_data), .send(send), .busy(busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(tx), .data(data_out), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);
        $monitor("time=%t address=0x%x nhlt=%d nerror=%d nwfi=%d led=%d rx=%d tx=%d", $time, address, nhlt, nerror, nwfi, led, rx, tx);
        clk = 0;
        interrupt_clear = 0;
        nreset = 0;
        #100
        nreset = 1;
        tx_data = 8'h5A;
        #5
        send = 1;
        #5
        send = 0;
        #1000
        tx_data = 8'h33;
        #5
        send = 1;
        #5
        send = 0;
        #2000
        interrupt_clear = 1;
        #5
        interrupt_clear = 0;
        #2000000
        $finish;
    end
endmodule
