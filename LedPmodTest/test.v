module ledPmodTest_tb;
    reg clk;
    wire [7:0] pmod_led1, pmod_led2;
    wire [6:0] seven_seg;
    wire seven_seg_sel;

    ledPmodTest #(.SEVENT_SEG_COUNTER_BITS(2), .COUNTER_BITS(12))
        t(.clk(clk), .pmod_led1(pmod_led1), .pmod_led2(pmod_led2), .seven_seg_sel(seven_seg_sel), .seven_seg(seven_seg));

    always #1 clk = ~clk;

    initial begin
        $monitor("time=%t pmod_led1=%b pmod_led2=%b seven_seg_sel=%d seven_seg=%b", $time, pmod_led1, pmod_led2, seven_seg_sel, seven_seg);
        clk = 0;
        #10000
        $finish;
    end
endmodule
