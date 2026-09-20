module uart1_tb;
    reg clk;
    wire tx;
    reg [7:0] data_in;
    wire [7:0] data_out;
    reg send;
    wire busy;
    wire interrupt;
    reg interrupt_clear, nreset;

    uart1tx #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4)) utx(.clk(clk), .tx(tx), .data(data_in), .send(send), .busy(busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4)) urx(.clk(clk), .rx(tx), .data(data_out), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("uart1_tb.vcd");
        $dumpvars(0, uart1_tb);
        $monitor("time=%t clk=%d nreset=%d tx=%d busy=%d data_in=%x data_out=%x interrupt=%d interrupt_clear=%d",
                    $time, clk, nreset, tx, busy, data_in, data_out, interrupt, interrupt_clear);
        clk = 0;
        data_in = 8'h5A;
        send = 0;
        interrupt_clear = 0;
        nreset = 0;
        #5
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
        #5
        interrupt_clear = 0;
        #5
        $finish;
    end
endmodule
