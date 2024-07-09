module sevenSegmentCommonAnode (
    input wire [3:0] code,
    output wire [6:0] out
);
    function [6:0] sevenSegDecodeCommonAnode(input [3:0] code);
        case (code)
            //                                  GFEDCBA
            'h0: sevenSegDecodeCommonAnode = 7'b1000000;
            'h1: sevenSegDecodeCommonAnode = 7'b1111001;
            'h2: sevenSegDecodeCommonAnode = 7'b0100100;
            'h3: sevenSegDecodeCommonAnode = 7'b0110000;
            'h4: sevenSegDecodeCommonAnode = 7'b0011001;
            'h5: sevenSegDecodeCommonAnode = 7'b0010010;
            'h6: sevenSegDecodeCommonAnode = 7'b0000010;
            'h7: sevenSegDecodeCommonAnode = 7'b1111000;
            'h8: sevenSegDecodeCommonAnode = 7'b0000000;
            'h9: sevenSegDecodeCommonAnode = 7'b0010000;
            'hA: sevenSegDecodeCommonAnode = 7'b0000100;
            'hB: sevenSegDecodeCommonAnode = 7'b0000011;
            'hC: sevenSegDecodeCommonAnode = 7'b1000110;
            'hD: sevenSegDecodeCommonAnode = 7'b1100000;
            'hE: sevenSegDecodeCommonAnode = 7'b0000110;
            'hF: sevenSegDecodeCommonAnode = 7'b0001110;
            default: sevenSegDecodeCommonAnode = 7'b1111111;
        endcase
    endfunction

    assign out = sevenSegDecodeCommonAnode(code);
endmodule

module sevenSegmentMultiplexedCommonAnode
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
    sevenSegmentCommonAnode s(.code(o_code), .out(segments[6:0]));

    assign segments[7] = points[sel];
    
    always @(posedge clk) begin
        if (counter == 0) begin
            sel = sel + 1;
        end
        counter = counter + 1;
    end
endmodule
