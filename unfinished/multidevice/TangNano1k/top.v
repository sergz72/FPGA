module top
(
    input wire clk,
    input wire nreset,
    input wire sck,
    input wire mosi,
    input wire ncs,
    output wire miso,
    output wire interrupt,
    output wire [3:0] out
);
    wire clk_sys;

    Gowin_rPLL chip_pll(
        .clkout(clk_sys), //135 mhz
        .clkin(clk)
    );  

    main #(.MCLK(64'd135000000)) m(.clk(clk), .clk_dds(clk_sys), .sck(sck), .mosi(mosi), .ncs(ncs), .miso(miso), .interrupt(interrupt), .out(out), .nreset(nreset));

endmodule
