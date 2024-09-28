`timescale 1 ns / 1 ps

module test;
    reg clk;
    wire trap;
    wire [31:0] mem_la_addr;
    wire scl_io;
    wire sda_io;
    reg con_button;
    reg psh_button;
    reg tra, trb;
    reg bak_button;
    wire led;

    main #(.TIMER_BITS(16), .RESET_DELAY_BIT(4), .CPU_CLOCK_BIT(1))
         m(.clk(clk), .trap(trap), .mem_la_addr(mem_la_addr), .scl_io(scl_io), .sda_io(sda_io),
           .con_button(con_button), .psh_button(psh_button), .tra(tra), .trb(trb), .bak_button(bak_button),
           .led(led));

    pullup(scl_io);
    pullup(sda_io);

    always #1 clk = ~clk;

    initial begin
        $dumpfile("meter_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t mem_la_addr=0x%x trap=%d scl_io=%d sda_io=%d led=%d", $time, mem_la_addr, trap, scl_io, sda_io, led);
        clk = 0;
        con_button = 1;
        psh_button = 1;
        tra = 1;
        trb = 1;
        bak_button = 1;
        #30000
        $finish;
    end
endmodule
