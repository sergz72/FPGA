module sevenSegmentCommonCathode (
    input wire [3:0] code,
    output wire [6:0] out
);
    function [6:0] sevenSegDecodeCommonCathode(input [3:0] code);
        case (code)
            //                                  GFEDCBA
            'h0: sevenSegDecodeCommonCathode = 7'b0111111;
            'h1: sevenSegDecodeCommonCathode = 7'b0000110;
            'h2: sevenSegDecodeCommonCathode = 7'b1011011;
            'h3: sevenSegDecodeCommonCathode = 7'b1001111;
            'h4: sevenSegDecodeCommonCathode = 7'b1100110;
            'h5: sevenSegDecodeCommonCathode = 7'b1101101;
            'h6: sevenSegDecodeCommonCathode = 7'b1111101;
            'h7: sevenSegDecodeCommonCathode = 7'b0000111;
            'h8: sevenSegDecodeCommonCathode = 7'b1111111;
            'h9: sevenSegDecodeCommonCathode = 7'b0010000;
            'hA: sevenSegDecodeCommonCathode = 7'b1110111;
            'hB: sevenSegDecodeCommonCathode = 7'b1111100;
            'hC: sevenSegDecodeCommonCathode = 7'b0111001;
            'hD: sevenSegDecodeCommonCathode = 7'b1011110;
            'hE: sevenSegDecodeCommonCathode = 7'b1111001;
            'hF: sevenSegDecodeCommonCathode = 7'b1110001;
            default: sevenSegDecodeCommonCathode = 7'b0000000;
        endcase
    endfunction

    assign out = sevenSegDecodeCommonCathode(code);
endmodule

module sevenSegmentMultiplexedCommonCathode
#(parameter SEL_BITS = 1, COUNTER_BITS = 24)
(
    input wire clk,
    input wire [(4 << SEL_BITS) - 1:0] code,
    input wire [(1 << SEL_BITS) - 1:0] points,
    output wire [7:0] segments,
    output reg [SEL_BITS - 1:0] sel = 0
);
    reg [COUNTER_BITS - 1:0] counter = 0;
    wire [3:0] o_code;

    mux #(.SEL_BITS(SEL_BITS)) m(.code(code), .sel(sel), .out(o_code));
    sevenSegmentCommonCathode s(.code(o_code), .out(segments[6:0]));

    assign segments[7] = ~points[sel];

    always @(posedge clk) begin
        if (counter == 0) begin
            sel = sel + 1;
        end
        counter = counter + 1;
    end
endmodule
