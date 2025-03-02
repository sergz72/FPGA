module pwm_tb;
    reg clk, nreset;
    wire out;

    pwm #(.WIDTH(3)) p(.clk(clk), .nreset(nreset), .period(3'h5), .duty(3'h2), .out(out));

    always #1 clk = ~clk;

    initial begin
        $monitor("time=%t nreset=%d clk=%d out=%d", $time, nreset, clk, out);
        clk = 0;
        nreset = 0;
        #10
        nreset = 1;
        #100
        $finish;
    end
endmodule
