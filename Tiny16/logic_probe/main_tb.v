module main_tb;
    wire nhlt, nwfi, led;
    reg clk;
    wire scl;
    wire sda;
    reg button1, button2;
    wire [4:0] dac1_code, dac2_code;

    main #(.RESET_BIT(2)) m(.clk(clk), .nhlt(nhlt), .nwfi(nwfi), .scl(scl), .sda(sda), .button1(button1), .button2(button2),
            .dac1_code(dac1_code), .dac2_code(dac2_code));

    pullup(scl);
    pullup(sda);

    always #1 clk <= ~clk;
    
    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t clk=%d nhlt=%d nwfi=%d scl=%d sda=%d button1=%d button2=%d dac1_code=%d dac2_code=%d",
                    $time, clk, nhlt, nwfi, scl, sda, button1, button2, dac1_code, dac2_code);
        clk = 0;
        button1 = 1;
        button2 = 1;
        #100000
        $finish;
    end
endmodule
