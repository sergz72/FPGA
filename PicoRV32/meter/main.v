`include "main.vh"

`timescale 1 ns / 1 ps

module main
#(parameter TIMER_INTERRUPT = 0,
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
    inout wire scl_io,
    inout wire sda_io,
    input wire con_button,
    input wire psh_button,
    input wire tra, // encoder
    input wire trb, // encoder
    input wire bak_button,
    output reg led = 1
);
    localparam RAM_START = 32'h40000000;
    localparam RAM_END = RAM_START + (1<<RAM_BITS) - 1;
    localparam MEMORY_SELECTOR_START_BIT = 29;

    reg reset = 0;
    reg [TIMER_BITS - 1:0] timer = 0;
    reg interrupt = 0;
    reg scl = 1;
    reg sda = 1;

`ifndef MEMORY_DEBUG
    wire [31:0] mem_addr;
`endif

    wire [31:0] irq, eoi, mem_wdata;
    reg [31:0] mem_rdata;
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
//    wire rom_selected, ram_selected, port1_selected;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign irq = {31'h0, interrupt};

    assign cpu_clk = timer[CPU_CLOCK_BIT];
    assign mem_invalid = mem_valid & !mem_ready;
//    assign rom_selected = mem_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 0;
//    assign ram_selected = mem_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 1;
//    assign port1_selected = mem_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 2;

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    picorv32 #(.ENABLE_IRQ(1),
               .ENABLE_FAST_MUL(1),
               .STACKADDR(RAM_END),
               .PROGADDR_IRQ(32'h8)
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

    assign scl_io = scl ? 1'bz : 0;
    assign sda_io = sda ? 1'bz : 0;

    always @(posedge clk) begin
        if (TIMER_INTERRUPT != 0) begin
            if (timer == {TIMER_BITS{1'b1}})
                interrupt <= 1;
            else if (eoi[0])
                interrupt <= 0;
        end
        timer <= timer + 1;
    end

    always @(negedge timer[RESET_DELAY_BIT]) begin
        reset <= 1;
    end

    always @(negedge cpu_clk) begin
        mem_ready <= mem_valid;
        if (mem_valid) begin
            case (mem_addr[31:MEMORY_SELECTOR_START_BIT])
                0: begin // rom
                    mem_rdata <= rom[mem_addr[ROM_BITS + 1:2]];
                end
                1: begin // ram
                    mem_rdata <= {ram4[mem_addr[RAM_BITS + 1:2]], ram3[mem_addr[RAM_BITS + 1:2]], ram2[mem_addr[RAM_BITS + 1:2]], ram1[mem_addr[RAM_BITS + 1:2]]};
                    if (mem_wstrb[0]) ram1[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[ 7: 0];
                    if (mem_wstrb[1]) ram2[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[15: 8];
                    if (mem_wstrb[2]) ram3[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) ram4[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[31:24];
                end
                2: begin
                    mem_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_io, sda_io};
                    if (mem_wstrb[0]) {led, scl, sda} <= mem_wdata[2:0];
                end
            endcase
        end
    end

endmodule
