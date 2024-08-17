module logic_probe_led
/*
             ----------
DAC_OUT------|- COMP1 |
             |        |-----COMP_HI
IN------+----|+       |
        |    ----------
        |
        |    ----------
        +----|- COMP2 |
             |        |-----COMP_LO
0.4v---------|+       |
             ----------

COMP_LO = IN < 0.4v
COMP_HI = IN > DAC_OUT

*/
#(parameter COUNTER_WIDTH = 20) // 50 MHz clk, 50 Hz frequency
(
    input wire clk,
    input wire comp_data_hi,
    input wire comp_data_lo,
    output reg led_one,
    output reg led_zero,
    output reg led_floating,
    output reg led_pulse
);
    reg [COUNTER_WIDTH - 1:0] counter = 0;
    reg [COUNTER_WIDTH - 1:0] one_counter, zero_counter, floating_counter;
    reg [7:0] one_brightness, zero_brightness, floating_brightness, pulse_brightness;
    reg pulse = 0;

    always @(posedge clk) begin
        if (counter == 0) begin
            pulse_brightness <= pulse ? 255 : 0;
            pulse <= 0;
            one_brightness <= one_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-8];
            one_counter <= 0;
            zero_brightness <= zero_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-8];
            zero_counter <= 0;
            floating_brightness <= floating_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-8];
            floating_counter <= 0;
        end
        else begin
            if (comp_data_hi == 1) begin
                one_counter <= one_counter + 1;
                pulse <= 1;
            end
            if (comp_data_lo == 1)
                zero_counter <= zero_counter + 1;
            if (comp_data_hi == 0 && comp_data_lo == 0)
                floating_counter <= floating_counter + 1;

            if (counter[COUNTER_WIDTH - 9:COUNTER_WIDTH - 16] == 1) begin
                if (one_brightness != 0)
                    one_brightness <= one_brightness - 1;
                led_one <= one_brightness != 0;

                if (zero_brightness != 0)
                    zero_brightness <= zero_brightness - 1;
                led_zero <= zero_brightness != 0;

                if (floating_brightness != 0)
                    floating_brightness <= floating_brightness - 1;
                led_floating <= floating_brightness != 0;

                if (pulse_brightness != 0)
                    pulse_brightness <= pulse_brightness - 1;
                led_pulse <= pulse_brightness != 0;
            end
        end
        counter <= counter + 1;
    end
endmodule

module logic_probe_led_tb;
    reg clk;
    reg comp_data_hi, comp_data_lo;
    wire led_one, led_zero, led_floating, led_pulse;

    logic_probe_led #(.COUNTER_WIDTH(16))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .led_one(led_one), .led_zero(led_zero), .led_floating(led_floating),
                .led_pulse(led_pulse));

    always #1 clk = ~clk;

    initial begin
        $monitor("time=%t led_one=%d led_zero=%d led_floating=%d led_pulse=%d",
                    $time, led_one, led_zero, led_floating, led_pulse);
        clk = 0;
        comp_data_hi = 0;
        comp_data_lo = 0;
        #100
        comp_data_hi = 1;
        #10000
        comp_data_hi = 0;
        comp_data_lo = 1;
        #1000
        comp_data_lo = 0;
        #1000000
        $finish;
    end
endmodule
