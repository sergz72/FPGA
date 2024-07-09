module ledPmodTest
#(parameter SEVENT_SEG_COUNTER_BITS = 20, COUNTER_BITS = 28)
(
    input clk,
    output wire [7:0] pmod_led1,
    output wire [7:0] pmod_led2,
    output wire seven_seg_sel,
    output wire [6:0] seven_seg
);
    reg [COUNTER_BITS - 1:0] counter = 0;
    wire segment7;

    sevenSegmentMultiplexedCommonAnode #(.COUNTER_BITS(SEVENT_SEG_COUNTER_BITS)) s(.clk(clk),
                                         .code(counter[COUNTER_BITS - 1:COUNTER_BITS - 8]), .points(2'b00),
                                         .segments({segment7, seven_seg}), .sel(seven_seg_sel));

    decoder #(.SEL_BITS(3)) d(.sel(counter[COUNTER_BITS - 5:COUNTER_BITS - 7]), .out(pmod_led1));
    decoder #(.SEL_BITS(3), .INVERT(1)) di(.sel(counter[COUNTER_BITS - 5:COUNTER_BITS - 7]), .out(pmod_led2));

    always @(posedge clk) begin
        counter = counter + 1;
    end
endmodule
