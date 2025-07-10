module top
(
    input wire clk,
    output wire nhlt,
    output wire nwfi,
    inout wire scl,
    inout wire sda,
    input wire button1,
    input wire button2,
    output wire [4:0] dac1_code,
    output wire [4:0] dac2_code,
    input wire comp_out_hi,
    input wire comp_out_lo
);
    wire clk_probe;

    Gowin_rPLL pll(
        .clkout(clk_probe), //output clkout
        .clkin(clk) //input clkin
    );

    main m(.clk(clk), .nhlt(nhlt), .nwfi(nwfi), .scl(scl), .sda(sda), .button1(button1), .button2(button2),
            .dac1_code(dac1_code), .dac2_code(dac2_code), .comp_out_hi(comp_out_hi), .comp_out_lo(comp_out_lo), .clk_probe(clk_probe));

endmodule
