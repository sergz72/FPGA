module ks0108_tb;
    reg clk;
    wire hlt;
    wire error;
    wire scl_io;
    wire sda_io;
    // ks0108
    wire ks_dc;
    wire ks_cs1;
    wire ks_cs2;
    wire ks_e;
    wire ks_reset;
    wire [7:0] ks_data;
    wire led_one, led_zero, led_floating, led_pulse;

    main m(.clk(clk), .comp_data_hi(clk), .comp_data_lo(0), .hlt(hlt), .error(error), .scl_io(scl_io), .sda_io(sda_io), .ks_dc(ks_dc),
            .ks_cs1(ks_cs1), .ks_cs2(ks_cs2), .ks_e(ks_e), .ks_reset(ks_reset), .ks_data(ks_data), .led_one(led_one), .led_zero(led_zero),
            .led_pulse(led_pulse), .led_floating(led_floating));

    always #1 clk = ~clk;

    initial begin
        $monitor("time=%t hlt=%d error=%d scl_io=%d sda_io=%d ks_dc=%d ks_cs1=%d ks_cs2=%d ks_e=%d ks_reset=%d ks_data=%x",
                 $time, hlt, error, scl_io, sda_io, ks_dc, ks_cs1, ks_cs2, ks_e, ks_reset, ks_data);
        clk = 0;
        #1000000
        $finish;
    end
endmodule
