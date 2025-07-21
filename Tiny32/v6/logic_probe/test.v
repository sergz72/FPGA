module test;
    reg clk, nreset;
    wire hlt, error, wfi, led;
    wire tx, rx, busy;
    reg [7:0] data_in;
    reg send;
    wire sck, mosi, ncs, dc;
    reg button1, button2;
    wire [4:0] dac1_code, dac2_code;
    reg comp_out_hi, comp_out_lo;

    main #(.RESET_BIT(3), .UART_CLOCK_DIV(8), .UART_CLOCK_COUNTER_BITS(4))
         m(.clk(clk), .clk_probe(clk), .wfi(wfi), .error(error), .hlt(hlt), .led(led), .tx(tx), .rx(rx), .sck(sck),
            .mosi(mosi), .ncs(ncs), .dc(dc), .button1(button1), .button2(button2), .dac1_code(dac1_code),
            .dac2_code(dac2_code), .comp_out_hi(comp_out_hi), .comp_out_lo(comp_out_lo));

    uart1tx #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4)) utx(.clk(clk), .tx(rx), .data(data_in), .send(send), .busy(busy), .nreset(nreset));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t led=%d rx=%d tx=%d ncs=%d sck=%d mosi=%d dc=%d", $time, led, rx, tx, ncs, sck, mosi, dc);
        clk = 0;
        data_in = 8'h5A;
        send = 0;
        nreset = 0;
        button1 = 1;
        button2 = 1;
        comp_out_hi = 0;
        comp_out_lo = 0;
        #100
        nreset = 1;
        #5
        send = 1;
        #5
        send = 0;
        #200
        data_in = 8'hA5;
        send = 1;
        #5
        send = 0;
        #10000000
        $finish;
    end
endmodule
