module main_tb;
    wire error, hlt, wfi;
    reg nreset, clk;

    main m(.clk(clk), .nreset(nreset), .error(error), .hlt(hlt), .wfi(wfi));

    always #1 clk <= ~clk;
    
    integer i;
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nreset=%d error=%d hlt=%d wfi=%d", $time, clk, nreset, error, hlt, wfi);
        clk = 0;
        nreset = 0;
        #10
        nreset = 1;

        for (i = 0; i < 5000; i = i + 1) begin
            #100
            if (hlt | wfi | error)
              $finish;
        end
        $finish;
    end
endmodule
