module top
#(parameter ROM_BITS = 10, RAM_BITS = 10, RODATA_BITS = 8, I2C_PORTS_BITS = 1)
(
	input wire clk,
    output wire nerror,
    output wire nhlt,
    output wire nwfi,
    output wire led,
    input wire rx,
    output wire tx,
    inout wire [(1 << I2C_PORTS_BITS) - 1:0] scl_io,
    inout wire [(1 << I2C_PORTS_BITS) - 1:0] sda_io
);
	wire clk270, clk180, clk90, clk0, usr_ref_out;
	wire usr_pll_lock_stdy, usr_pll_lock;

	CC_PLL #(
		.REF_CLK(10.0),      // reference input in MHz
		.OUT_CLK(40.0),     // pll output frequency in MHz
		.PERF_MD("ECONOMY"), // LOWPOWER, ECONOMY, SPEED
		.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
		.CI_FILTER_CONST(2), // optional CI filter constant
		.CP_FILTER_CONST(4)  // optional CP filter constant
	) pll_inst (
		.CLK_REF(clk), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
		.USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
		.CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clk0), .CLK_REF_OUT(usr_ref_out)
	);

	main #(.ROM_BITS(ROM_BITS), .RAM_BITS(RAM_BITS), .RODATA_BITS(RODATA_BITS), .I2C_PORTS_BITS(I2C_PORTS_BITS))
	     m(.clk(clk0), .nerror(nerror), .nwfi(nwfi), .nhlt(nhlt), .led(led), .rx(rx), .tx(tx), .scl_io(scl_io), .sda_io(sda_io));

endmodule
