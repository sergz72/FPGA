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
    output wire [3:0] fcode,
    input wire [2:0] sel,
    output wire interrupt
);
    wire [27:0] frequency_code;

    frequency_counter fc(.clk(clk), .iclk(comp_data_hi), .clk_frequency_div4(CLK_FREQUENCY_DIV4), .code(frequency_code), .interrupt(interrupt),
                            .interrupt_clear(sel[2]));

    logic_probe_led #(.COUNTER_WIDTH(19))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .led_one(led_one), .led_zero(led_zero), .led_floating(led_floating),
                .led_pulse(led_pulse));

    function [3:0] code_sel(input [2:0] sel);
        case (sel)
            0: code_sel = frequency_code[3:0];
            1: code_sel = frequency_code[7:4];
            2: code_sel = frequency_code[11:8];
            3: code_sel = frequency_code[15:12];
            4: code_sel = frequency_code[19:16];
            5: code_sel = frequency_code[23:20];
            6: code_sel = frequency_code[27:24];
            7: code_sel = 0;
        endcase
    endfunction

    assign fcode = code_sel(sel);

endmodule
