`timescale 1 ns / 1 ps

module main32
#(parameter
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
SDRAM_PRECHARGE_LATENCY = 2,
UART_BAUD = 115200
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
    input wire [31:0] sdram_data_in,
    output wire [31:0] sdram_data_out,
    output wire [3:0] sdram_dqm
);
    localparam RAM_START = 32'h20000000;
    localparam RAM_END = RAM_START + (4<<RAM_BITS);
    localparam MEMORY_SELECTOR_START_BIT = 28;
    localparam UART_CLOCK_COUNTER_BITS = $clog2(CLK_FREQUENCY / UART_BAUD);
    localparam UART_CLOCK_DIV1 = CLK_FREQUENCY / UART_BAUD;
    localparam UART_CLOCK_DIV = UART_CLOCK_DIV1[UART_CLOCK_COUNTER_BITS-1:0];

    reg nreset = 0;

    wire trap;

    wire [31:0] irq, eoi;
    wire [31:0] mem_rdata;
    reg [31:0] rom_rdata, ram_rdata;
    wire mem_valid, mem_instr;
	wire mem_la_read;
	wire mem_la_write;
	wire [31:0] mem_la_addr, mem_addr;
	wire [31:0] mem_la_wdata, mem_wdata;
	wire [ 3:0] mem_la_wstrb, mem_wstrb;
    reg mem_ready = 0;
	wire pcpi_valid;
	wire [31:0] pcpi_insn;
	wire [31:0] pcpi_rs1;
	wire [31:0] pcpi_rs2;
	wire trace_valid;
	wire [35:0] trace_data;
    wire rom_selected, ram_selected, port_selected, uart_data_selected, uart_control_selected, sdram_selected;
    reg wr = 0;
    reg rd = 0;
    wire [RAM_BITS - 1:0] ram_address;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    reg[RESET_BIT:0] timer = 0;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_req;
    wire uart_ack;
    wire [7:0] uart_data_out;

    wire [31:0] sdram_rdata;
    wire sdram_req, sdram_ack;
    wire [3:0] sdram_nwr;

    assign ntrap = ~trap;

    assign irq = 32'h0; //{28'h0, timer_interrupt, 3'h0};

    assign memory_selector = mem_la_addr[31:MEMORY_SELECTOR_START_BIT];

    assign rom_selected = memory_selector == 1;
    assign ram_selected = memory_selector == 2;
    assign port_selected = memory_selector == 3;
    assign uart_data_selected = memory_selector == 4;
    assign uart_control_selected = memory_selector == 5;
    assign sdram_selected = memory_selector == 6;

    assign mem_rdata = rom_selected
        ? rom_rdata
        : (ram_selected ?
            ram_rdata
            : (uart_data_selected
                ? {24'h0, uart_data_out}
                : (sdram_selected
                    ? sdram_rdata
                    : {30'h0, uart_rx_fifo_empty, uart_tx_fifo_full})));
    
    assign ram_address = mem_la_addr[RAM_BITS + 1:2];

    assign uart_req = uart_data_selected & mem_valid;
    assign sdram_req = sdram_selected & mem_valid;

    assign sdram_nwr[0] = !mem_wstrb[0];
    assign sdram_nwr[1] = !mem_wstrb[1];
    assign sdram_nwr[2] = !mem_wstrb[2];
    assign sdram_nwr[3] = !mem_wstrb[3];

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
               .PROGADDR_IRQ(32'h1000_0010),
               .PROGADDR_RESET(32'h1000_0000),
               .BARREL_SHIFTER(1),
               .ENABLE_IRQ_TIMER(1),
               .ENABLE_COUNTERS(1),
               .ENABLE_COUNTERS64(0),
               .LATCHED_IRQ(0)
        )
        cpu(.clk(clk),
                .resetn(nreset),
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
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(mem_wdata[7:0]), .data_out(uart_data_out), .nwr(!mem_wstrb[0]), .req(uart_req), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty), .ack(uart_ack));

    sdram_controller #(.SDRAM_ADDRESS_WIDTH(SDRAM_ADDRESS_WIDTH), .SDRAM_COLUMN_ADDRESS_WIDTH(SDRAM_COLUMN_ADDRESS_WIDTH),
                        .BANK_BITS(SDRAM_BANK_BITS), .CLK_FREQUENCY(CLK_FREQUENCY), .MODE_REGISTER_VALUE(SDRAM_MODE_REGISTER_VALUE),
                        .AUTOREFRESH_LATENCY(SDRAM_AUTOREFRESH_LATENCY), .CAS_LATENCY(SDRAM_CAS_LATENCY), .PRECHARGE_LATENCY(SDRAM_PRECHARGE_LATENCY),
                        .BANK_ACTIVATE_LATENCY(SDRAM_BANK_ACTIVATE_LATENCY))
                    sdram_c(.clk(clk_sdram), .nreset(nreset), .cpu_address(mem_la_addr[22:2]), .cpu_data_in(mem_wdata), .cpu_data_out(sdram_rdata),
                                .cpu_req(sdram_req), .cpu_ack(sdram_ack), .cpu_nwr(sdram_nwr), .sdram_ncs(sdram_ncs), .sdram_ras(sdram_ras),
                                .sdram_cas(sdram_cas), .sdram_clk(sdram_clk), .sdram_address(sdram_address), .sdram_ba(sdram_ba),
                                .sdram_nwe(sdram_nwe), .sdram_data_in(sdram_data_in), .sdram_data_out(sdram_data_out), .sdram_dqm(sdram_dqm));

    always @(posedge clk) begin
        if (timer[RESET_BIT])
            nreset <= 1;
        timer <= timer + 1;
    end

    always @(posedge clk) begin
        mem_ready <= mem_valid & (rom_selected | ram_selected | port_selected | uart_control_selected | uart_ack | sdram_ack);
    end

    always @(posedge clk) begin
        if (mem_valid & rom_selected)
            rom_rdata <= rom[mem_la_addr[ROM_BITS + 1:2]];
    end

    always @(posedge clk) begin
        if (mem_valid & ram_selected) begin
            if (mem_wstrb[0]) ram1[ram_address] <= mem_wdata[ 7: 0];
            if (mem_wstrb[1]) ram2[ram_address] <= mem_wdata[15: 8];
            if (mem_wstrb[2]) ram3[ram_address] <= mem_wdata[23:16];
            if (mem_wstrb[3]) ram4[ram_address] <= mem_wdata[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
    end

    always @(posedge clk) begin
        if (mem_valid & port_selected) begin
            if (mem_wstrb[0]) {led2, led1} <= mem_la_wdata[1:0];
        end
    end

endmodule
