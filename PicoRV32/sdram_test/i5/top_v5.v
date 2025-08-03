`timescale 1 ns / 1 ps

module top_v5
#(parameter
UART_BAUD = 115200,
RESET_BIT = 19,
// 4k 32 bit words RAM
RAM_BITS = 12,
// 8k 32 bit words ROM
ROM_BITS = 13,
SDRAM_ADDRESS_WIDTH = 11,
SDRAM_COLUMN_ADDRESS_WIDTH = 8,
SDRAM_BANK_BITS = 2,
CLK_FREQUENCY = 25000000,
SDRAM_MODE_REGISTER_VALUE = 'h20,
SDRAM_AUTOREFRESH_LATENCY = 3,
SDRAM_CAS_LATENCY = 2,
SDRAM_BANK_ACTIVATE_LATENCY = 2,
SDRAM_PRECHARGE_LATENCY = 2
)
(
    input wire clk,
    output wire ntrap,
    output wire led1,
    output wire led2,
    output wire tx,
    input wire rx,
    output wire sdram_clk,
    output wire [10:0] sdram_address,
    output wire [1:0] sdram_ba,
    output wire sdram_ras,
    output wire sdram_cas,
    output wire sdram_nwe,
    inout wire [31:0] sdram_data
);
    wire [31:0] sdram_data_out;
    wire [3:0] sdram_dqm;
    wire sdram_ncs;

    assign sdram_data = sdram_nwe ? 32'hz : sdram_data_out;

    main #(.RESET_BIT(RESET_BIT), .CLK_FREQUENCY(CLK_FREQUENCY), .UART_BAUD(UART_BAUD), .RAM_BITS(RAM_BITS),
            .ROM_BITS(ROM_BITS), .SDRAM_ADDRESS_WIDTH(SDRAM_ADDRESS_WIDTH), .SDRAM_BANK_BITS(SDRAM_BANK_BITS),
            .SDRAM_COLUMN_ADDRESS_WIDTH(SDRAM_COLUMN_ADDRESS_WIDTH),
            .SDRAM_MODE_REGISTER_VALUE(SDRAM_MODE_REGISTER_VALUE), .SDRAM_AUTOREFRESH_LATENCY(SDRAM_AUTOREFRESH_LATENCY),
            .SDRAM_CAS_LATENCY(SDRAM_CAS_LATENCY), .SDRAM_BANK_ACTIVATE_LATENCY(SDRAM_BANK_ACTIVATE_LATENCY), .SDRAM_PRECHARGE_LATENCY(SDRAM_PRECHARGE_LATENCY))
         m(.clk(clk), .clk_sdram(clk), .ntrap(ntrap), .led1(led1), .led2(led2), .tx(tx), .rx(rx), .sdram_clk(sdram_clk),
            .sdram_address(sdram_address), .sdram_ba(sdram_ba),
            .sdram_ncs(sdram_ncs), .sdram_ras(sdram_ras), .sdram_cas(sdram_cas), .sdram_nwe(sdram_nwe), .sdram_data_in(sdram_data),
            .sdram_data_out(sdram_data_out), .sdram_dqm(sdram_dqm));
    
endmodule
