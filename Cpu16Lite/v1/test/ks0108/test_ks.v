module ks0108_tb;
    reg clk;
    wire hlt;
    wire error;
    wire scl_io;
    wire sda_io;
    // ks0108
    wire ks_dc;
    wire ks_e;
    wire ks_cs1;
    wire ks_cs2;
    wire [7:0] ks_data;
    wire reset;
    reg button;

    main #(.CLK_FREQUENCY_DIV4(150000), .TIMER_BITS(16), .RESET_DELAY_BIT(4), .CPU_CLOCK_BIT(1))
         m(.clk(clk), .hlt(hlt), .error(error), .scl_io(scl_io), .sda_io(sda_io), .ks_dc(ks_dc), .ks_e(ks_e), .ks_cs1(ks_cs1),
            .ks_cs2(ks_cs2), .ks_data(ks_data), .button(button), .reset(reset));

    pullup(scl_io);
    pullup(sda_io);

    always #1 clk = ~clk;

    initial begin
//        $dumpfile("vf_tb.vcd");
//        $dumpvars(0, vf_tb);
        $monitor("time=%t reset=%d hlt=%d error=%d scl_io=%d sda_io=%d ks_dc=%d ks_e=%d ks_cs1=%d ks_cs2=%d ks_data=%x",
                 $time, reset, hlt, error, scl_io, sda_io, ks_dc, ks_e, ks_cs1, ks_cs2, ks_data);
        clk = 0;
        button = 1;
        #300000
        $finish;
    end
endmodule
