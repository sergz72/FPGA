`include "main.vh"

`timescale 1 ns / 1 ps

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
    output wire trap,
    output wire mem_invalid,
`ifdef MEMORY_DEBUG
    output wire [31:0] mem_la_addr,
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
    localparam RAM_START = 32'h10000000;
    localparam RAM_END = RAM_START + (4<<RAM_BITS);
    localparam MEMORY_SELECTOR_START_BIT = 27;

    reg reset = 0;

    reg [TIMER_BITS - 1:0] timer = 0;
    reg interrupt = 0;

`ifndef NO_INOUT_PINS
    reg scl0 = 1;
    reg sda0 = 1;
    reg [I2C_PORTS - 1:0] scl = {I2C_PORTS{1'b1}};
    reg [I2C_PORTS - 1:0] sda = {I2C_PORTS{1'b1}};
`endif

`ifndef MEMORY_DEBUG
    wire [31:0] mem_la_addr;
`endif

    wire [31:0] irq, eoi, mem_wdata;
    wire [31:0] mem_rdata;
    reg [31:0] rom_rdata, ram_rdata, ports_rdata;
    wire [3:0] mem_wstrb;
    wire mem_valid, mem_instr;
    reg mem_ready = 0;
	wire mem_la_read;
	wire mem_la_write;
	wire [31:0] mem_addr;
	wire [31:0] mem_la_wdata;
	wire [ 3:0] mem_la_wstrb;
	wire pcpi_valid;
	wire [31:0] pcpi_insn;
	wire [31:0] pcpi_rs1;
	wire [31:0] pcpi_rs2;
	wire trace_valid;
	wire [35:0] trace_data;
    wire cpu_clk;
    wire rom_selected, ram_selected, ports_selected, uart_data_selected, uart_control_selected;
    reg rom_ready = 0;
    reg ram_ready = 0;
    reg wr = 0;
    reg rd = 0;
    reg uart_data_ready = 0;
    reg uart_control_ready = 0;
    wire [RAM_BITS - 1:0] ram_address;
    reg [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_nrd, uart_nwr;
    wire [7:0] uart_data_out;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign irq = {28'h0, interrupt, 3'h0};

    assign cpu_clk = timer[CPU_CLOCK_BIT];
    assign mem_invalid = mem_valid & !mem_ready;
    assign rom_selected = memory_selector === 1;
    assign ram_selected = memory_selector === 2;
    assign uart_data_selected = memory_selector === 5'h1D;
    assign uart_control_selected = memory_selector === 5'h1E;
    assign ports_selected = memory_selector === 5'h1F;
    assign mem_rdata = mem_rdata_f(memory_selector);

    assign uart_nrd = !(mem_valid & uart_data_selected & rd);
    assign uart_nwr = !(mem_valid & uart_data_selected & wr);

    assign ram_address = mem_la_addr[RAM_BITS + 1:2];

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

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    picorv32 #(.ENABLE_IRQ(1),
               .ENABLE_FAST_MUL(1),
               .ENABLE_DIV(1),
               .STACKADDR(RAM_END),
               .PROGADDR_IRQ(32'h0800_0010),
               .PROGADDR_RESET(32'h0800_0000),
               .BARREL_SHIFTER(1),
               .ENABLE_IRQ_TIMER(1),
               .ENABLE_COUNTERS(1),
               .ENABLE_COUNTERS64(0),
               .LATCHED_IRQ(0)
        )
        cpu(.clk(cpu_clk),
                .resetn(reset),
                .trap(trap),
                .irq(irq),
                .eoi(eoi),
                .mem_ready(mem_ready),
                .mem_instr(mem_instr),
                .mem_wdata(mem_wdata),
                .mem_rdata(mem_rdata),
                .mem_addr(mem_addr),
                .mem_wstrb(mem_wstrb),
                .mem_valid(mem_valid),
                .pcpi_wr(1'b0),
                .pcpi_rd(0),
                .pcpi_wait(1'b0),
                .pcpi_ready(1'b0),
	            .mem_la_read(mem_la_read),
	            .mem_la_write(mem_la_write),
	            .mem_la_addr(mem_la_addr),
	            .mem_la_wdata(mem_la_wdata),
	            .mem_la_wstrb(mem_la_wstrb),
	            .pcpi_valid(pcpi_valid),
	            .pcpi_insn(pcpi_insn),
	            .pcpi_rs1(pcpi_rs1),
	            .pcpi_rs2(pcpi_rs2),
                .trace_valid(trace_valid),
                .trace_data(trace_data)
        );

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(mem_la_wdata[7:0]), .data_out(uart_data_out), .nwr(uart_nwr), .nrd(uart_nrd), .nreset(reset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty));

    // todo i2c_others, spi

    always @(posedge clk) begin
        if (timer == {TIMER_BITS{1'b1}})
            interrupt <= 1;
        else if (eoi[3])
            interrupt <= 0;
        timer <= timer + 1;
    end

    always @(negedge timer[RESET_DELAY_BIT]) begin
        reset <= 1;
    end

    always @(negedge cpu_clk) begin
        if (!reset) begin
            wr <= 0;
            rd <= 0;
        end
        else begin
            wr <= mem_la_write;
            rd <= mem_la_read;
            if (mem_la_read | mem_la_write)
                memory_selector <= mem_la_addr[31:MEMORY_SELECTOR_START_BIT];
        end
    end

    always @(posedge mem_valid) begin
        mem_ready <= rom_selected | ram_selected | ports_selected | uart_control_selected | uart_data_selected;
    end

    always @(posedge mem_valid) begin
        if (rom_selected)
            rom_rdata <= rom[mem_la_addr[ROM_BITS + 1:2]];
    end

    always @(posedge mem_valid) begin
        if (ram_selected) begin
            if (wr & mem_la_wstrb[0]) ram1[ram_address] <= mem_la_wdata[ 7: 0];
            if (wr & mem_la_wstrb[1]) ram2[ram_address] <= mem_la_wdata[15: 8];
            if (wr & mem_la_wstrb[2]) ram3[ram_address] <= mem_la_wdata[23:16];
            if (wr & mem_la_wstrb[3]) ram4[ram_address] <= mem_la_wdata[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
    end

    always @(posedge mem_valid) begin
        if (ports_selected) begin
`ifndef NO_INOUT_PINS
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_io, sda0_io};
`else
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_in, sda0_in};
`endif
            if (wr & mem_la_wstrb[0]) {led, scl0, sda0} <= mem_la_wdata[2:0];
        end
    end

endmodule
