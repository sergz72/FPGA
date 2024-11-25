module main
#(parameter CLK_FREQUENCY_DIV4 = 27000000/4)
(
    input wire clk,
    input wire comp_data_hi,
    input wire comp_data_lo,
    output wire led_one,
    output wire led_zero,
    output wire led_floating,
    output wire led_pulse,
    output wire tx
);
    wire interrupt;
    wire busy;
    wire [27:0] frequency_code;

    frequency_counter fc(.clk(clk), .iclk(comp_data_hi), .clk_frequency_div4(CLK_FREQUENCY_DIV4), .code(frequency_code), .interrupt(interrupt),
                            .interrupt_clear(busy));

    logic_probe_led #(.COUNTER_WIDTH(19))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .led_one(led_one), .led_zero(led_zero), .led_floating(led_floating),
                .led_pulse(led_pulse));

    uart4 u(.clk(clk), .tx(tx), .data({4'b0000, frequency_code}), .send(interrupt), .busy(busy));

endmodule
