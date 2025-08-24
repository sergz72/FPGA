`timescale 1 ns / 1 ps

module top
#(parameter
UART_BAUD = 115200,
RESET_BIT = 10,
// 4k 32 bit words RAM
RAM_BITS = 12,
// 8k 32 bit words ROM
ROM_BITS = 13,
CLK_FREQUENCY = 50000000,
HYPERRAM_LATENCY = 6,
HYPERRAM_MEMORY_BITS = 21 // 2Mx32
)
(
    input wire clk,
    output wire ntrap,
    output wire [7:0] leds,
    output wire tx,
    input wire rx,
    output wire hyperram_clk,
    output wire hyperram_clkn,
    output wire hyperram_nreset,
    inout wire hyperram_rwds,
    inout wire [7:0] hyperram_data,
    output wire hyperram_ncs,
    output wire hyperram_debug_clk,
    output wire hyperram_debug_clkn,
    output wire hyperram_debug_nreset,
    output wire hyperram_debug_rwds,
    output wire [7:0] hyperram_debug_data,
    output wire hyperram_debug_ncs
);
    wire [7:0] hyperram_data_out, leds_main;
    wire hyperram_data_noe, hyperram_rwds_noe;
    wire hyperram_rwds_out;
	 
	 //wire main_clk;
	 wire c0;
	 
	 //reg [5:0] counter = 0;
	 
	 //assign main_clk = counter[5];

    assign hyperram_data = hyperram_data_noe ? 8'hz : hyperram_data_out;
    assign hyperram_rwds = hyperram_rwds_noe ? 1'bz : hyperram_rwds_out;
	 
	 assign hyperram_clkn = ~hyperram_clk;
	 
	 assign leds = ~leds_main;
	 
	 assign hyperram_debug_clk = hyperram_clk;
	 assign hyperram_debug_clkn = hyperram_clkn;
	 assign hyperram_debug_nreset = hyperram_nreset;
	 assign hyperram_debug_rwds = hyperram_rwds;
	 assign hyperram_debug_data = hyperram_data;
	 assign hyperram_debug_ncs = hyperram_ncs;

	 pll p(.inclk0(clk), .c0(c0)); // 150 MHz clock

    main #(.RESET_BIT(RESET_BIT), .CLK_FREQUENCY(CLK_FREQUENCY), .UART_BAUD(UART_BAUD), .HYPERRAM_LATENCY(HYPERRAM_LATENCY), .HYPERRAM_MEMORY_BITS(HYPERRAM_MEMORY_BITS))
         m(.clk(clk), .clk_hyperram(c0), .ntrap(ntrap), .leds(leds_main), .tx(tx), .rx(rx), .hyperram_clk(hyperram_clk), .hyperram_rwds_noe(hyperram_rwds_noe),
            .hyperram_nreset(hyperram_nreset), .hyperram_ncs(hyperram_ncs), .hyperram_rwds_in(hyperram_rwds), .hyperram_rwds_out(hyperram_rwds_out),
            .hyperram_data_in(hyperram_data), .hyperram_data_out(hyperram_data_out), .hyperram_data_noe(hyperram_data_noe));
    
	 //always @(posedge clk)
		//counter <= counter + 1;

endmodule
