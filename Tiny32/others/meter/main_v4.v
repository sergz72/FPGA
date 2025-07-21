`include "main.vh"
`include "tiny32.vh"

module main
#(parameter
I2C_PORTS_BITS = 1,
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
    inout wire [(1 << I2C_PORTS_BITS) - 1:0] scl_io,
    inout wire [(1 << I2C_PORTS_BITS) - 1:0] sda_io,
`else
    input wire [(1 << I2C_PORTS_BITS) - 1:0] scl_in,
    input wire [(1 << I2C_PORTS_BITS) - 1:0] sda_in,
    output wire [(1 << I2C_PORTS_BITS) - 1:0] scl_oe,
    output wire [(1 << I2C_PORTS_BITS) - 1:0] sda_oe,
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

    reg [`CPU_TIMER_BITS - 1:0] cpu_timer = 0;
    wire timer_interrupt;
    wire [31:0] time_value;

`ifndef MEMORY_DEBUG
    wire [31:0] address;
`endif

    wire hlt, error, wfi, mem_valid;
    wire [7:0] irq, interrupt_ack;
    wire [31:0] data_in, mem_rdata, i2c_rdata;
    reg [31:0] rom_rdata, ram_rdata, ports_rdata;
    wire [3:0] mem_nwr;
    reg mem_ready = 0;
    wire cpu_clk;
    wire rom_selected, ram_selected, ports_selected, uart_data_selected, timer_selected, time_selected, i2c_selected;
    wire uart_control_selected;
    wire [`STAGE_WIDTH - 1:0] stage;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_req, uart_ack;
    wire [7:0] uart_data_out;

    wire time_nrd, timer_nwr;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];
    
    reg [(1 << I2C_PORTS_BITS) - 1:0] scl = {(1 << I2C_PORTS_BITS){1'b1}};
    reg [(1 << I2C_PORTS_BITS) - 1:0] sda = {(1 << I2C_PORTS_BITS){1'b1}};
    wire [I2C_PORTS_BITS - 1:0] i2c_port;
    
    assign nhlt = !hlt;
    assign nerror = !error;
    assign nwfi = !wfi;

    assign irq = {7'h0, timer_interrupt};

    assign memory_selector = address[31:MEMORY_SELECTOR_START_BIT];

    assign cpu_clk = cpu_timer[`CPU_CLOCK_BIT];
    assign rom_selected = memory_selector == 1;
    assign ram_selected = memory_selector == 2;
    assign i2c_selected = memory_selector == 5'h1A;
    assign time_selected = memory_selector == 5'h1B;
    assign timer_selected = memory_selector == 5'h1C;
    assign uart_data_selected = memory_selector == 5'h1D;
    assign uart_control_selected = memory_selector == 5'h1E;
    assign ports_selected = memory_selector == 5'h1F;
    assign mem_rdata = mem_rdata_f(memory_selector);

    assign i2c_port = address[I2C_PORTS_BITS - 1:0];
`ifndef NO_INOUT_PINS
    assign i2c_rdata = {30'h0, scl_io[i2c_port], sda_io[i2c_port]};
`else
    assign i2c_rdata = {30'h0, scl_in[i2c_port], sda_in[i2c_port]};
`endif

    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];

    assign uart_req = mem_valid & uart_data_selected;
    assign time_nrd = !(mem_valid & time_selected & (mem_nwr == 4'b1111));
    assign timer_nwr = !(mem_valid & mem_ready & timer_selected & (mem_nwr != 4'b1111));
    
    genvar i;
    generate
        for (i = 0; i < (1 << I2C_PORTS_BITS); i = i + 1) begin : i2c_generate
`ifndef NO_INOUT_PINS
            assign sda_io[i] = sda[i] ? 1'bz : 0;
            assign scl_io[i] = scl[i] ? 1'bz : 0;
`else
            assign sda_oe[i] = !sda[i];
            assign scl_oe[i] = !scl[i];
`endif
        end
    endgenerate

    function [31:0] mem_rdata_f(input [31-MEMORY_SELECTOR_START_BIT:0] source);
        case (source)
            1: mem_rdata_f = rom_rdata;
            2: mem_rdata_f = ram_rdata;
            5'h1A: mem_rdata_f = i2c_rdata;
            5'h1B: mem_rdata_f = time_value;
            5'h1D: mem_rdata_f = {24'h0, uart_data_out};
            5'h1E: mem_rdata_f = {30'h0, uart_rx_fifo_empty, uart_tx_fifo_full};
            default: mem_rdata_f = ports_rdata;
        endcase
    endfunction

    tiny32 #(.RESET_PC(32'h08000000), .ISR_ADDRESS(24'h080000))
        cpu(.clk(cpu_clk), .mem_valid(mem_valid), .mem_nwr(mem_nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .mem_ready(mem_ready), .interrupt(irq), .interrupt_ack(interrupt_ack));

    uart_fifo #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(data_in[7:0]), .data_out(uart_data_out), .req(uart_req), .ack(uart_ack), .nwr(mem_nwr == 4'b1111),
                .nreset(nreset), .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty));

    timer #(.MHZ_TIMER_BITS(`MHZ_TIMER_BITS), .MHZ_TIMER_VALUE(`MHZ_TIMER_VALUE))
        t(.clk(clk), .nreset(nreset), .nwr(timer_nwr), .value(data_in), .interrupt(timer_interrupt), .interrupt_clear(interrupt_ack[0]));

    time_counter #(.MHZ_TIMER_BITS(`MHZ_TIMER_BITS), .MHZ_TIMER_VALUE(`MHZ_TIMER_VALUE))
        tc(.clk(clk), .nreset(nreset), .nrd(time_nrd), .value(time_value));

    // todo spi

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    always @(posedge clk) begin
        if (cpu_timer[`CPU_TIMER_BITS -1])
            nreset <= 1;
        cpu_timer <= cpu_timer + 1;
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & ram_selected) begin
            if (!mem_nwr[0])
                ram1[ram_address] <= data_in[7:0];
            if (!mem_nwr[1])
                ram2[ram_address] <= data_in[15:8];
            if (!mem_nwr[2])
                ram3[ram_address] <= data_in[23:16];
            if (!mem_nwr[3])
                ram4[ram_address] <= data_in[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
        mem_ready <= mem_valid & (ram_selected | rom_selected | ports_selected | uart_control_selected | uart_ack | time_selected | timer_selected | i2c_selected);
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & rom_selected)
            rom_rdata <= rom[rom_address];
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & ports_selected) begin
            ports_rdata <= {27'b0, con_button, psh_button, tra, trb, bak_button};
            if (!mem_nwr[0]) led <= data_in[0];
        end
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & i2c_selected & !mem_nwr[0])
            {scl[i2c_port], sda[i2c_port]} <= data_in[1:0];
    end

endmodule
