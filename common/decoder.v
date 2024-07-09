module decoder
#(parameter SEL_BITS = 1, INVERT = 0)
(
    input wire [SEL_BITS - 1:0] sel,
    output wire [2 ** SEL_BITS - 1:0] out
);
    genvar i;
    generate
        for (i = 0; i < 2 ** SEL_BITS; i = i + 1) begin
            if (INVERT == 0)
                assign out[i] = sel == i;
            else
                assign out[i] = sel != i;
        end
    endgenerate
endmodule

module decoder_tb;
    wire [7:0] out, outn;
    reg [2:0] sel;

    decoder #(.SEL_BITS(3)) d(.sel(sel), .out(out));
    decoder #(.SEL_BITS(3), .INVERT(1)) dn(.sel(sel), .out(outn));

    integer i;
    initial begin
        $monitor("time=%t sel=%d out=%b outn=%b", $time, sel, out, outn);
        for (i = 0; i < 8; i = i + 1) begin
            sel = i;
            #1;
        end
        $finish;
    end
endmodule
