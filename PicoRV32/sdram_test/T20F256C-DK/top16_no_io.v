`timescale 1 ns / 1 ps

module top16_no_io
#(parameter
UART_BAUD = 115200,
RESET_BIT = 19,
// 4k 32 bit words RAM
RAM_BITS = 12,
// 8k 32 bit words ROM
ROM_BITS = 13,
SDRAM_ADDRESS_WIDTH = 13,
SDRAM_COLUMN_ADDRESS_WIDTH = 9,
SDRAM_BANK_BITS = 2,
CLK_FREQUENCY = 50000000,
SDRAM_MODE_REGISTER_VALUE = 'h21,
SDRAM_AUTOREFRESH_LATENCY = 3,
SDRAM_CAS_LATENCY = 2,
SDRAM_BANK_ACTIVATE_LATENCY = 2,
SDRAM_PRECHARGE_LATENCY = 2
)
(
    input wire clk,
    output wire ntrap,
    output wire [6:0] leds,
    output wire tx,
    input wire rx,
    output wire sdram_clk,
    output wire sdram_cke,
    output wire [12:0] sdram_address,
    output wire [1:0] sdram_ba,
    output wire sdram_ncs,
    output wire sdram_ras,
    output wire sdram_cas,
    output wire sdram_nwe,
    input wire [15:0] sdram_data_in,
    output wire [15:0] sdram_data_out,
    output wire sdram_data_oe[15:0],
    output wire [1:0] sdram_dqm
);
    wire sdram_data_noe;
    wire sdram_sel;
    wire [7:0] main_leds;

    assign leds = ~main_leds[6:0];
    
    assign sdram_data_oe[0] = !sdram_data_noe;
    assign sdram_data_oe[1] = !sdram_data_noe;
    assign sdram_data_oe[2] = !sdram_data_noe;
    assign sdram_data_oe[3] = !sdram_data_noe;
    assign sdram_data_oe[4] = !sdram_data_noe;
    assign sdram_data_oe[5] = !sdram_data_noe;
    assign sdram_data_oe[6] = !sdram_data_noe;
    assign sdram_data_oe[7] = !sdram_data_noe;
    assign sdram_data_oe[8] = !sdram_data_noe;
    assign sdram_data_oe[9] = !sdram_data_noe;
    assign sdram_data_oe[10] = !sdram_data_noe;
    assign sdram_data_oe[11] = !sdram_data_noe;
    assign sdram_data_oe[12] = !sdram_data_noe;
    assign sdram_data_oe[13] = !sdram_data_noe;
    assign sdram_data_oe[14] = !sdram_data_noe;
    assign sdram_data_oe[15] = !sdram_data_noe;

    main16 #(.RESET_BIT(RESET_BIT), .CLK_FREQUENCY(CLK_FREQUENCY), .UART_BAUD(UART_BAUD), .RAM_BITS(RAM_BITS),
            .ROM_BITS(ROM_BITS), .SDRAM_ADDRESS_WIDTH(SDRAM_ADDRESS_WIDTH), .SDRAM_BANK_BITS(SDRAM_BANK_BITS),
            .SDRAM_COLUMN_ADDRESS_WIDTH(SDRAM_COLUMN_ADDRESS_WIDTH),
            .SDRAM_MODE_REGISTER_VALUE(SDRAM_MODE_REGISTER_VALUE), .SDRAM_AUTOREFRESH_LATENCY(SDRAM_AUTOREFRESH_LATENCY),
            .SDRAM_CAS_LATENCY(SDRAM_CAS_LATENCY), .SDRAM_BANK_ACTIVATE_LATENCY(SDRAM_BANK_ACTIVATE_LATENCY), .SDRAM_PRECHARGE_LATENCY(SDRAM_PRECHARGE_LATENCY))
         m(.clk(clk), .clk_sdram(clk), .ntrap(ntrap), .leds(main_leds), .tx(tx), .rx(rx), .sdram_clk(sdram_clk),
            .sdram_address(sdram_address), .sdram_ba(sdram_ba), .sdram_data_noe(sdram_data_noe),
            .sdram_ncs(sdram_ncs), .sdram_ras(sdram_ras), .sdram_cas(sdram_cas), .sdram_nwe(sdram_nwe), .sdram_data_in(sdram_data_in),
            .sdram_data_out(sdram_data_out), .sdram_dqm(sdram_dqm), .sdram_cke(sdram_cke), .sdram_sel(sdram_sel));
    
endmodule
