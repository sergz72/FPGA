module parallelViewer
#(parameter COUNTER_BITS = 24)
(
    input clk,
    input [7:0] data,
    input reset,
    input cs,
    input dc,
    input wr,
    input rd,
    output reg reset_o,
    output reg cs_o,
    output reg dc_o,
    output reg rd_o,
    output seven_seg_sel,
    output [6:0] seven_seg
);
    reg [7:0] o_data;

    sevenSegmentMultiplexedCommonAnode #(.COUNTER_BITS(COUNTER_BITS)) s(.clk(clk), .code(o_data), .segments(seven_seg), .sel(seven_seg_sel));

    always @(posedge wr) begin
        reset_o = reset;
        cs_o = cs;
        dc_o = dc;
        rd_o = rd;
        o_data = data;
    end
endmodule
