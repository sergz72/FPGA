`include "main.vh"
`include "tiny32.vh"

module main
#(parameter ROM_BITS = 8, RAM_BITS = 8)
(
    input wire clk,
    output wire nhlt,
    output wire nerror,
    output wire nwfi,
`ifdef MEMORY_DEBUG
    output wire [31:0] address,
`endif
    output reg led = 1,
    output wire tx,
    input wire rx
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
    reg [31:0] rom_rdata, ram_rdata;
    wire [3:0] nwr;
    wire nrd;
    wire cpu_clk, mem_clk;
    wire rom_selected, ram_selected, ports_selected, uart_data_selected, timer_selected;
    wire [`STAGE_WIDTH - 1:0] stage;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire [31:0] uart_rdata;
    wire [7:0] uart_data;
    wire uart_send, uart_busy;
    wire uart_interrupt;

    wire timer_interrupt, timer_nwr;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [7:0] ram1 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram2 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram3 [0:(1<<RAM_BITS)-1];
    reg [7:0] ram4 [0:(1<<RAM_BITS)-1];

    assign memory_selector = address[31:MEMORY_SELECTOR_START_BIT];

    assign nhlt = !hlt;
    assign nerror = !error;
    assign nwfi = !wfi;

    assign cpu_clk = cpu_timer[`CPU_CLOCK_BIT];
    assign rom_selected = memory_selector == 5'h01;
    assign ram_selected = memory_selector == 5'h02;
    assign timer_selected = memory_selector == 5'h1D;
    assign uart_data_selected = memory_selector == 5'h1E;
    assign ports_selected = memory_selector == 5'h1F;

    assign mem_rdata = rom_selected ? rom_rdata : (ram_selected ? ram_rdata : uart_rdata);

    assign timer_nwr = !timer_selected | (nwr == 4'b1111);

    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];

    assign mem_clk = nrd & (nwr == 4'b1111);

    assign uart_send = uart_data_selected & !nwr[0];

    assign uart_rdata = {23'h0, uart_busy, uart_data};

    tiny32 #(.RESET_PC(32'h08000000), .ISR_ADDRESS(24'h080000))
            cpu(.clk(cpu_clk), .nrd(nrd), .nwr(nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(1'b1), .interrupt({6'h0, uart_interrupt, timer_interrupt}), .interrupt_ack(interrupt_ack));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(tx), .data(data_in[7:0]), .send(uart_send), .busy(uart_busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(rx), .data(uart_data), .interrupt(uart_interrupt), .interrupt_clear(interrupt_ack[1]), .nreset(nreset));

    timer #(.MHZ_TIMER_BITS(`MHZ_TIMER_BITS), .MHZ_TIMER_VALUE(`MHZ_TIMER_VALUE))
        t(.clk(clk), .nreset(nreset), .nwr(timer_nwr), .value(data_in), .interrupt(timer_interrupt), .interrupt_clear(interrupt_ack[0]));

    initial begin
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
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
        if (ports_selected)
            if (!nwr[0]) led <= data_in[0];
    end

endmodule
