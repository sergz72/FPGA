module main_tb;
    wire error, hlt, wfi;
    wire [`WIDTH - 1:0] mem_address;
    reg nreset, clk;

    main #(.WIDTH(`WIDTH)) m(.clk(clk), .nreset(nreset), .error(error), .hlt(hlt), .wfi(wfi), .mem_address(mem_address));

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nreset=%d error=%d hlt=%d wfi=%d mem_address=0x%x", $time, clk, nreset, error, hlt, wfi, mem_address);
        clk = 0;
        nreset = 0;
        #10
        nreset = 1;
        #2000
        $finish;
    end
endmodule
