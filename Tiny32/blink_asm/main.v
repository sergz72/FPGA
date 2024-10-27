`include "main.vh"
`include "tiny32.vh"

module main
#(parameter ROM_BITS = 8)
(
    input wire clk,
    output wire nhlt,
    output wire nerror,
    output wire nwfi,
`ifdef MEMORY_DEBUG
    output wire [31:0] address,
`endif
    output reg led = 1
);
    localparam MEMORY_SELECTOR_START_BIT = 27;

    reg nreset = 0;

    reg [`CPU_TIMER_BITS - 1:0] cpu_timer = 0;

`ifndef MEMORY_DEBUG
    wire [31:0] address;
`endif

    wire hlt, error, wfi;
    wire [7:0] interrupt_ack;
    wire [31:0] data_in, mem_rdata;
    reg [31:0] rom_rdata;
    wire [3:0] nwr;
    wire nrd;
    wire cpu_clk;
    wire rom_selected, ports_selected;
    wire [`STAGE_WIDTH - 1:0] stage;
    wire mem_clk;
    wire [ROM_BITS - 1:0] rom_address;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];

    assign nhlt = !hlt;
    assign nerror = !error;
    assign nwfi = !wfi;

    assign cpu_clk = cpu_timer[`CPU_CLOCK_BIT];
    assign rom_selected = address[31:MEMORY_SELECTOR_START_BIT] == 5'h01;
    assign ports_selected = address[31:MEMORY_SELECTOR_START_BIT] == 5'h1F;
    assign mem_rdata = rom_rdata;

    assign rom_address = address[ROM_BITS + 1:2];

    assign mem_clk = nrd & (nwr == 4'b1111);

    tiny32 #(.RESET_PC(32'h08000000), .ISR_ADDRESS(24'h080000))
            cpu(.clk(cpu_clk), .nrd(nrd), .nwr(nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(1'b1), .interrupt(8'h0), .interrupt_ack(interrupt_ack));

    initial begin
        $readmemh("asm/code.hex", rom);
    end

    always @(posedge clk) begin
        if (cpu_timer[`CPU_TIMER_BITS - 1])
            nreset <= 1;
        cpu_timer <= cpu_timer + 1;
    end

    always @(negedge mem_clk) begin
        if (rom_selected)
            rom_rdata <= rom[rom_address];
    end

    always @(negedge mem_clk) begin
        if (ports_selected) begin
            if (!nwr[0]) led <= data_in[0];
        end
    end

endmodule
