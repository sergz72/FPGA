module logic_probe_tb;
    reg clk, clk_in, nreset, interrupt_clear;
    reg comp_data_hi, comp_data_lo;
    wire data, interrupt;

    logic_probe #(.COUNTERS_WIDTH(10), .TIME_PERIOD(512))
        probe(.clk(clk), .clk_in(clk_in), .nreset(nreset), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
              .data(data), .interrupt(interrupt), .interrupt_clear(interrupt_clear));

    always #1 clk <= ~clk;

    initial begin
        $dumpfile("logic_probe_tb.vcd");
        $dumpvars(0, logic_probe_tb);
        $monitor("time=%t clk_in=%d nreset=%d interrupt=%d interrupt_clear=%d data=%d",
                    $time, clk_in, nreset, interrupt, interrupt_clear, data);
        clk = 0;
        clk_in = 0;
        nreset = 0;
        comp_data_hi = 0;
        comp_data_lo = 0;
        interrupt_clear = 0;
        #10
        nreset = 1;
        #100
        comp_data_hi = 1;
        #100
        comp_data_hi = 0;
        comp_data_lo = 1;
        #100
        comp_data_lo = 0;
        #1000
        clk_in = 1;
        #10
        clk_in = 0;
        #10
        clk_in = 1;
        #10
        clk_in = 0;
        #10
        clk_in = 1;
        #10
        clk_in = 0;
        #10
        interrupt_clear = 1;
        #10
        interrupt_clear = 0;
        #100
        $finish;
    end
endmodule
