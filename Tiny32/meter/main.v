`include "main.vh"

module main
#(parameter
UART_BAUD = 115200,
I2C_PORTS = 1,
// 1ms
RESET_DELAY = 1,
CPU_FREQ = 1000000,
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
    localparam UART_CLOCK_DIV = `OSC_FREQ / UART_BAUD;
    localparam UART_CLOCK_COUNTER_BITS = $clog2(`OSC_FREQ / UART_BAUD) + 1;
    localparam CPU_TIMER_BITS = $clog2(`OSC_FREQ * RESET_DELAY / 1000) + 1;
    localparam CPU_CLOCK_BIT = $clog2(`OSC_FREQ / CPU_FREQ);
    localparam MHZ_TIMER_BITS = $clog2(`OSC_FREQ / 1000000);
    localparam MHZ_TIMER_VALUE = `OSC_FREQ / 1000000 - 1;

    localparam MEMORY_SELECTOR_START_BIT = 27;

    reg nreset = 0;

    reg [CPU_TIMER_BITS - 1:0] cpu_timer = 0;
    reg [MHZ_TIMER_BITS - 1:0] mhz_timer = 0;
    wire timer_interrupt;
    wire [31:0] time_value;
    wire mhz_clock;

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
    wire rom_selected, ram_selected, ports_selected, uart_data_selected, timer_selected, time_selected;
    //wire uart_control_selected;
    wire [2:0] stage;
    wire mem_clk;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_nwr, uart_nrd;
    wire [7:0] uart_data_out;

    wire time_nrd, timer_nwr;

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

    assign cpu_clk = cpu_timer[CPU_CLOCK_BIT];
    assign rom_selected = memory_selector === 1;
    assign ram_selected = memory_selector === 2;
    assign time_selected = memory_selector === 5'h1B;
    assign timer_selected = memory_selector === 5'h1C;
    assign uart_data_selected = memory_selector === 5'h1D;
    //assign uart_control_selected = memory_selector === 5'h1E;
    assign ports_selected = memory_selector === 5'h1F;
    assign mem_rdata = mem_rdata_f(memory_selector);

    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];

    assign uart_nwr = !uart_data_selected | (nwr === 4'b1111);
    assign uart_nrd = !uart_data_selected | nrd;
    assign time_nrd = !time_selected | nrd;
    assign timer_nwr = !timer_selected | (nwr === 4'b1111);

    assign mem_clk = nrd & (nwr === 4'b1111);

    assign mhz_clock = mhz_timer[MHZ_TIMER_BITS - 1];
    
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
            5'h1B: mem_rdata_f = time_value;
            5'h1D: mem_rdata_f = {24'h0, uart_data_out};
            5'h1E: mem_rdata_f = {30'h0, uart_rx_fifo_empty, uart_tx_fifo_full};
            default: mem_rdata_f = ports_rdata;
        endcase
    endfunction

    tiny32 #(.RESET_PC(32'h08000000), .ISR_ADDRESS(24'h080000))
        cpu(.clk(cpu_clk), .nrd(nrd), .nwr(nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(1), .interrupt(irq), .interrupt_ack(interrupt_ack));

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(data_in[7:0]), .data_out(uart_data_out), .nwr(uart_nwr), .nrd(uart_nrd), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty));

    timer t(.clk(mhz_clock), .nreset(nreset), .nwr(timer_nwr), .value(data_in), .interrupt(timer_interrupt), .interrupt_clear(interrupt_ack[0]));

    time_counter tc(.clk(mhz_clock), .nreset(nreset), .nrd(time_nrd), .value(time_value));

    // todo i2c_others, spi

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    always @(posedge clk) begin
        if (cpu_timer[CPU_TIMER_BITS -1])
            nreset <= 1;
        cpu_timer <= cpu_timer + 1;
    end

    always @(posedge clk) begin
        if (!nreset)
            mhz_timer <= 0;
        else if (mhz_timer == MHZ_TIMER_VALUE - 1)
            mhz_timer <= 0;
        else
            mhz_timer <= mhz_timer + 1;
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
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_io, sda0_io};
`else
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_in, sda0_in};
`endif
            if (!nwr[0]) {led, scl0, sda0} <= data_in[2:0];
        end
    end

endmodule
