`timescale 1 ns / 1 ps

module test;
    // 8k 32 bit words ROM
    localparam ROM_BITS = 13;
    
    reg clk, clk_rom_controller;
    wire ntrap;
    wire led;
    wire rom_sck;
    wire [3:0] rom_sio;
    wire rom_ncs;

    main #(.RESET_BIT(3))
         m(.clk(clk), .clk_rom_controller(clk_rom_controller), .ntrap(ntrap), .led(led), .rom_sck(rom_sck), .rom_sio(rom_sio), .rom_ncs(rom_ncs));

    qspi_rom_emulator #(.MEMORY_BITS(ROM_BITS+3)) rom(.sck(rom_sck), .sio(rom_sio), .ncs(rom_ncs));

    always #2 clk = ~clk;
    always #1 clk_rom_controller = ~clk_rom_controller;

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t led=%d", $time, led);
        clk = 0;
        #1500000
        $finish;
    end
endmodule
