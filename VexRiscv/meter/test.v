`timescale 1 ns / 1 ps

module test;
    reg clk;
    wire error;
    wire [31:0] rom_addr;
    wire scl_io;
    wire sda_io;
    reg con_button;
    reg psh_button;
    reg tra, trb;
    reg bak_button;
    wire led, wfi;

    main #(.TIMER_BITS(10), .RESET_DELAY_BIT(5), .CPU_CLOCK_BIT(1))
         m(.clk(clk), .error(error), .rom_addr(rom_addr), .scl_io(scl_io), .sda_io(sda_io),
           .con_button(con_button), .psh_button(psh_button), .tra(tra), .trb(trb), .bak_button(bak_button),
           .led(led), .wfi(wfi));

    pullup(scl_io);
    pullup(sda_io);

    always #1 clk = ~clk;

    initial begin
        $dumpfile("meter_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t wfi=%d rom_addr=0x%x error=%d scl_io=%d sda_io=%d led=%d", $time, wfi, rom_addr, error, scl_io, sda_io, led);
        clk = 0;
        con_button = 1;
        psh_button = 1;
        tra = 1;
        trb = 1;
        bak_button = 1;
        #4000000
        $finish;
    end
endmodule
