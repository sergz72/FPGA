module logicProbe_tb;
    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t reset_o=%d cs_o=%d dc_o=%d rd_o=%d seven_seg_sel=%d seven_seg=0x%0h", $time,
                    reset_o, cs_o, dc_o, rd_o, seven_seg_sel, seven_seg);
        $finish;
    end
endmodule
