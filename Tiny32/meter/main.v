`include "main.vh"

module main
#(parameter
// 115200 at 27MHz
UART_CLOCK_DIV = 234,
// 115200 at 10MHz
//UART_CLOCK_DIV = 87,
UART_CLOCK_COUNTER_BITS = 8,
I2C_PORTS = 1,
// 6.75 interrupts/sec
TIMER_BITS = 22,
// about 20 ms delay
RESET_DELAY_BIT = 19,
// div = 64
CPU_CLOCK_BIT = 5,
// 2k 32 bit words RAM
RAM_BITS = 11,
// 8k 32 bit words ROM
ROM_BITS = 13)
(
    input wire clk,
    output wire nhlt,
    output wire nerror,
    output wire nwfi,
`ifdef MEMORY_DEBUG
    output wire [31:0] address,
`endif
`ifndef NO_INOUT_PINS
    inout wire scl0_io,
    inout wire sda0_io,
    inout wire [I2C_PORTS - 1:0] scl_io,
    inout wire [I2C_PORTS - 1:0] sda_io,
`else
    input wire scl0_in,
    input wire sda0_in,
    output reg scl0 = 1,
    output reg sda0 = 1,
    input wire [I2C_PORTS - 1:0] scl_in,
    input wire [I2C_PORTS - 1:0] sda_in,
    output reg [I2C_PORTS - 1:0] scl = {I2C_PORTS{1'b1}},
    output reg [I2C_PORTS - 1:0] sda = {I2C_PORTS{1'b1}},
`endif
    input wire con_button,
    input wire psh_button,
    input wire tra, // encoder
    input wire trb, // encoder
    input wire bak_button,
    output reg led = 1,
    output wire tx,
    input wire rx
);
    localparam MEMORY_SELECTOR_START_BIT = 27;

    reg nreset = 0;

    reg [TIMER_BITS - 1:0] timer = 0;
    reg timer_interrupt = 0;

`ifndef NO_INOUT_PINS
    reg scl0 = 1;
    reg sda0 = 1;
    reg [I2C_PORTS - 1:0] scl = {I2C_PORTS{1'b1}};
    reg [I2C_PORTS - 1:0] sda = {I2C_PORTS{1'b1}};
`endif

`ifndef MEMORY_DEBUG
    wire [31:0] address;
`endif

    wire hlt, error, wfi;
    wire [7:0] irq, interrupt_ack;
    wire [31:0] data_in, mem_rdata;
    reg [31:0] rom_rdata, ram_rdata, ports_rdata;
    wire [3:0] nwr;
    wire nrd;
    wire cpu_clk;
    wire rom_selected, ram_selected, ports_selected, uart_data_selected;
    //wire uart_control_selected;
    wire [2:0] stage;
    wire mem_clk;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_nwr, uart_nrd;
    wire [7:0] uart_data_out;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign nhlt = !hlt;
    assign nerror = !error;
    assign nwfi = !wfi;

    assign irq = {7'h0, timer_interrupt};

    assign memory_selector = address[31:MEMORY_SELECTOR_START_BIT];

    assign cpu_clk = timer[CPU_CLOCK_BIT];
    assign rom_selected = memory_selector === 1;
    assign ram_selected = memory_selector === 2;
    assign uart_data_selected = memory_selector === 5'h1D;
    //assign uart_control_selected = memory_selector === 5'h1E;
    assign ports_selected = memory_selector === 5'h1F;
    assign mem_rdata = mem_rdata_f(memory_selector);

    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];

    assign uart_nwr = !uart_data_selected | (nwr === 4'b1111);
    assign uart_nrd = !uart_data_selected | nrd;

    assign mem_clk = nrd & (nwr === 4'b1111);

`ifndef NO_INOUT_PINS
    assign scl0_io = scl0 ? 1'bz : 0;
    assign sda0_io = sda0 ? 1'bz : 0;

    genvar i;
    generate
        for (i = 0; i < I2C_PORTS; i = i + 1) begin : i2c_generate
            assign sda_io[i] = sda[i] ? 1'bz : 0;
        end
    endgenerate
`endif

    function [31:0] mem_rdata_f(input [31-MEMORY_SELECTOR_START_BIT:0] source);
        case (source)
            1: mem_rdata_f = rom_rdata;
            2: mem_rdata_f = ram_rdata;
            29: mem_rdata_f = {24'h0, uart_data_out};
            30: mem_rdata_f = {30'h0, uart_rx_fifo_empty, uart_tx_fifo_full};
            default: mem_rdata_f = ports_rdata;
        endcase
    endfunction

    tiny32 #(.RESET_PC(32'h08000000), .ISR_ADDRESS(24'h080000))
        cpu(.clk(cpu_clk), .nrd(nrd), .nwr(nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(1), .interrupt(irq), .interrupt_ack(interrupt_ack));

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(data_in[7:0]), .data_out(uart_data_out), .nwr(uart_nwr), .nrd(uart_nrd), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty));

    // todo i2c_others, spi

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    always @(posedge clk) begin
        if (!nreset) begin
            timer <= 0;
            timer_interrupt <= 0;
        end
        else if (interrupt_ack[0])
            timer_interrupt <= 0;
        else if (timer == {TIMER_BITS{1'b1}})
            timer_interrupt <= 1;
        timer <= timer + 1;
    end

    always @(posedge clk) begin
        if (timer[RESET_DELAY_BIT])
            nreset <= 1;
    end

    always @(negedge mem_clk) begin
        if (ram_selected) begin
            if (!nwr[0])
                ram1[ram_address] <= data_in[7:0];
            if (!nwr[1])
                ram2[ram_address] <= data_in[15:8];
            if (!nwr[2])
                ram3[ram_address] <= data_in[23:16];
            if (!nwr[3])
                ram4[ram_address] <= data_in[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
    end

    always @(negedge mem_clk) begin
        if (rom_selected)
            rom_rdata <= rom[rom_address];
    end

    always @(negedge mem_clk) begin
        if (ports_selected) begin
`ifndef NO_INOUT_PINS
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_io, sda_io};
`else
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_in, sda_in};
`endif
            if (!nwr[0]) {led, scl, sda} <= data_in[2:0];
        end
    end

endmodule
