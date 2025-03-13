module top
(
    input wire clk,
    input wire clk_pwm,
    input wire nreset,
    input wire sck,
    input wire mosi,
    input wire ncs,
    output wire miso,
    output wire interrupt,
    output wire [3:0] dds_out,
    output wire [3:0] pwm_out,
    input wire [1:0] freq_in,
    output wire led_nreset,
    output wire led_interrupt,
    output wire led_ncs
);
    wire clk_dds;

    assign led_nreset = nreset;
    assign led_interrupt = interrupt;
    assign led_ncs = ncs;

    Gowin_rPLL your_instance_name(
        .clkout(clk_dds), //output clkout0
        .clkin(clk) //input clkin
    );

    main #(.MCLK_DDS(64'd297000000), .MCLK_PWM(32'd112000000))
        m(.clk(clk), .clk_dds(clk_dds), .clk_pwm(clk_pwm), .sck(sck), .mosi(mosi), .ncs(ncs), .miso(miso), .interrupt(interrupt), .nreset(nreset),
            .dds_out(dds_out), .pwm_out(pwm_out), .freq_in(freq_in));

endmodule
