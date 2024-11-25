module logicProbe1_tb;
    reg clk;
    reg comp_data_hi, comp_data_lo;
    reg [1:0] mode;
    wire[3:0] dac_value;
    wire led_one, led_zero, led_floating, led_pulse;

    logicProbe1 #(.COUNTER_WIDTH(16))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .led_one(led_one), .led_zero(led_zero), .led_floating(led_floating),
                .led_pulse(led_pulse));

    logicProbeDAC dac(.mode(mode), .dac_value(dac_value));

    always #1 clk = ~clk;

    initial begin
        $monitor("time=%t led_one=%d led_zero=%d led_floating=%d led_pulse=%d dac_value=%d",
                    $time, led_one, led_zero, led_floating, led_pulse, dac_value);
        clk = 0;
        mode = 0;
        comp_data_hi = 0;
        comp_data_lo = 0;
        #100
        comp_data_hi = 1;
        #1000
        comp_data_hi = 0;
        comp_data_lo = 1;
        #1000
        comp_data_lo = 0;
        #1000000
        $finish;
    end
endmodule
