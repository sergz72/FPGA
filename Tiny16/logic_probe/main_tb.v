module main_tb;
    wire nhlt, nwfi, led;
    reg clk, clk_probe;
    wire scl;
    wire sda;
    reg button1, button2, comp_out_hi, comp_out_lo;
    wire [4:0] dac1_code, dac2_code;
    wire dout;

    main #(.RESET_BIT(2), .TIME_PERIOD(5000)) m(.clk(clk), .nhlt(nhlt), .nwfi(nwfi), .scl(scl), .sda(sda), .button1(button1), .button2(button2),
            .dac1_code(dac1_code), .dac2_code(dac2_code), .comp_out_hi(comp_out_hi), .comp_out_lo(comp_out_lo), .clk_probe(clk_probe),
            .dout(dout));

    pullup(scl);
    pullup(sda);

    always #1 clk <= ~clk;
    always #1 clk_probe <= ~clk_probe;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nhlt=%d nwfi=%d scl=%d sda=%d button1=%d button2=%d dac1_code=%d dac2_code=%d",
                    $time, clk, nhlt, nwfi, scl, sda, button1, button2, dac1_code, dac2_code);
        clk = 0;
        clk_probe = 0;
        button1 = 1;
        button2 = 1;
        comp_out_hi = 0;
        comp_out_lo = 0;
        #10000000
        $finish;
    end
endmodule
