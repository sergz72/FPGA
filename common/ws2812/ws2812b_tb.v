module ws2812b_tb;
    wire dout;
    reg clk, nreset;
    reg address;
    reg [7:0] r, g, b;
    reg mem_valid;
    wire mem_ready;

    ws2812b #(.MAX_ADDRESS(1), .COUNT_BITS(1))
        w(.clk(clk), .nreset(nreset), .address(address), .r(r), .g(g), .b(b), .mem_valid(mem_valid), .mem_ready(mem_ready), .dout(dout));
    
    always #1 clk = ~clk;

    initial begin
        $dumpfile("ws2812b_tb.vcd");
        $dumpvars(0, ws2812b_tb);
        $monitor("time=%t nreset=%d mem_valid=%d mem_ready=%d address=%d dout=%d", $time, nreset, mem_valid, mem_ready, address, dout);
        clk = 0;
        nreset = 0;
        #10
        address = 0;
        mem_valid = 0;
        nreset = 1;
        #5
        r = 'h11;
        g = 'h22;
        b = 'h33;
        mem_valid = 1;
        #4
        mem_valid = 0;
        #4
        address = 1;
        r = 'h44;
        g = 'h55;
        b = 'h66;
        mem_valid = 1;
        #4
        mem_valid = 0;
        #10000
        $finish;
    end
endmodule
