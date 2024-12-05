`include "main.vh"

module test;
    localparam I2C_PORTS_BITS = 1;

    reg clk;
    wire nhlt, nerror, nwfi;
    wire [31:0] address;
    wire [(1 << I2C_PORTS_BITS) - 1:0] scl_io;
    wire [(1 << I2C_PORTS_BITS) - 1:0] sda_io;
    reg con_button;
    reg psh_button;
    reg tra, trb;
    reg bak_button;
    wire led;
    wire tx, rx, busy;
    reg send;
    reg [7:0] tx_data;
    wire [7:0] data_out;
    wire interrupt;
    reg interrupt_clear, nreset;

    main #(.I2C_PORTS_BITS(I2C_PORTS_BITS))
         m(.clk(clk), .nhlt(nhlt), .nerror(nerror), .nwfi(nwfi), .address(address),
           .scl_io(scl_io), .sda_io(sda_io), .con_button(con_button), .psh_button(psh_button), .tra(tra), .trb(trb),
           .bak_button(bak_button), .led(led), .tx(tx), .rx(rx));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(rx), .data(tx_data), .send(send), .busy(busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(tx), .data(data_out), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    pullup(scl_io[0]);
    pullup(sda_io[0]);
    pullup(scl_io[1]);
    pullup(sda_io[1]);

    always #1 clk = ~clk;

    initial begin
        $dumpfile("meter_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t address=0x%x nhlt=%d nerror=%d nwfi=%d scl_io[0]=%d sda_io[0]=%d scl_io[1]=%d sda_io[1]=%d led=%d rx=%d tx=%d data_out=0x%x busy=%d interrupt=%d",
                 $time, address, nhlt, nerror, nwfi, scl_io[0], sda_io[0], scl_io[1], sda_io[1], led, rx, tx, data_out, busy, interrupt);
        clk = 0;
        con_button = 1;
        psh_button = 1;
        tra = 1;
        trb = 1;
        bak_button = 1;
        send = 0;
        interrupt_clear = 0;
        nreset = 0;
        #3000
        nreset = 1;
        tx_data = 8'h5A;
        #5
        send = 1;
        #5
        send = 0;
        #1000
        tx_data = 8'h33;
        #5
        send = 1;
        #5
        send = 0;
        #20000
        interrupt_clear = 1;
        #5
        interrupt_clear = 0;
        #500000
        $finish;
    end
endmodule
