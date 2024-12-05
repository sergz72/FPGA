`include "main.vh"
`include "tiny32.vh"

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
    output wire hlt,
    output wire error,
    output wire wfi,
`ifdef MEMORY_DEBUG
    output wire [31:0] address,
`endif
    output reg led = 1
);
    localparam MEMORY_SELECTOR_START_BIT = 30;

    reg nreset = 0;

    reg [TIMER_BITS - 1:0] timer = 0;
    reg timer_interrupt = 0;

`ifndef MEMORY_DEBUG
    wire [31:0] address;
`endif

    wire [7:0] irq, interrupt_ack;
    wire [31:0] data_in, mem_rdata;
    reg [31:0] rom_rdata, ram_rdata;
    wire [3:0] mem_nwr;
    wire mem_valid;
    wire cpu_clk;
    wire rom_selected, ram_selected, ports_selected;
    wire [`STAGE_WIDTH - 1:0] stage;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;
    reg mem_ready = 0;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign irq = {7'h0, timer_interrupt};

    assign cpu_clk = timer[CPU_CLOCK_BIT];
    assign rom_selected = address[31:MEMORY_SELECTOR_START_BIT] === 0;
    assign ram_selected = address[31:MEMORY_SELECTOR_START_BIT] === 1;
    assign ports_selected = address[31:MEMORY_SELECTOR_START_BIT] === 3;
    assign mem_rdata = rom_selected ? rom_rdata : ram_rdata;

    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];

    tiny32 cpu(.clk(cpu_clk), .mem_valid(mem_valid), .mem_nwr(mem_nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .mem_ready(mem_ready), .interrupt(irq), .interrupt_ack(interrupt_ack));

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    always @(posedge clk) begin
        if (interrupt_ack[0])
            timer_interrupt <= 0;
        else if (timer == {TIMER_BITS{1'b1}})
            timer_interrupt <= 1;
        timer <= timer + 1;
    end

    always @(negedge timer[RESET_DELAY_BIT]) begin
        nreset <= 1;
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
        mem_ready <= mem_valid & (ram_selected | rom_selected | ports_selected);
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & rom_selected)
            rom_rdata <= rom[rom_address];
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & ports_selected) begin
            if (!mem_nwr[0]) led <= data_in[0];
        end
    end

endmodule
