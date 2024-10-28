module uart1_tb2;
    parameter CLOCK_DIV = 8;
    parameter CLOCK_DIV2 = CLOCK_DIV * 2;
    parameter CLOCK_COUNTER_BITS = 4;
    reg clk;
    reg tx;
    wire [7:0] data_out;
    wire interrupt;
    reg interrupt_clear, nreset;

    uart1rx #(.CLOCK_DIV(CLOCK_DIV), .CLOCK_COUNTER_BITS(CLOCK_COUNTER_BITS))
            urx(.clk(clk), .rx(tx), .data(data_out), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    always #1 clk = ~clk;

    integer i;
    initial begin
        $dumpfile("uart1_tb2.vcd");
        $dumpvars(0, uart1_tb2);
        $monitor("time=%t clk=%d nreset=%d tx=%d data_out=%x interrupt=%d interrupt_clear=%d", $time, clk, nreset, tx, data_out, interrupt, interrupt_clear);
        clk = 0;
        interrupt_clear = 0;
        nreset = 0;
        tx = 1;
        #CLOCK_DIV
        nreset = 1;
        #CLOCK_DIV
        for (i = 0; i <= 255; i = i + 1) begin
            tx = 0;
            #CLOCK_DIV2
            interrupt_clear = 0;
            tx = i[0];
            #CLOCK_DIV2
            tx = i[1];
            #CLOCK_DIV2
            tx = i[2];
            #CLOCK_DIV2
            tx = i[3];
            #CLOCK_DIV2
            tx = i[4];
            #CLOCK_DIV2
            tx = i[5];
            #CLOCK_DIV2
            tx = i[6];
            #CLOCK_DIV2
            tx = i[7];
            #CLOCK_DIV2
            tx = 1;
            #CLOCK_DIV2;
            interrupt_clear = 1;
        end
        $finish;
    end
endmodule
