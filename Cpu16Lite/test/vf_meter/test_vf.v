module vf_tb;
    reg clk;
    wire hlt;
    wire error;
    wire scl_io;
    wire sda_io;
    // hd44780
    wire hd_dc;
    wire hd_e;
    wire [7:0] hd_data;
    wire led_one, led_zero, led_floating, led_pulse;
    reg button;

    main #(.CLK_FREQUENCY_DIV4(800000), .CLK_DIVIDER_BITS(9)) m(.clk(clk), .comp_data_hi(clk), .comp_data_lo(0), .hlt(hlt), .error(error), .scl_io(scl_io), .sda_io(sda_io), .hd_dc(hd_dc),
            .hd_e(hd_e), .hd_data(hd_data), .led_one(led_one), .led_zero(led_zero), .led_pulse(led_pulse), .led_floating(led_floating), .button(button));

    pullup(scl_io);
    pullup(sda_io);

    always #1 clk = ~clk;

    initial begin
//        $dumpfile("vf_tb.vcd");
//        $dumpvars(0, vf_tb);
        $monitor("time=%t hlt=%d error=%d scl_io=%d sda_io=%d hd_dc=%d hd_e=%d hd_data=%x", $time, hlt, error, scl_io, sda_io, hd_dc, hd_e, hd_data);
        clk = 0;
        button = 1;
        #12800000
        $finish;
    end
endmodule
