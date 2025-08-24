`timescale 1 ns / 1 ps

module test;
    localparam HYPERRAM_LATENCY = 6;
    localparam HYPERRAM_LATENCY2X = 1;
    localparam HYPERRAM_MEMORY_BITS = 21; // 2Mx32

    reg clk;
    wire ntrap;
    wire [7:0] leds;
    wire tx, rx;

    wire hyperram_clk, hyperram_nreset, hyperram_rwds, hyperram_rwds_out, hyperram_data_noe, hyperram_ncs, hyperram_rwds_noe;
    wire [7:0] hyperram_data_out, hyperram_data;

    assign hyperram_data = hyperram_data_noe ? 8'hz : hyperram_data_out;
    assign hyperram_rwds = hyperram_rwds_noe ? 1'bz : hyperram_rwds_out;

    main #(.RESET_BIT(3), .CLK_FREQUENCY(115200*10), .UART_BAUD(115200), .HYPERRAM_LATENCY(HYPERRAM_LATENCY), .HYPERRAM_MEMORY_BITS(HYPERRAM_MEMORY_BITS))
         m(.clk(clk), .clk_hyperram(clk), .ntrap(ntrap), .leds(leds), .tx(tx), .rx(rx), .hyperram_clk(hyperram_clk), .hyperram_rwds_noe(hyperram_rwds_noe),
            .hyperram_nreset(hyperram_nreset), .hyperram_ncs(hyperram_ncs), .hyperram_rwds_in(hyperram_rwds), .hyperram_rwds_out(hyperram_rwds_out),
            .hyperram_data_in(hyperram_data), .hyperram_data_out(hyperram_data_out), .hyperram_data_noe(hyperram_data_noe));

    hyperram_emulator #(.LATENCY(HYPERRAM_LATENCY), .LATENCY2X(HYPERRAM_LATENCY2X), .MEMORY_BITS(HYPERRAM_MEMORY_BITS))
                     emulator(.nreset(hyperram_nreset), .clk(hyperram_clk), .ncs(hyperram_ncs), .rwds(hyperram_rwds), .data(hyperram_data));

    assign rx = 1'b1;

    always #2 clk = ~clk;

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t leds=0x%02x", $time, leds);
        clk = 0;
        #1500000
        $finish;
    end
endmodule
