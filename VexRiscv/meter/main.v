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
    output wire error,
`ifdef MEMORY_DEBUG
    output wire [31:0] rom_addr,
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
    localparam RAM_END = RAM_START + (1<<RAM_BITS) - 1;
    localparam MEMORY_SELECTOR_START_BIT = 30;

    reg reset = 0;
    reg [TIMER_BITS - 1:0] timer = 0;
    reg interrupt = 0;

`ifndef NO_INOUT_PINS
    reg scl = 1;
    reg sda = 1;
`endif

`ifndef MEMORY_DEBUG
    wire [31:0] rom_addr;
`endif

    wire iBus_cmd_valid;
    reg iBus_rsp_valid = 0;
    wire iBus_cmd_ready;

    wire dBus_cmd_ready;
    wire dBusError, iBusError;
    wire dBus_cmd_valid;
    reg dBus_rsp_ready = 0;

    reg [31:0] rom_rdata, ram_rdata, ports_rdata;
    wire [31:0] mem_wdata, mem_addr, mem_rdata;
    wire [3:0] mem_wr_mask;
    wire [1:0] mem_size;
    wire wr;
    wire cpu_clk;
    wire rom_selected, ram_selected, ports_selected;
    reg ram_selectedf;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign cpu_clk = timer[CPU_CLOCK_BIT];
    assign rom_selected = iBus_cmd_valid & rom_addr[31:MEMORY_SELECTOR_START_BIT] === 0;
    assign ram_selected = dBus_cmd_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 1;
    assign ports_selected = dBus_cmd_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 3;
    assign mem_rdata = ram_selectedf ? ram_rdata : ports_rdata;

    assign iBusError = iBus_cmd_valid & !rom_selected;
    assign dBusError = dBus_cmd_valid & !(ram_selected | ports_selected);
    assign error = iBusError | dBusError;

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

    VexRiscv cpu(.clk(cpu_clk),
                .reset(!reset),
                .iBus_cmd_valid(iBus_cmd_valid),
                .iBus_cmd_ready(iBus_cmd_ready),
                .iBus_cmd_payload_pc(rom_addr),
                .iBus_rsp_valid(iBus_rsp_valid),
                .iBus_rsp_payload_error(iBusError),
                .iBus_rsp_payload_inst(rom_rdata),
                .timerInterrupt(interrupt),
                .externalInterrupt(1'h0),
                .softwareInterrupt(1'h0),
                .dBus_cmd_valid(dBus_cmd_valid),
                .dBus_cmd_ready(dBus_cmd_ready),
                .dBus_cmd_payload_wr(wr),
                .dBus_cmd_payload_mask(mem_wr_mask),
                .dBus_cmd_payload_address(mem_addr),
                .dBus_cmd_payload_data(mem_wdata),
                .dBus_cmd_payload_size(mem_size),
                .dBus_rsp_ready(dBus_rsp_ready),
                .dBus_rsp_error(dBusError),
                .dBus_rsp_data(mem_rdata)
    );

    assign iBus_cmd_ready = 1'b1;
    assign dBus_cmd_ready = 1'b1;

    always @(posedge clk) begin
/*        if (TIMER_INTERRUPT != 0) begin
            if (timer == {TIMER_BITS{1'b1}})
                interrupt <= 1;
            else if (eoi[0])
                interrupt <= 0;
        end*/
        timer <= timer + 1;
    end

    always @(negedge timer[RESET_DELAY_BIT]) begin
        reset <= 1;
    end

    always @(posedge cpu_clk) begin
        if (!reset)
            dBus_rsp_ready  <= 1'b0;
        else
            dBus_rsp_ready <= (ram_selected | ports_selected) & !wr;
    end

    always @(posedge cpu_clk) begin
        iBus_rsp_valid  <= rom_selected;
        if (rom_selected)
            rom_rdata <= rom[rom_addr[ROM_BITS + 1:2]];
    end

    always @(posedge cpu_clk) begin
        ram_selectedf <= ram_selected;
        if (ram_selected) begin
            if (wr & mem_wr_mask[0]) ram1[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[ 7: 0];
            if (wr & mem_wr_mask[1]) ram2[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[15: 8];
            if (wr & mem_wr_mask[2]) ram3[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[23:16];
            if (wr & mem_wr_mask[3]) ram4[mem_addr[RAM_BITS + 1:2]] <= mem_wdata[31:24];
            ram_rdata <= {ram4[mem_addr[RAM_BITS + 1:2]], ram3[mem_addr[RAM_BITS + 1:2]], ram2[mem_addr[RAM_BITS + 1:2]], ram1[mem_addr[RAM_BITS + 1:2]]};
        end
    end

    always @(posedge cpu_clk) begin
        if (ports_selected) begin
`ifndef NO_INOUT_PINS
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_io, sda_io};
`else
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl_in, sda_in};
`endif
            if (wr & mem_wr_mask[0]) {led, scl, sda} <= mem_wdata[2:0];
        end
    end

endmodule
