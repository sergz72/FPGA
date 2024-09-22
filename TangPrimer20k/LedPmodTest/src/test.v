module test
(
  input wire clk,
  output reg [7:0] leds = 8'b11111110,
  output reg [7:0] leds2 = 8'b00111111,
  output wire [6:0] seven_seg,
  output wire seven_seg_sel
);
    reg [31:0] counter = 0;
    wire segment7, seven_seg_sel_s;

    assign seven_seg_sel = ~seven_seg_sel_s;

    sevenSegmentMultiplexedCommonAnode #(.COUNTER_BITS(18))
        s(.clk(clk), .code(counter[31:24]), .points(2'b00), .segments({segment7, seven_seg}), .sel(seven_seg_sel_s));

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // shift register
    always @(posedge counter[23]) begin
        // shift left
        leds <= {leds[6:0], leds[7]};
        // shift right
        leds2 <= {leds2[0], leds2[7:1]};
    end

endmodule