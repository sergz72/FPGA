`include "main.vh"

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
`ifndef NO_INOUT_PINS
    inout wire scl_io,
    inout wire sda_io,
`else
    input wire scl_in,
    input wire sda_in,
    output reg scl = 1,
    output reg sda = 1,
`endif
`ifdef INTEL
    output reg nreset = 0,
    input wire reset_in,
`endif
    input wire con_button,
    input wire psh_button,
    input wire tra, // encoder
    input wire trb, // encoder
    input wire bak_button,
    output reg led = 1
);
    localparam MEMORY_SELECTOR_START_BIT = 30;

`ifndef INTEL
    reg nreset = 0;
    wire reset_in;

    assign reset_in = nreset;
`endif

    reg [TIMER_BITS - 1:0] timer = 0;
    reg interrupt = 0;

`ifndef NO_INOUT_PINS
    reg scl = 1;
    reg sda = 1;
`endif

`ifndef MEMORY_DEBUG
    wire [31:0] address;
`endif

    wire [7:0] irq;
    wire [31:0] data_in, mem_rdata;
    reg [31:0] rom_rdata, ram_rdata, ports_rdata;
    wire [3:0] nwr;
    wire nrd;
    reg ready = 1;
    wire cpu_clk;
    wire rom_selected, ram_selected, ports_selected;
    wire [1:0] stage;
    wire mem_clk;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign irq = {7'h0, interrupt};

    assign cpu_clk = timer[CPU_CLOCK_BIT];
    assign rom_selected = address[31:MEMORY_SELECTOR_START_BIT] === 0;
    assign ram_selected = address[31:MEMORY_SELECTOR_START_BIT] === 1;
    assign ports_selected = address[31:MEMORY_SELECTOR_START_BIT] === 3;
    assign mem_rdata = rom_selected ? rom_rdata : (ram_selected ? ram_rdata : ports_rdata);

    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];

    assign mem_clk = nrd & (nwr === 4'b1111);

`ifndef NO_INOUT_PINS
    assign scl_io = scl ? 1'bz : 0;
    assign sda_io = sda ? 1'bz : 0;
`endif

    tiny32 cpu(.clk(cpu_clk), .nrd(nrd), .nwr(nwr), .wfi(wfi), .nreset(reset_in), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(ready), .interrupt(irq));

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    always @(posedge clk) begin
        if (timer == {TIMER_BITS{1'b1}})
            interrupt <= 1;
        else if (interrupt & !wfi)
            interrupt <= 0;
        timer <= timer + 1;
    end

    always @(negedge timer[RESET_DELAY_BIT]) begin
        nreset <= 1;
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
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_io, sda_io};
`else
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_in, sda_in};
`endif
            if (!nwr[0]) {led, scl, sda} <= data_in[2:0];
        end
    end

endmodule
