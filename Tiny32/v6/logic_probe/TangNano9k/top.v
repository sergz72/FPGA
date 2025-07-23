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
    output wire led,
    output wire pwm_out
);
    wire clk_probe, clk_main;
    reg clk_pwm;

    Gowin_rPLL pll(
        .clkout(clk_probe), //120MHz
        .clkoutd(clk_main), //30MHz
        .clkin(clk) //27MHz
    );

    main #(.UART_CLOCK_DIV(260), .UART_CLOCK_COUNTER_BITS(9), .MHZ_TIMER_BITS(5), .MHZ_TIMER_VALUE(30), .PROBE_TIME_PERIOD(12000000))
           m(.clk(clk_main), .clk_probe(clk_probe), .clk_pwm(clk_pwm), .nwfi(nwfi), .nerror(nerror),
             .nhlt(nhlt), .led(led), .tx(tx), .rx(rx), .sck(sck),
             .mosi(mosi), .ncs(ncs), .dc(dc), .button1(button1), .button2(button2), .dac1_code(dac1_code),
             .dac2_code(dac2_code), .comp_out_hi(comp_out_hi), .comp_out_lo(comp_out_lo), .pwm_out(pwm_out));

    always @(posedge clk_probe) begin
        clk_pwm = !clk_pwm;
    end

endmodule
