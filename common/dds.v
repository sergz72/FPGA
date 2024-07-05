module dds_bin
#(parameter WIDTH = 32, OUT_WIDTH = 1)
(
    input wire clk,
    input wire [WIDTH - 1:0] code,
    output [OUT_WIDTH - 1:0] out
);
    reg [WIDTH - 1:0] counter = 0;

    assign out = counter[WIDTH - 1: WIDTH - OUT_WIDTH];
    
    always @(posedge clk) begin
        counter = counter + code;
    end
endmodule

module dds_tb;
    reg clk;
    wire out;
    wire [1:0] out2;

    dds_bin #(.WIDTH(16)) d(.clk(clk), .code(16'd10000), .out(out));
    dds_bin #(.WIDTH(16), .OUT_WIDTH(2)) d2(.clk(clk), .code(16'd10000), .out(out2));

    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t out=%d out2=%d", $time, out, out2);
        clk = 0;
        #1000
        $finish;
    end
endmodule
