`timescale 1 ns / 1 ps

module main
#(parameter
RESET_BIT = 19,
MHZ_TIMER_BITS = 6,
MHZ_TIMER_VALUE = 27,
// 2k 32 bit words RAM
RAM_BITS = 11,
// 8k 32 bit words ROM
ROM_BITS = 13)
(
    input wire clk,
    output wire nerror,
    output wire nwfi,
    output reg led = 1
);
    localparam MEMORY_SELECTOR_START_BIT = 28;

    wire iBus_cmd_valid;
    reg iBus_rsp_valid = 0;

    wire dBusError, iBusError, dBusDeviceSelected;
    wire dBus_cmd_valid;
    reg dBus_rsp_ready = 0;

    reg [31:0] rom_rdata, ram_rdata, rodata_rdata;
    wire [31:0] mem_wdata, mem_addr, mem_rdata;
    wire [RAM_BITS - 1:0] ram_address;
    wire [31:0] rom_addr;
    wire [3:0] mem_wr_mask;
    wire [1:0] mem_size;
    wire wr;
    wire rom_selected, rodata_selected, ram_selected, port_selected, timer_selected;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire timer_req, timer_ack;

    wire error, wfi;

    wire timer_interrupt;
    reg timer_interrupt_clear = 0;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    reg [RESET_BIT:0] timer = 0;
    reg nreset = 0;

    assign ram_address = mem_addr[RAM_BITS + 1:2];
    assign memory_selector = mem_addr[31:MEMORY_SELECTOR_START_BIT];

    assign nerror = !error;
    assign nwfi = !wfi;
    
    assign rom_selected = rom_addr[31:MEMORY_SELECTOR_START_BIT] == 1;
    assign rodata_selected = memory_selector == 1;
    assign ram_selected = memory_selector == 2;
    assign port_selected = memory_selector == 3;
    assign timer_selected = memory_selector == 4;
    
    assign timer_req = dBus_cmd_valid & timer_selected & wr;

    assign iBusError = iBus_cmd_valid & !rom_selected;
    assign dBusDeviceSelected = rodata_selected | ram_selected | port_selected | timer_selected;
    assign dBusError = dBus_cmd_valid & !dBusDeviceSelected;
    assign error = iBusError | dBusError;

    assign mem_rdata = rodata_selected ? rodata_rdata : ram_rdata;

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    VexRiscv cpu(.clk(clk),
                .reset(!nreset),
                .iBus_cmd_valid(iBus_cmd_valid),
                .iBus_cmd_ready(1'b1),
                .iBus_cmd_payload_pc(rom_addr),
                .iBus_rsp_valid(iBus_rsp_valid),
                .iBus_rsp_payload_error(iBusError),
                .iBus_rsp_payload_inst(rom_rdata),
                .timerInterrupt(timer_interrupt),
                .externalInterrupt(1'b0),
                .softwareInterrupt(1'b0),
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

    timer #(.MHZ_TIMER_BITS(MHZ_TIMER_BITS), .MHZ_TIMER_VALUE(MHZ_TIMER_VALUE))
        t(.clk(clk), .nreset(nreset), .req(timer_req), .ack(timer_ack), .value(mem_wdata), .interrupt(timer_interrupt), .interrupt_clear(timer_interrupt_clear));

    always @(posedge clk) begin
        if (timer[RESET_BIT])
            nreset <= 1;
        timer <= timer + 1;
    end

    always @(posedge clk) begin
        iBus_rsp_valid  <= iBus_cmd_valid & rom_selected;
        dBus_rsp_ready <= dBus_cmd_valid & (rodata_selected | timer_ack | ram_selected | port_selected);
        rom_rdata <= rom[rom_addr[ROM_BITS + 1:2]];
        rodata_rdata <= rom[mem_addr[ROM_BITS + 1:2]];
    end

    always @(posedge clk) begin
        if (dBus_cmd_valid & ram_selected) begin
            if (wr & mem_wr_mask[0]) ram1[ram_address] <= mem_wdata[ 7: 0];
            if (wr & mem_wr_mask[1]) ram2[ram_address] <= mem_wdata[15: 8];
            if (wr & mem_wr_mask[2]) ram3[ram_address] <= mem_wdata[23:16];
            if (wr & mem_wr_mask[3]) ram4[ram_address] <= mem_wdata[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
    end

    always @(posedge clk) begin
        if (dBus_cmd_valid & port_selected & wr) begin
            if (mem_wr_mask[0]) led <= mem_wdata[0];
            if (mem_wr_mask[1]) timer_interrupt_clear <= mem_wdata[8];
        end
    end

endmodule
