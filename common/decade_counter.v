module decade_counter(
    input wire clk,
    input wire ce,
    input wire reset,
    output reg [3:0] value,
    output wire oce
);
    assign oce = (value == 9) && ce;

    always @(posedge clk or negedge reset) begin
        if (reset == 0)
            value = 0;
        else begin
            if (ce == 1) begin
                if (value == 9)
                    value = 0;
                else
                    value = value + 1;
            end
        end
    end
endmodule

module decade_counters
#(parameter COUNT = 8)
(
    input wire clk,
    input wire reset,
    output wire [COUNT * 4 - 1:0] value
);
    wire [COUNT - 1:0] oce;

    genvar i;
    generate
        decade_counter dc_first(.clk(clk), .reset(reset), .ce(1'b1), .value(value[3:0]), .oce(oce[0]));
        for (i = 1; i < COUNT - 1; i = i + 1) begin
            decade_counter dc(.clk(clk), .reset(reset), .ce(oce[i - 1]), .value(value[3 + 4 * i:4 * i]), .oce(oce[i]));
        end
        decade_counter dc_last(.clk(clk), .reset(reset), .ce(oce[COUNT - 2]), .value(value[COUNT * 4 - 1:(COUNT - 1) * 4]));
    endgenerate
endmodule

module decade_counters_tb;
    reg clk, reset;
    wire [11:0] value;

    decade_counters #(.COUNT(3)) d(.clk(clk), .reset(reset), .value(value));

    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t value=0x%0x", $time, value);
        clk = 0;
        reset = 0;
        #20
        reset = 1;
        #10000
        $finish;
    end
endmodule
