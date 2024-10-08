module div_tb;
    localparam MAX_COUNT = 2000;

    reg clk, nreset, start, signed_ope, fail;
    reg [31:0] dividend, divisor;
    wire [31:0] quotient, remainder;
    reg [31:0] exp_quotient, exp_remainder;
    wire ready;
    reg [10:0] count;

    div d(.clk(clk), .nrst(nreset), .dividend(dividend), .divisor(divisor), .start(start), .signed_ope(signed_ope),
            .quotient(quotient), .remainder(remainder), .ready(ready));

    always #1 clk <= !clk;

    initial begin
        $dumpfile("div_tb.vcd");
        $dumpvars(0, fiv_tb);
        $monitor("time=%t clk=%d nreset=%d start=%d signed_ope=%d dividend=%d divisor=%d quotient=%d remainder=%d ready=%d",
                    $time, clk, nreset, start, signed_ope, dividend, divisor, quotient, remainder, ready);
        
        clk = 0;
        nreset = 0;
        start = 0;
        signed_ope = 0;

        #5
        nreset = 1;

        fail = 0;

        for (count = 0; count < MAX_COUNT; count++) begin
            #1
            dividend = $random;
            divisor  = $random;
            exp_quotient = dividend / divisor;
            exp_remainder = dividend % divisor;
            start = 1;
            #4
            start = 0;
            #100
            fail = !ready || (quotient != exp_quotient) || (remainder != exp_remainder);
            if (fail)
                count = MAX_COUNT;
        end

        if (fail) begin
             $display("unsigned div FAIL");
            $finish;
        end
        else
            $display("unsigned div PASS");

        signed_ope = 1;

        for (count = 0; count < MAX_COUNT; count++) begin
            #1
            dividend = $random;
            divisor  = $random;
            exp_quotient = $signed(dividend) / $signed(divisor);
            exp_remainder = $signed(dividend) % $signed(divisor);
            start = 1;
            #4
            start = 0;
            #100
            fail = !ready || (quotient != exp_quotient) || (remainder != exp_remainder);
            if (fail)
                count = MAX_COUNT;
        end

        if (fail) begin
             $display("signed div FAIL");
        end
        else
            $display("signed div PASS");

        $finish;
    end
endmodule
