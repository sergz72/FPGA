module logic_probe_spi_dac_tb;
    reg clk, comp_data_hi, comp_data_lo, spi_rx, spi_sck, spi_cs;
    wire spi_tx;
    wire [3:0] dac;
    wire interrupt;

    logic_probe_spi_dac #(.FREQ_COUNTERS_WIDTH(10), .TIME_COUNTERS_WIDTH(10), .TIME_PERIOD(512))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .spi_tx(spi_tx), .spi_rx(spi_rx), .spi_sck(spi_sck), .spi_cs(spi_cs),
              .interrupt(interrupt), .dac_out(dac));

    always #1 clk <= ~clk;

    integer i;
    initial begin
        $dumpfile("logic_probe_spi_dac_tb.vcd");
        $dumpvars(0, logic_probe_spi_dac_tb);
        $monitor("time=%t clk=%d interrupt=%d spi_tx=%d spi_rx=%d spi_clk=%d spi_cs=%d dac_out=%d",
                    $time, clk, interrupt, spi_tx, spi_rx, spi_sck, spi_cs, dac);
        clk = 0;
        comp_data_hi = 1;
        comp_data_lo = 1;
        spi_cs = 1;
        spi_sck = 0;
        spi_rx = 1;
        #10
        spi_cs = 0;
        #10
        spi_cs = 1;
        #100
        comp_data_hi = 0;
        #100
        comp_data_hi = 1;
        comp_data_lo = 0;
        #100
        comp_data_lo = 1;
        #1000
        spi_cs = 0;
        for (i = 0; i < 30+24; i = i + 1) begin
            #10
            spi_sck = 1;
            #10
            spi_sck = 0;
        end
        #10
        spi_cs = 1;
        #100
        $finish;
    end
endmodule
