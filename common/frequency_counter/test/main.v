module main
(
	input wire clk,
	input wire iclk,
   output wire [27:0] code,
   input wire [25:0] clk_frequency_div4,
   output wire interrupt,
   input wire interrupt_clear
);

frequency_counter fc(.clk(clk), .iclk(iclk), .clk_frequency_div4(clk_frequency_div4), .code(code), .interrupt(interrupt), .interrupt_clear(interrupt_clear));

endmodule
