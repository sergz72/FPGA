module main_tb;
    wire nerror, nhlt, nwfi, led, tx, rx, busy, interrupt;
    reg clk, send, interrupt_clear, nreset;
    reg [7:0] tx_data;
    wire [7:0] data_out;

    main m(.clk(clk), .nerror(nerror), .nhlt(nhlt), .nwfi(nwfi), .led(led), .tx(tx), .rx(rx));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(rx), .data(tx_data), .send(send), .busy(busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(tx), .data(data_out), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nerror=%d nhlt=%d nwfi=%d led=%d tx=%d rx=%d data_out=0x%x", $time, clk, nerror, nhlt, nwfi, led, tx, rx, data_out);
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
        #200000
        $finish;
    end
endmodule
