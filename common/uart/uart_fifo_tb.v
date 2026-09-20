module uart_fifo_tb;
    reg clk;
    wire tx;
    reg [7:0] data_in;
    wire [7:0] data_out;
    reg req, nwr;
    wire ack;
    wire full, empty;
    reg nreset;

    uart_fifo #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4))
        ufifo(.clk(clk), .tx(tx), .rx(tx), .data_in(data_in), .data_out(data_out), .req(req), .nwr(nwr), .ack(ack),
                .nreset(nreset), .full(full), .empty(empty));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("uart_fifo_tb.vcd");
        $dumpvars(0, uart_fifo_tb);
        $monitor("time=%t clk=%d nreset=%d tx=%d req=%d nwr=%d ack=%d data_in=%x data_out=%x full=%d empty=%d",
                    $time, clk, nreset, tx, req, nwr, ack, data_in, data_out, full, empty);
        clk = 0;
        data_in = 8'h5A;
        req = 0;
        nwr = 1;
        nreset = 0;
        #5
        nreset = 1;
        #5
        nwr = 0;
        req = 1;
        #5
        req = 0;
        data_in = 8'hA5;
        #5
        req = 1;
        #5
        req = 0;
        #500
        nwr = 1;
        req = 1;
        #5
        req = 0;
	    #5
        req = 1;
        #5
        req = 0;
        data_in = 8'h99;
        #5
        nwr = 0;
        req = 1;
        #5
        req = 0;
        #200
        nwr = 1;
        req = 1;
        #5
        req = 0;
        #5
        $finish;
    end
endmodule
