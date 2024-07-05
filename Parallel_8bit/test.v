module parallelViewer_tb;
    reg clk, reset, cs, dc, wr, rd;
    reg [7:0] data;
    wire reset_o, cs_o, dc_o, rd_o, seven_seg_sel;
    wire [6:0] seven_seg;

    parallelViewer #(.COUNTER_BITS(1)) v(
        .clk(clk), .data(data), .reset(reset), .cs(cs), .dc(dc), .wr(wr), .rd(rd),
        .reset_o(reset_o), .cs_o(cs_o), .dc_o(dc_o), .rd_o(rd_o), .seven_seg_sel(seven_seg_sel),
        .seven_seg(seven_seg)
    );

    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t reset_o=%d cs_o=%d dc_o=%d rd_o=%d seven_seg_sel=%d seven_seg=0x%0h", $time,
                    reset_o, cs_o, dc_o, rd_o, seven_seg_sel, seven_seg);
        clk = 0;
        data = 0;
        reset = 0;
        cs = 1;
        dc = 1;
        wr = 1;
        rd = 1;
        #20
        wr = 0;
        #20
        wr = 1;
        #20
        reset = 1;
        cs = 0;
        wr = 0;
        #20
        wr = 1;
        #20
        cs = 1;
        dc = 0;
        wr = 0;
        #20
        wr = 1;
        #20
        dc = 1;
        rd = 0;
        wr = 0;
        #20
        wr = 1;
        #20
        rd = 1;
        data = 'h5A;
        wr = 0;
        #20
        wr = 1;
        #100
        data = 'hA5;
        wr = 0;
        #20
        wr = 1;
        #100
        $finish;
    end
endmodule
