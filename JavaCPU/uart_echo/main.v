`include "main.vh"

module main
#(parameter ROM_BITS = 9, RAM_BITS = 9, RODATA_BITS = 9, HEAP_BITS = 9)
(
    input wire clk,
    output wire nerror,
    output wire nhlt,
    output wire nwfi,
    output reg led = 1,
    input wire rx,
    output wire tx
);
    localparam MEMORY_SELECTOR_START_BIT = 29;

    wire [31:0] mem_data_in, mem_data_out, mem_address, uart_rdata;
    reg [31:0] ram_rdata, rodata_rdata, heap_rdata;
    wire mem_valid, mem_nwr;

    reg mem_ready = 0;
    wire [RAM_BITS - 1:0] ram_address;
    wire [RODATA_BITS - 1:0] rodata_address;
    wire [HEAP_BITS - 1:0] heap_address;
    wire [31-MEMORY_SELECTOR_START_BIT:0] memory_selector;
    wire ram_selected, rodata_selected, port_selected, timer_selected, uart_selected, heap_selected;

    wire hlt, wfi, error;

    wire [1:0] interrupt, interrupt_ack;

    wire timer_interrupt, timer_nwr;

    wire [7:0] uart_data;
    wire uart_send, uart_busy, uart_interrupt;

    reg [31:0] ram [0:(1<<RAM_BITS)-1];
    reg [31:0] rodata [0:(1<<RODATA_BITS)-1];
    reg [31:0] heap [0:(1<<HEAP_BITS)-1];

    reg nreset = 0;
    wire cpu_clk;

    reg [`RESET_BIT:0] reset_timer = 0;

    java_cpu #(.ROM_BITS(ROM_BITS))
              cpu(.clk(cpu_clk), .error(error), .hlt(hlt), .wfi(wfi), .nreset(nreset), .mem_address(mem_address), .mem_nwr(mem_nwr),
                  .mem_data_in(mem_data_out), .mem_data_out(mem_data_in), .mem_valid(mem_valid), .mem_ready(mem_ready),
                  .interrupt(interrupt), .interrupt_ack(interrupt_ack));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(tx), .data(mem_data_in[7:0]), .send(uart_send), .busy(uart_busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(rx), .data(uart_data), .interrupt(uart_interrupt), .interrupt_clear(interrupt_ack[1]), .nreset(nreset));

    timer #(.MHZ_TIMER_BITS(`MHZ_TIMER_BITS), .MHZ_TIMER_VALUE(`MHZ_TIMER_VALUE))
        t(.clk(clk), .nreset(nreset), .nwr(timer_nwr), .value(mem_data_in), .interrupt(timer_interrupt), .interrupt_clear(interrupt_ack[0]));

    assign interrupt = {uart_interrupt, timer_interrupt};

    assign memory_selector = mem_address[31:MEMORY_SELECTOR_START_BIT];
    assign ram_address = mem_address[RAM_BITS-1:0];
    assign rodata_address = mem_address[RODATA_BITS-1:0];
    assign heap_address = mem_address[HEAP_BITS-1:0];
    assign nerror = !error;
    assign nhlt = !hlt;
    assign nwfi = !wfi;
    assign cpu_clk = reset_timer[`CPU_CLOCK_BIT];

    assign ram_selected = memory_selector == 1;
    assign rodata_selected = memory_selector == 2;
    assign heap_selected = memory_selector == 3;
    assign uart_selected = mem_address == 32'hFFFFFFFD;
    assign timer_selected = mem_address == 32'hFFFFFFFE;
    assign port_selected = mem_address == 32'hFFFFFFFF;

    assign uart_rdata = {23'h0, uart_busy, uart_data};
    assign uart_send = nreset & mem_valid & mem_ready & uart_selected & !mem_nwr;

    assign mem_data_out = mem_rdata_f(memory_selector);;

    assign timer_nwr = !(nreset & mem_valid & mem_ready & timer_selected & !mem_nwr);

    function [31:0] mem_rdata_f(input [31-MEMORY_SELECTOR_START_BIT:0] source);
        case (source)
            1: mem_rdata_f = ram_rdata;
            2: mem_rdata_f = rodata_rdata;
            3: mem_rdata_f = heap_rdata;
            default: mem_rdata_f = uart_rdata;
        endcase
    endfunction

    initial begin
        $readmemh("asm/rodata.hex", rodata);
    end

    always @(posedge clk) begin
        if (reset_timer[`RESET_BIT])
            nreset <= 1;
        reset_timer <= reset_timer + 1;
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & ram_selected) begin
            if (!mem_nwr)
                ram[ram_address] <= mem_data_in;
            ram_rdata <= ram[ram_address];
        end
        mem_ready <= nreset & mem_valid & (ram_selected | rodata_selected | heap_selected | port_selected | timer_selected | uart_selected);
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & heap_selected) begin
            if (!mem_nwr)
                heap[heap_address] <= mem_data_in;
            heap_rdata <= heap[heap_address];
        end
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & rodata_selected) begin
            rodata_rdata <= rodata[rodata_address];
        end
    end

    always @(negedge cpu_clk) begin
        if (mem_valid & port_selected & !mem_nwr)
            led <= mem_data_in[0];
    end
endmodule
