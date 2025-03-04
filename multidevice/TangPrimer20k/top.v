module top
(
    input wire clk,
    input wire nreset,
    input wire sck,
    input wire mosi,
    input wire ncs,
    output wire miso,
    output wire interrupt,
    output wire [3:0] dds_out,
    output wire [3:0] pwm_out,
    input wire [1:0] freq_in
);
    wire clk_dds, clk_pwm;

    Gowin_rPLL your_instance_name(
        .clkout(clk_dds), //output clkout0
        .clkoutd(clk_pwm), //output clkout1
        .clkin(clk) //input clkin
    );

    main #(.MCLK_DDS(64'd297000000), .MCLK_PWM(32'd74250000))
        m(.clk(clk), .clk_dds(clk_dds), .clk_pwm(clk_pwm), .sck(sck), .mosi(mosi), .ncs(ncs), .miso(miso), .interrupt(interrupt), .nreset(nreset),
            .dds_out(dds_out), .pwm_out(pwm_out), .freq_in(freq_in));

endmodule
