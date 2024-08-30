module main
// 9600 baud
#(parameter CLOCK_DIV = 2812, CLOCK_COUNTER_BITS = 12)
(
    input wire clk,
    output wire tx,
    input wire rx
);
    wire [7:0] data;
    wire send;
    wire busy;

    uart1tx #(.CLOCK_DIV(CLOCK_DIV), .CLOCK_COUNTER_BITS(CLOCK_COUNTER_BITS)) utx(.clk(clk), .tx(tx), .data(data), .send(send), .busy(busy));
    uart1rx #(.CLOCK_DIV(CLOCK_DIV), .CLOCK_COUNTER_BITS(CLOCK_COUNTER_BITS)) urx(.clk(clk), .rx(rx), .data(data), .interrupt(send), .interrupt_clear(busy));

endmodule

module uart_echo_tb;
    reg clk;
    wire tx;
    reg rx = 1;

    always #1 clk = ~clk;

    main #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4)) m(.clk(clk), .tx(tx), .rx(rx));

    initial begin
        $dumpfile("uart_echo_tb.vcd");
        $dumpvars(0, uart_echo_tb);
        $monitor("time=%t clk=%d tx=%d rx=%d", $time, clk, tx, rx);
        clk = 0;
        #10
        rx = 0;
        #16
        rx = 1;
        #16
        rx = 0;
        #16
        rx = 1;
        #16
        rx = 0;
        #16
        rx = 0;
        #16
        rx = 1;
        #16
        rx = 0;
        #16
        rx = 1;
        #500

        rx = 0;
        #16
        rx = 1;
        #16
        rx = 0;
        #16
        rx = 1;
        #16
        rx = 0;
        #16
        rx = 0;
        #16
        rx = 1;
        #16
        rx = 0;
        #16
        rx = 1;

        #500
        $finish;
    end
endmodule
