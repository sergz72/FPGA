module logicProbe1
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
    reg pulse_reset;
    
    always @(posedge comp_data_hi or negedge pulse_reset) begin
        pulse <= pulse_reset;
    end

    always @(posedge clk) begin
        if (counter == 0) begin
            pulse_brightness <= pulse ? 255 : 0;
            pulse_reset <= 0;
            one_brightness <= one_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-8];
            one_counter <= 0;
            zero_brightness <= zero_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-8];
            zero_counter <= 0;
            floating_brightness <= floating_counter[COUNTER_WIDTH-1:COUNTER_WIDTH-8];
            floating_counter <= 0;
        end
        else begin
            pulse_reset <= 1;
            if (comp_data_hi == 1)
                one_counter <= one_counter + 1;
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

module logicProbeDAC
(
    input wire [1:0] mode,
    output wire [3:0] dac_value // R2R DAC 4 bit
);

    function [3:0] build_dac_value(input [1:0] mode);
        case (mode)
            0: build_dac_value = 7; // 1.4v - for 1.8v logic
            1: build_dac_value = 10; // 2.0v - for 2.5v logic
            default: build_dac_value = 12; // 2.4v - for 3.3/5v logic
        endcase
    endfunction

    assign dac_value = build_dac_value(mode);

endmodule