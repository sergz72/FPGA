`include "main.vh"

`timescale 1 ns / 1 ps

module main
#(parameter
// 3.375 interrupts/sec
TIMER_BITS = 23,
// about 20 ms delay
RESET_DELAY_BIT = 19,
// div = 64
CPU_CLOCK_BIT = 5,
// 1k 32 bit words RAM
RAM_BITS = 10,
// 1k 32 bit words ROM
ROM_BITS = 10)
(
    input wire clk,
    output wire trap,
    output wire mem_invalid,
`ifdef MEMORY_DEBUG
    output wire [31:0] mem_addr,
`endif
`ifndef NO_INOUT_PINS
    inout wire scl_io,
    inout wire sda_io,
`else
    input wire scl_in,
    input wire sda_in,
    output reg scl = 1,
    output reg sda = 1,
`endif
    input wire con_button,
    input wire psh_button,
    input wire tra, // encoder
    input wire trb, // encoder
    input wire bak_button,
    output reg led = 1
);
    localparam RAM_START = 32'h40000000;
    localparam RAM_END = RAM_START + (1<<RAM_BITS);
    localparam MEMORY_SELECTOR_START_BIT = 30;

    reg reset = 0;
    reg [TIMER_BITS - 1:0] timer = 0;
    reg interrupt = 0;

`ifndef NO_INOUT_PINS
    reg scl = 1;
    reg sda = 1;
`endif

`ifndef MEMORY_DEBUG
    wire [31:0] mem_addr;
`endif

    wire [31:0] irq, eoi, mem_wdata;
    wire [31:0] mem_rdata;
    reg [31:0] rom_rdata, ram_rdata, ports_rdata;
    wire [3:0] mem_wstrb;
    wire mem_valid, mem_instr;
    reg mem_ready = 0;
	wire mem_la_read;
	wire mem_la_write;
	wire [31:0] mem_la_addr;
	wire [31:0] mem_la_wdata;
	wire [ 3:0] mem_la_wstrb;
	wire pcpi_valid;
	wire [31:0] pcpi_insn;
	wire [31:0] pcpi_rs1;
	wire [31:0] pcpi_rs2;
	wire trace_valid;
	wire [35:0] trace_data;
    wire cpu_clk;
    wire rom_selected, ram_selected, ports_selected;
    reg rom_ready = 0;
    reg ram_ready = 0;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign irq = {28'h0, interrupt, 3'h0};

    assign cpu_clk = timer[CPU_CLOCK_BIT];
    assign mem_invalid = mem_valid & !mem_ready;
    assign rom_selected = mem_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 0;
    assign ram_selected = mem_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 1;
    assign ports_selected = mem_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 3;
    assign mem_rdata = rom_ready ? rom_rdata : (ram_ready ? ram_rdata : ports_rdata);

`ifndef NO_INOUT_PINS
    assign scl_io = scl ? 1'bz : 0;
    assign sda_io = sda ? 1'bz : 0;
`endif

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
               .PROGADDR_IRQ(32'h10),
               .BARREL_SHIFTER(1)
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

    always @(posedge clk) begin
        if (timer == {TIMER_BITS{1'b1}})
            interrupt <= 1;
        else if (eoi[0])
            interrupt <= 0;
        timer <= timer + 1;
    end

    always @(negedge timer[RESET_DELAY_BIT]) begin
        reset <= 1;
    end

    always @(negedge cpu_clk) begin
        mem_ready <= rom_selected | ram_selected | ports_selected;
        rom_ready <= rom_selected;
        ram_ready <= ram_selected;
    end

    always @(negedge cpu_clk) begin
        if (rom_selected)
            rom_rdata <= rom[mem_addr[ROM_BITS + 1:2]];
    end

    always @(negedge cpu_clk) begin
        if (ram_selected) begin
            if (mem_wstrb[0]) ram1[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[ 7: 0];
            if (mem_wstrb[1]) ram2[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[15: 8];
            if (mem_wstrb[2]) ram3[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[23:16];
            if (mem_wstrb[3]) ram4[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[31:24];
            ram_rdata <= {ram4[mem_addr[RAM_BITS + 1:2]], ram3[mem_addr[RAM_BITS + 1:2]], ram2[mem_addr[RAM_BITS + 1:2]], ram1[mem_addr[RAM_BITS + 1:2]]};
        end
    end

    always @(negedge cpu_clk) begin
        if (ports_selected) begin
`ifndef NO_INOUT_PINS
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_io, sda_io};
`else
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_in, sda_in};
`endif
            if (mem_wstrb[0]) {led, scl, sda} <= mem_wdata[2:0];
        end
    end

endmodule
