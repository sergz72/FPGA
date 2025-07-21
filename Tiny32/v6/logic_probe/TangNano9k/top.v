module top
(
    input wire clk,
    output wire nhlt,
    output wire nerror,
    output wire nwfi,
    input wire button1,
    input wire button2,
    output wire [4:0] dac1_code,
    output wire [4:0] dac2_code,
    input wire comp_out_hi,
    input wire comp_out_lo,
    output wire sck,
    output wire mosi,
    output wire ncs,
    output wire dc,
    output wire tx,
    input wire rx,
    output wire led
);
    wire clk_probe;

    Gowin_rPLL pll(
        .clkout(clk_probe), //output clkout
        .clkoutd(clk_main),
        .clkin(clk) //input clkin
    );

    main m(.clk(clk_main), .clk_probe(clk_probe), .nwfi(nwfi), .nerror(nerror), .nhlt(nhlt), .led(led), .tx(tx), .rx(rx), .sck(sck),
            .mosi(mosi), .ncs(ncs), .dc(dc), .button1(button1), .button2(button2), .dac1_code(dac1_code),
            .dac2_code(dac2_code), .comp_out_hi(comp_out_hi), .comp_out_lo(comp_out_lo));

endmodule
