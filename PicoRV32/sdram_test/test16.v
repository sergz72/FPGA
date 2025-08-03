`timescale 1 ns / 1 ps

module test16;
    reg clk;
    wire ntrap;
    wire led1, led2;
    wire tx, rx;
    reg [7:0] data_in;
    wire interrupt;
    reg interrupt_clear, nreset;
    reg send;
    wire busy;

    wire sdram_clk;
    wire [12:0] sdram_address;
    wire [1:0] sdram_ba;
    wire sdram_ncs;
    wire sdram_ras;
    wire sdram_cas;
    wire sdram_nwe;
    wire sdram_data_noe;
    wire [15:0] sdram_data_out;
    wire [1:0] sdram_dqm;
    wire [15:0] sdram_data;

    assign sdram_data = sdram_data_noe ? 16'hz : sdram_data_out;

    main16 #(.RESET_BIT(3), .CLK_FREQUENCY(115200*10), .UART_BAUD(115200))
         m(.clk(clk), .clk_sdram(clk), .ntrap(ntrap), .led1(led1), .led2(led2), .tx(tx), .rx(rx), .sdram_clk(sdram_clk),
            .sdram_address(sdram_address), .sdram_ba(sdram_ba), .sdram_data_noe(sdram_data_noe),
            .sdram_ncs(sdram_ncs), .sdram_ras(sdram_ras), .sdram_cas(sdram_cas), .sdram_nwe(sdram_nwe), .sdram_data_in(sdram_data),
            .sdram_data_out(sdram_data_out), .sdram_dqm(sdram_dqm));

    uart1tx #(.CLOCK_DIV(10), .CLOCK_COUNTER_BITS(4)) utx(.clk(clk), .tx(rx), .data(data_in), .send(send), .busy(busy), .nreset(nreset));

    sdram_emulator #(.BURST_SIZE(2), .ADDRESS_WIDTH(13), .COLUMN_ADDRESS_WIDTH(9))
                    sdram_e(.clk(sdram_clk), .cke(1'b1), .address(sdram_address), .ba(sdram_ba),
                            .ncs(sdram_ncs), .ras(sdram_ras), .cas(sdram_cas), .nwe(sdram_nwe), .data(sdram_data),
                            .dqm(sdram_dqm));
                            
    always #1 clk = ~clk;

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, test);
        $monitor("time=%t led1=%d led2=%d rx=%d tx=%d", $time, led1, led2, rx, tx);
        clk = 0;
        data_in = 8'h5A;
        send = 0;
        interrupt_clear = 0;
        nreset = 0;
        #100
        nreset = 1;
        #5
        send = 1;
        #5
        send = 0;
        #200
        interrupt_clear = 1;
        #5
        interrupt_clear = 0;
        data_in = 8'hA5;
        send = 1;
        #5
        send = 0;
        #200
        interrupt_clear = 1;
        #1500000
        $finish;
    end
endmodule
