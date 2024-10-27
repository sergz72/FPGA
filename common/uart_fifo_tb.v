module uart_fifo_tb;
    reg clk;
    wire tx;
    reg [7:0] data_in;
    wire [7:0] data_out;
    reg nwr, nrd;
    wire full, empty;
    reg nreset;

    uart_fifo #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4))
        ufifo(.clk(clk), .tx(tx), .rx(tx), .data_in(data_in), .data_out(data_out), .nwr(nwr), .nrd(nrd), .nreset(nreset),
                .full(full), .empty(empty));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("uart_fifo_tb.vcd");
        $dumpvars(0, uart_fifo_tb);
        $monitor("time=%t clk=%d nreset=%d tx=%d nwr=%d nrd=%d data_in=%x data_out=%x full=%d empty=%d",
                    $time, clk, nreset, tx, nwr, nrd, data_in, data_out, full, empty);
        clk = 0;
        data_in = 8'h5A;
        nrd = 1;
        nwr = 1;
        nreset = 0;
        #5
        nreset = 1;
        #5
        nwr = 0;
        #5
        nwr = 1;
        data_in = 8'hA5;
        #5
        nwr = 0;
        #5
        nwr = 1;
        #500
        nrd = 0;
        #5
        nrd = 1;
	#5
        nrd = 0;
        #5
        nrd = 1;
        data_in = 8'h99;
        #5
        nwr = 0;
        #5
        nwr = 1;
        #200
        nrd = 0;
        #5
        nrd = 1;
        #5
        $finish;
    end
endmodule
