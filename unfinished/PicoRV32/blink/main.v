`timescale 1 ns / 1 ps

module main
#(parameter
RESET_BIT = 19,
TIMER_BITS = 23,
// 4k 32 bit words RAM
RAM_BITS = 12,
// 8k 32 bit words ROM
ROM_BITS = 13)
(
    input wire clk,
    output wire ntrap,
    output reg led,
    output wire tx,
    input wire rx
);
    localparam RAM_START = 32'h80000000;
    localparam RAM_END = RAM_START + (4<<RAM_BITS);
    localparam MEMORY_SELECTOR_START_BIT = 30;

    reg nreset = 0;

    reg timer_interrupt;
    wire timer_interrupt_clear;

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
    wire rom_selected, ram_selected, port_selected;
    reg wr = 0;
    reg rd = 0;
    wire [RAM_BITS - 1:0] ram_address;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    reg[TIMER_BITS-1:0] timer = 0;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign ntrap = ~trap;

    assign irq = {28'h0, timer_interrupt, 3'h0};

    assign memory_selector = mem_la_addr[31:MEMORY_SELECTOR_START_BIT];

    assign rom_selected = memory_selector == 1;
    assign ram_selected = memory_selector == 2;
    assign port_selected = memory_selector == 3;

    assign mem_rdata = mem_rdata_f(memory_selector);

    assign timer_interrupt_clear = eoi[3];
    
    assign ram_address = mem_la_addr[RAM_BITS + 1:2];

    function [31:0] mem_rdata_f(input [31-MEMORY_SELECTOR_START_BIT:0] source);
        case (source)
            1: mem_rdata_f = rom_rdata;
            default: mem_rdata_f = ram_rdata;
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
               .PROGADDR_IRQ(32'h4000_0010),
               .PROGADDR_RESET(32'h4000_0000),
               .BARREL_SHIFTER(1),
               .ENABLE_IRQ_TIMER(0),
               .ENABLE_COUNTERS(0),
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

    always @(posedge clk) begin
        if (timer[RESET_BIT])
            nreset <= 1;
        if (timer[TIMER_BITS - 1]) begin
            timer <= 0;
            timer_interrupt <= 1;
        end
        else begin
            timer <= timer + 1;
            if (timer_interrupt_clear)
                timer_interrupt <= 0;
        end
    end

    always @(posedge clk) begin
        mem_ready <= mem_valid & rom_selected | ram_selected | port_selected;
    end

    always @(posedge clk) begin
        if (mem_valid & rom_selected)
            rom_rdata <= rom[mem_la_addr[ROM_BITS + 1:2]];
    end

    always @(posedge clk) begin
        if (mem_valid & ram_selected) begin
            if (mem_wstrb[0]) ram1[ram_address] <= mem_la_wdata[ 7: 0];
            if (mem_wstrb[1]) ram2[ram_address] <= mem_la_wdata[15: 8];
            if (mem_wstrb[2]) ram3[ram_address] <= mem_la_wdata[23:16];
            if (mem_wstrb[3]) ram4[ram_address] <= mem_la_wdata[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
    end

    always @(posedge clk) begin
        if (mem_valid & port_selected) begin
            if (mem_wstrb[0]) led <= mem_la_wdata[0];
        end
    end

endmodule
