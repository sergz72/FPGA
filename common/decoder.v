module decoder
#(parameter SEL_BITS = 1)
(
    input wire [SEL_BITS - 1:0] sel,
    output wire [2 ** SEL_BITS - 1:0] out
);
    genvar i;
    generate
        for (i = 0; i < 2 ** SEL_BITS; i = i + 1) begin
            assign out[i] = sel == i;
        end
    endgenerate
endmodule

module decoder_tb;
    wire [7:0] out;
    reg [2:0] sel;

    decoder #(.SEL_BITS(3)) d(.sel(sel), .out(out));

    integer i;
    initial begin
        $monitor("time=%t sel=%d out=%d", $time, sel, out);
        for (i = 0; i < 8; i = i + 1) begin
            sel = i;
            #1;
        end
        $finish;
    end
endmodule
