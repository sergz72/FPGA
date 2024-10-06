`include "main.vh"

`timescale 1 ns / 1 ps

module main
#(parameter
// 115200 at 27MHz
UART_CLOCK_DIV = 234,
UART_CLOCK_COUNTER_BITS = 8,
I2C_PORTS = 1,
// 3.375 interrupts/sec
TIMER_BITS = 23,
// about 20 ms delay
RESET_DELAY_BIT = 19,
// div = 64
CPU_CLOCK_BIT = 5,
// 1k 32 bit words RAM
RAM_BITS = 10,
// 8k 32 bit words ROM
ROM_BITS = 13)
(
    input wire clk,
    output wire nerror,
    output wire nwfi,
`ifdef MEMORY_DEBUG
    output wire [31:0] rom_addr,
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
    localparam MEMORY_SELECTOR_START_BIT = 27;

    reg reset = 0;
    reg [TIMER_BITS - 1:0] timer = 0;
    reg timer_interrupt = 0;
    reg timer_interrupt_clear = 0;

`ifndef NO_INOUT_PINS
    reg scl0 = 1;
    reg sda0 = 1;
    reg [I2C_PORTS - 1:0] scl = {I2C_PORTS{1'b1}},
    reg [I2C_PORTS - 1:0] sda = {I2C_PORTS{1'b1}},
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

    reg [31:0] rom_rdata, rodata_rdata, ram_rdata, ports_rdata;
    wire [31:0] mem_wdata, mem_addr, mem_rdata;
    wire [3:0] mem_wr_mask;
    wire [1:0] mem_size;
    wire wr;
    wire cpu_clk;
    wire rom_selected, rodata_selected, ram_selected, ports_selected;
    reg ram_selectedf, ports_selectedf, uart_control_selectedf, rodata_selectedf;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_nrd, uart_nwr;
    wire [7:0] uart_data_out;
 
    wire error, wfi;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign cpu_clk = timer[CPU_CLOCK_BIT];

    assign nerror = !error;
    assign nwfi = !wfi;
    
    assign rom_selected = iBus_cmd_valid & rom_addr[31:MEMORY_SELECTOR_START_BIT] === 0;
    assign rodata_selected = dBus_cmd_valid & rom_addr[31:MEMORY_SELECTOR_START_BIT] === 0;
    assign ram_selected = dBus_cmd_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 1;

    assign uart_data_selected = dBus_cmd_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 29;
    assign uart_control_selected = dBus_cmd_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 30;
    assign ports_selected = dBus_cmd_valid & mem_addr[31:MEMORY_SELECTOR_START_BIT] === 31;
    
    assign mem_rdata = ram_selectedf ? ram_rdata :
             (rodata_selectedf ? rodata_rdata :
                (ports_selectedf ? ports_rdata : 
                    (uart_control_selectedf ? {30'h0, uart_rx_fifo_empty, uart_tx_fifo_full} : {24'h0, uart_data_out})));

    assign uart_nrd = !(uart_data_selected & !wr);
    assign uart_nwr = !(uart_data_selected & wr);

    assign iBusError = iBus_cmd_valid & !rom_selected;
    assign dBusError = dBus_cmd_valid & !(rodata_selected | ram_selected | ports_selected | uart_control_selected | uart_data_selected);
    assign error = iBusError | dBusError;

`ifndef NO_INOUT_PINS
    assign scl0_io = scl0 ? 1'bz : 0;
    assign sda0_io = sda0 ? 1'bz : 0;

    genvar i;
    generate
        for (i = 0; i < I2C_PORTS; i = i + 1) begin
            assign sda_io[i] = sda[i] ? 1'bz : 0;
        end
    endgenerate
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
                .timerInterrupt(timer_interrupt),
                .externalInterrupt(1'h0),
                .softwareInterrupt(1'h0),
                .CsrPlugin_inWfi(wfi),
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

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(mem_wdata[7:0]), .data_out(data_out), .nwr(uart_nwr), .nrd(uart_nrd), .nreset(reset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty));

    // todo i2c_display, i2c_others, spi
    
    assign iBus_cmd_ready = 1'b1;
    assign dBus_cmd_ready = 1'b1;

    always @(posedge clk) begin
        if (timer == {TIMER_BITS{1'b1}})
            timer_interrupt <= 1;
            else if (timer_interrupt_clear)
                timer_interrupt <= 0;
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
        rodata_selectedf <= rodata_selected;
        if (rom_selected)
            rom_rdata <= rom[rom_addr[ROM_BITS + 1:2]];
        if (rodata_selected)
            rodata_rdata <= rom[mem_addr[ROM_BITS + 1:2]];
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
        ports_selectedf <= ports_selected;
        uart_control_selectedf <= uart_control_selected;
        if (ports_selected) begin
`ifndef NO_INOUT_PINS
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_io, sda0_io};
`else
            ports_rdata <= {25'b0, con_button, psh_button, tra, trb, bak_button, scl0_in, sda0_in};
`endif
            if (wr & mem_wr_mask[0]) {led, scl0, sda0} <= mem_wdata[2:0];
            if (wr & mem_wr_mask[1]) timer_interrupt_clear <= mem_wdata[8];
        end
    end

endmodule
