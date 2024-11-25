`include "main.vh"

`timescale 1 ns / 1 ps

module main
#(parameter
I2C_PORTS = 1,
// 2k 32 bit words RAM
RAM_BITS = 11,
// 8k 32 bit words ROM
ROM_BITS = 13)
(
    input wire clk,
    output wire nerror,
    output wire nwfi,
`ifdef MEMORY_DEBUG
    output wire [31:0] rom_addr,
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

    reg [`CPU_TIMER_BITS - 1:0] cpu_timer = 0;
    reg [`MHZ_TIMER_BITS - 1:0] mhz_timer = 0;
    wire timer_interrupt;
    reg timer_interrupt_clear = 0;
    wire [31:0] time_value;
    wire mhz_clock;

`ifndef NO_INOUT_PINS
    reg scl0 = 1;
    reg sda0 = 1;
    reg [I2C_PORTS - 1:0] scl = {I2C_PORTS{1'b1}};
    reg [I2C_PORTS - 1:0] sda = {I2C_PORTS{1'b1}};
`endif

`ifndef MEMORY_DEBUG
    wire [31:0] rom_addr;
`endif

    wire iBus_cmd_valid;
    reg iBus_rsp_valid = 0;

    wire dBusError, iBusError, dBusDeviceSelected;
    wire dBus_cmd_valid;
    reg dBus_rsp_ready = 0;

    reg [31:0] rom_rdata, rodata_rdata, ram_rdata, ports_rdata;
    wire [31:0] mem_wdata, mem_addr, mem_rdata;
    wire [RAM_BITS - 1:0] ram_address;
    wire [3:0] mem_wr_mask;
    wire [1:0] mem_size;
    wire wr;
    wire cpu_clk;
    wire rom_selected, rodata_selected, ram_selected, ports_selected, uart_data_selected, uart_control_selected, timer_selected, time_selected;
    reg ram_rsp_ready, ports_rsp_ready, uart_control_rsp_ready, rodata_rsp_ready, uart_data_rsp_ready, time_rsp_ready, timer_rsp_ready;
    reg uart_data_rsp_sel, time_rsp_sel, timer_rsp_sel;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;
    reg [31-MEMORY_SELECTOR_START_BIT:0] memory_selectorf;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_nrd, uart_nwr;
    wire [7:0] uart_data_out;
 
    wire time_nrd, timer_nwr;

    wire error, wfi;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign cpu_clk = cpu_timer[`CPU_CLOCK_BIT];
    assign mhz_clock = mhz_timer[`MHZ_TIMER_BITS - 1];

    assign ram_address = mem_addr[RAM_BITS + 1:2];
    assign memory_selector = mem_addr[31:MEMORY_SELECTOR_START_BIT];

    assign nerror = !error;
    assign nwfi = !wfi;
    
    assign rom_selected = rom_addr[31:MEMORY_SELECTOR_START_BIT] == 1;
    assign rodata_selected = memory_selector == 1;
    assign ram_selected = memory_selector == 2;


    assign time_selected = memory_selector == 5'h1B;
    assign timer_selected = memory_selector == 5'h1C;

    assign uart_data_selected = memory_selector == 5'h1D;
    assign uart_control_selected = memory_selector == 5'h1E;
    assign ports_selected = memory_selector == 5'h1F;
    
    assign mem_rdata = mem_rdata_f(memory_selectorf);

    assign uart_nrd = !(dBus_cmd_valid & uart_data_rsp_sel & !wr);
    assign uart_nwr = !(dBus_cmd_valid & uart_data_rsp_sel & wr);

    assign time_nrd = !(dBus_cmd_valid & time_rsp_sel & !wr);
    assign timer_nwr = !(dBus_cmd_valid & timer_rsp_sel & wr);

    assign iBusError = iBus_cmd_valid & !rom_selected;
    assign dBusDeviceSelected = rodata_selected | ram_selected | ports_selected | uart_control_selected | uart_data_selected | timer_selected | time_selected;
    assign dBusError = dBus_cmd_valid & !dBusDeviceSelected;
    assign error = iBusError | dBusError;

`ifndef NO_INOUT_PINS
    assign scl0_io = scl0 ? 1'bz : 0;
    assign sda0_io = sda0 ? 1'bz : 0;

    genvar i;
    generate
        for (i = 0; i < I2C_PORTS; i = i + 1) begin
            assign sda_io[i] = sda[i] ? 1'bz : 0;
        end
    endgenerate
`endif

    function [31:0] mem_rdata_f(input [31-MEMORY_SELECTOR_START_BIT:0] source);
        case (source)
            1: mem_rdata_f = rodata_rdata;
            2: mem_rdata_f = ram_rdata;
            5'h1B: mem_rdata_f = time_value;
            5'h1D: mem_rdata_f = {24'h0, uart_data_out};
            5'h1E: mem_rdata_f = {30'h0, uart_rx_fifo_empty, uart_tx_fifo_full};
            default: mem_rdata_f = ports_rdata;
        endcase
    endfunction

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    VexRiscv cpu(.clk(cpu_clk),
                .reset(!nreset),
                .iBus_cmd_valid(iBus_cmd_valid),
                .iBus_cmd_ready(1'b1),
                .iBus_cmd_payload_pc(rom_addr),
                .iBus_rsp_valid(iBus_rsp_valid),
                .iBus_rsp_payload_error(iBusError),
                .iBus_rsp_payload_inst(rom_rdata),
                .timerInterrupt(timer_interrupt),
                .externalInterrupt(1'h0),
                .softwareInterrupt(1'h0),
                .CsrPlugin_inWfi(wfi),
                .dBus_cmd_valid(dBus_cmd_valid),
                .dBus_cmd_ready(1'b1),
                .dBus_cmd_payload_wr(wr),
                .dBus_cmd_payload_mask(mem_wr_mask),
                .dBus_cmd_payload_address(mem_addr),
                .dBus_cmd_payload_data(mem_wdata),
                .dBus_cmd_payload_size(mem_size),
                .dBus_rsp_ready(dBus_rsp_ready),
                .dBus_rsp_error(dBusError),
                .dBus_rsp_data(mem_rdata)
    );

    uart_fifo #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(mem_wdata[7:0]), .data_out(uart_data_out), .nwr(uart_nwr), .nrd(uart_nrd), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty));

    timer t(.clk(mhz_clock), .nreset(nreset), .nwr(timer_nwr), .value(mem_wdata), .interrupt(timer_interrupt), .interrupt_clear(timer_interrupt_clear));

    time_counter tc(.clk(mhz_clock), .nreset(nreset), .nrd(time_nrd), .value(time_value));

    // todo i2c_display, i2c_others, spi
    
    always @(posedge clk) begin
        if (cpu_timer[`CPU_TIMER_BITS -1])
            nreset <= 1;
        cpu_timer <= cpu_timer + 1;
    end

    always @(posedge clk) begin
        if (mhz_timer == `MHZ_TIMER_VALUE)
            mhz_timer <= 0;
        else
            mhz_timer <= mhz_timer + 1;
    end

    always @(negedge cpu_clk) begin
        if (!nreset)
            dBus_rsp_ready  <= 1'b0;
        else if (dBus_cmd_valid)
            dBus_rsp_ready <= dBusDeviceSelected;
    end

    always @(negedge cpu_clk) begin
        iBus_rsp_valid  <= rom_selected;
        if (dBus_cmd_valid)
            rodata_rsp_ready <= rodata_selected;
        if (rom_selected)
            rom_rdata <= rom[rom_addr[ROM_BITS + 1:2]];
        if (rodata_selected)
            rodata_rdata <= rom[mem_addr[ROM_BITS + 1:2]];
    end

    always @(negedge cpu_clk) begin
        if (dBus_cmd_valid)
            memory_selectorf <= memory_selector;
        ram_rsp_ready <= ram_selected;
        if (dBus_cmd_valid & ram_selected) begin
            if (wr & mem_wr_mask[0]) ram1[ram_address] <= mem_wdata[ 7: 0];
            if (wr & mem_wr_mask[1]) ram2[ram_address] <= mem_wdata[15: 8];
            if (wr & mem_wr_mask[2]) ram3[ram_address] <= mem_wdata[23:16];
            if (wr & mem_wr_mask[3]) ram4[ram_address] <= mem_wdata[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
    end

    always @(negedge cpu_clk) begin
        if (!nreset) begin
            timer_interrupt_clear <= 0;
        end
        else begin
            uart_data_rsp_sel <= uart_data_selected;
            time_rsp_sel <= time_selected;
            timer_rsp_sel <= timer_selected;
            if (dBus_cmd_valid) begin
                ports_rsp_ready <= ports_selected;
                uart_control_rsp_ready <= uart_control_selected;
                uart_data_rsp_ready <= uart_data_selected;
                time_rsp_ready <= time_selected;
                timer_rsp_ready <= timer_selected;
            end
            if (dBus_cmd_valid & ports_selected) begin
    `ifndef NO_INOUT_PINS
                ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_io, sda0_io};
    `else
                ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_in, sda0_in};
    `endif
                if (wr & mem_wr_mask[0]) {led, scl0, sda0} <= mem_wdata[2:0];
                if (wr & mem_wr_mask[1]) timer_interrupt_clear <= mem_wdata[8];
            end
        end
    end

endmodule
