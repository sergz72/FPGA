module dds_tb;
    reg clk;
    wire out;
    wire [1:0] out2;

    dds #(.WIDTH(16)) d(.clk(clk), .code(16'd10000), .out(out));
    dds #(.WIDTH(16), .OUT_WIDTH(2)) d2(.clk(clk), .code(16'd10000), .out(out2));

    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t out=%d out2=%d", $time, out, out2);
        clk = 0;
        #1000
        $finish;
    end
endmodule
