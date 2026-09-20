module sevenSegment_tb;
    reg clk;
    reg [7:0] code;
    reg [1:0] points;
    wire [7:0] segments_ca;
    wire [7:0] segments_cc;
    wire sel_ca;
    wire sel_cc;

    sevenSegmentMultiplexedCommonAnode #(.SEL_BITS(1), .COUNTER_BITS(2))
        ca(.clk(clk), .code(code), .points(points), .segments(segments_ca), .sel(sel_ca));
    sevenSegmentMultiplexedCommonCathode #(.SEL_BITS(1), .COUNTER_BITS(2))
        cc(.clk(clk), .code(code), .points(points), .segments(segments_cc), .sel(sel_cc));

    always #5 clk = ~clk;

    integer i;
    initial begin
        $monitor("time=%t code=0x%h points=%b sel_ca=%d segments_ca=%b sel_cc=%d segments_cc=%b",
                 $time, code, points, sel_ca, segments_ca, sel_cc, segments_cc);
        clk = 0;
        code = 8'h5A;
        points = 'b10;
        #130
        code = 8'hA5;
        points = 'b01;
        #130
        $finish;
    end
endmodule
