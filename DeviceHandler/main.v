module main
#(parameter MODULE_ID_BITS = 3, NUM_MODULES = 5, SPI_BITS = 3, MODULE_IO_BITS = 10, MODULE4_IO_BITS = 2, MODULE5_IO_BITS = 2)
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
    inout wire [MODULE5_IO_BITS - 1:0] module5_io
);
    wire [SPI_BITS - 1:0] module_do [NUM_MODULES - 1: 0];
    wire [MODULE_IO_BITS - 1:0] module1_out;
    wire [MODULE_IO_BITS - 1:0] module2_out;
    wire [MODULE_IO_BITS - 1:0] module3_out;
    wire [MODULE_IO_BITS - 1:0] module4_out;
    wire [MODULE_IO_BITS - 1:0] module5_out;
    wire [MODULE_IO_BITS - 1:0] module1_oe;
    wire [MODULE_IO_BITS - 1:0] module2_oe;
    wire [MODULE_IO_BITS - 1:0] module3_oe;
    wire [MODULE_IO_BITS - 1:0] module4_oe;
    wire [MODULE_IO_BITS - 1:0] module5_oe;
    wire [MODULE_IO_BITS - 1:0] module4_in;
    wire [MODULE_IO_BITS - 1:0] module5_in;

    genvar i;
    generate
        for (i = 0; i < NUM_MODULES; i = i + 1) begin
            assign sda[i] = module_id == i && sda_oe ? 0 : 1'bz;
            assign scl[i] = module_id == i && scl_oe ? 0 : 1'bz;
        end
        for (i = 0; i < MODULE_IO_BITS; i = i + 1) begin
            assign module1_io[i] = module1_oe[i] ? module1_out[i] : 1'bz;
            assign module2_io[i] = module2_oe[i] ? module2_out[i] : 1'bz;
            assign module3_io[i] = module3_oe[i] ? module3_out[i] : 1'bz;
        end
        for (i = 0; i < MODULE4_IO_BITS; i = i + 1) begin
            assign module4_io[i] = module4_oe[i] ? module4_out[i] : 1'bz;
            assign module4_in[i] = module4_io[i];
        end
        for (i = MODULE4_IO_BITS; i < MODULE_IO_BITS; i = i + 1) begin
            assign module4_in[i] = 0;
        end
        if (NUM_MODULES > 4) begin : gen_51
            for (i = 0; i < MODULE5_IO_BITS; i = i + 1) begin
                assign module5_io[i] = module5_oe[i] ? module5_out[i] : 1'bz;
                assign module5_in[i] = module5_io[i];
            end
            for (i = MODULE5_IO_BITS; i < MODULE_IO_BITS; i = i + 1) begin
                assign module5_in[i] = 0;
            end
        end
    endgenerate

    assign sda_out = module_id > NUM_MODULES - 1 ? 1'b1 : sda[module_id];
    assign scl_out = module_id > NUM_MODULES - 1 ? 1'b1 : scl[module_id];

    assign sdo = module_id > NUM_MODULES - 1 ? {SPI_BITS{1'b1}} : module_do[module_id];

    device_handler #(.SPI_BITS(SPI_BITS), .IO_BITS(MODULE_IO_BITS))
        module1(.clk(clk), .nreset(nreset), .sdi(sdi), .sdo(module_do[0]), .sclk(sclk), .sncs(module_id == 0), .module_in(module1_io),
                .module_out(module1_out), .module_oe(module1_oe));

    device_handler #(.SPI_BITS(SPI_BITS), .IO_BITS(MODULE_IO_BITS))
        module2(.clk(clk), .nreset(nreset), .sdi(sdi), .sdo(module_do[1]), .sclk(sclk), .sncs(module_id == 1), .module_in(module2_io),
                .module_out(module2_out), .module_oe(module2_oe));

    device_handler #(.SPI_BITS(SPI_BITS), .IO_BITS(MODULE_IO_BITS))
        module3(.clk(clk), .nreset(nreset), .sdi(sdi), .sdo(module_do[2]), .sclk(sclk), .sncs(module_id == 2), .module_in(module3_io),
                .module_out(module3_out), .module_oe(module3_oe));

    device_handler #(.SPI_BITS(SPI_BITS), .IO_BITS(MODULE_IO_BITS))
        module4(.clk(clk), .nreset(nreset), .sdi(sdi), .sdo(module_do[3]), .sclk(sclk), .sncs(module_id == 3), .module_in(module4_in),
                .module_out(module4_out), .module_oe(module4_oe));

    generate
        if (NUM_MODULES > 4) begin : gen_52
            device_handler #(.SPI_BITS(SPI_BITS), .IO_BITS(MODULE_IO_BITS))
                module5(.clk(clk), .nreset(nreset), .sdi(sdi), .sdo(module_do[4]), .sclk(sclk), .sncs(module_id == 4), .module_in(module5_in),
                        .module_out(module5_out), .module_oe(module5_oe));
        end
    endgenerate
endmodule
