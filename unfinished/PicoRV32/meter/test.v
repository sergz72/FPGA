`include "main.vh"

`timescale 1 ns / 1 ps

module test;
    localparam I2C_PORTS = 1;

    reg clk;
    wire ntrap, nmem_invalid;
    wire [31:0] mem_la_addr;
    wire scl0_io;
    wire sda0_io;
    wire [I2C_PORTS - 1:0] scl_io;
    wire [I2C_PORTS - 1:0] sda_io;
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

    main #(.I2C_PORTS(I2C_PORTS))
         m(.clk(clk), .ntrap(ntrap), .nmem_invalid(nmem_invalid), .mem_la_addr(mem_la_addr), .scl0_io(scl0_io), .sda0_io(sda0_io),
           .con_button(con_button), .psh_button(psh_button), .tra(tra), .trb(trb), .bak_button(bak_button),
           .led(led), .scl_io(scl_io), .sda_io(sda_io), .tx(tx), .rx(rx));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(rx), .data(tx_data), .send(send), .busy(busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(tx), .data(data_out), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    pullup(scl0_io);
    pullup(sda0_io);
    pullup(scl_io[0]);
    pullup(sda_io[0]);

    always #1 clk = ~clk;

    initial begin
        $dumpfile("meter_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t mem_la_addr=0x%x ntrap=%d nmem_invalid=%d scl0_io=%d sda0_io=%d led=%d scl_io=0x%x sda_io=0x%x rx=%d tx=%d data_out=0x%x busy=%d interrupt=%d",
                 $time, mem_la_addr, ntrap, nmem_invalid, scl0_io, sda0_io, led, scl_io, sda_io, rx, tx, data_out, busy, interrupt);
        clk = 0;
        con_button = 1;
        psh_button = 1;
        tra = 1;
        trb = 1;
        bak_button = 1;
        send = 0;
        interrupt_clear = 0;
        nreset = 0;
        #5000
        nreset = 1;
        tx_data = 8'h5A;
        send = 1;
        #5
        send = 0;
        #10000
        interrupt_clear = 1;
        #5
        interrupt_clear = 0;
        #500000
        $finish;
    end
endmodule
