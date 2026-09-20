module pwm2_tb;
    reg clk, nreset, nwr;
    wire out, wack;

    pwm2 #(.WIDTH(3)) p(.clk(clk), .nreset(nreset), .nwr(nwr), .wack(wack), .period(3'h1), .cmp(3'h1), .out(out));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("pwm2_tb.vcd");
        $dumpvars(0, pwm2_tb);
        $monitor("time=%t nreset=%d clk=%d nwr=%d wack=%d out=%d", $time, nreset, clk, nwr, wack, out);
        clk = 0;
        nreset = 0;
        nwr = 1;
        #10
        nreset = 1;
        #10
        nwr = 0;
        #10
        nwr = 1;
        #100
        $finish;
    end
endmodule
