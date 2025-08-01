`timescale 1 ns / 1 ps

module top
#(parameter
UART_CLOCK_DIV = 234,
UART_CLOCK_COUNTER_BITS = 8,
RESET_BIT = 19,
// 4k 32 bit words RAM
RAM_BITS = 12,
// 8k 32 bit words ROM
ROM_BITS = 13,
SDRAM_ADDRESS_WIDTH = 11,
SDRAM_COLUMN_ADDRESS_WIDTH = 8,
SDRAM_BANK_BITS = 2
)
(
    input wire clk,
    input wire clk_sdram,
    output wire ntrap,
    output reg led1,
    output reg led2,
    output wire tx,
    input wire rx,
    output wire sdram_clk,
    output wire [10:0] sdram_address,
    output wire [1:0] sdram_ba,
    output wire sdram_ncs,
    output wire sdram_ras,
    output wire sdram_cas,
    output wire sdram_nwe,
    inout wire [31:0] sdram_data,
    output wire [3:0] sdram_dqm
);
    wire [31:0] sdram_data_out;

    assign sdram_data = sdram_nwe ? 32'hz : sdram_data_out;

    main #(.RESET_BIT(RESET_BIT), .UART_CLOCK_DIV(UART_CLOCK_DIV), .UART_CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS), .RAM_BITS(RAM_BITS),
            .ROM_BITS(ROM_BITS), .SDRAM_ADDRESS_WIDTH(SDRAM_ADDRESS_WIDTH), .SDRAM_BANK_BITS(SDRAM_BANK_BITS), .SDRAM_COLUMN_ADDRESS_WIDTH(SDRAM_COLUMN_ADDRESS_WIDTH))
         m(.clk(clk), .clk_sdram(clk_sdram), .ntrap(ntrap), .led1(led1), .led2(led2), .tx(tx), .rx(rx), .sdram_clk(sdram_clk),
            .sdram_address(sdram_address), .sdram_ba(sdram_ba),
            .sdram_ncs(sdram_ncs), .sdram_ras(sdram_ras), .sdram_cas(sdram_cas), .sdram_nwe(sdram_nwe), .sdram_data_in(sdram_data),
            .sdram_data_out(sdram_data_out), .sdram_dqm(sdram_dqm));
    
endmodule
