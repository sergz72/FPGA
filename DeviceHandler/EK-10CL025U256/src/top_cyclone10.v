module top_cyclone10
#(parameter MODULE_ID_BITS = 3, NUM_MODULES = 5, SPI_BITS = 2, MODULE_IO_BITS = 10, MODULE4_IO_BITS = 2, MODULE5_IO_BITS = 2,
  NUM_LEDS = 4)
(
    input wire clk,
    input wire nreset,
    //i2c cpu->fpga
    input wire sda_oe,
    output wire sda_out,
    input wire scl_oe,
    output wire scl_out,
    // spi cpu->fpga
    input wire [SPI_BITS - 1:0] sdi,
    output wire [SPI_BITS - 1:0] sdo,
    input wire sclk,
    input wire sncs,
    //address
    input wire [MODULE_ID_BITS - 1: 0] module_id,
    //i2c fpga->modules
    inout wire [NUM_MODULES - 1: 0] sda,
    inout wire [NUM_MODULES - 1: 0] scl,
    //io fpga->modules
    inout wire [MODULE_IO_BITS - 1:0] module1_io,
    inout wire [MODULE_IO_BITS - 1:0] module2_io,
    inout wire [MODULE_IO_BITS - 1:0] module3_io,
    inout wire [MODULE4_IO_BITS - 1:0] module4_io,
    inout wire [MODULE5_IO_BITS - 1:0] module5_io,
    // leds
    output wire [NUM_LEDS - 1:0] leds
);
	  wire pll_clk, locked;
	 
	  pll p(.areset(0), .inclk0(clk), .c0(pll_clk), .locked(locked));

    main #(.MODULE_ID_BITS(MODULE_ID_BITS), .NUM_MODULES(NUM_MODULES), .SPI_BITS(SPI_BITS), .MODULE_IO_BITS(MODULE_IO_BITS), .MODULE4_IO_BITS(MODULE4_IO_BITS),
            .MODULE5_IO_BITS(MODULE5_IO_BITS), .NUM_LEDS(NUM_LEDS))
         m(.clk(pll_clk), .nreset(nreset), .sda_oe(sda_oe), .sda_out(sda_out), .scl_oe(scl_oe), .scl_out(scl_out), .sdi(sdi), .sdo(sdo), .sclk(sclk), .sncs(sncs),
           .module_id(module_id), .sda(sda), .scl(scl), .module1_io(module1_io), .module2_io(module2_io), .module3_io(module3_io), .module4_io(module4_io),
           .module5_io(module5_io), .leds(leds));

endmodule