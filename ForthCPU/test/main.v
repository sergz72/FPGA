`include "main.vh"

module main
#(parameter ROM_BITS = 8, RAM_BITS = 8)
(
    input wire clk,
    output wire nerror,
    output wire nhlt,
    output wire nwfi,
    output reg led = 1,
    input wire rx,
    output wire tx
);
    localparam MEMORY_SELECTOR_START_BIT = 13;

    wire error, hlt, wfi;
    wire [15:0] mem_address, mem_data_in, mem_data_out, uart_rdata;
    reg [15:0] ram_rdata;
    wire cpu_clk;
    wire mem_valid, mem_nwr;
    wire ram_selected, ports_selected, uart_selected;

    reg mem_ready = 0;
    wire [RAM_BITS - 1:0] ram_address;
    wire [15-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire [1:0] interrupt, interrupt_ack;

    wire [7:0] uart_data;
    wire uart_send, uart_busy, uart_interrupt;

    reg timer_interrupt = 0;

    reg nreset = 0;

    reg [`CPU_TIMER_BITS - 1:0] cpu_timer = 0;

    reg [15:0] ram [0:(1<<RAM_BITS)-1];

    forth_cpu #(.ROM_BITS(ROM_BITS))
              cpu(.clk(cpu_clk), .error(error), .hlt(hlt), .wfi(wfi), .nreset(nreset), .mem_address(mem_address), .mem_nwr(mem_nwr),
                  .mem_data_in(mem_data_out), .mem_data_out(mem_data_in), .mem_valid(mem_valid), .mem_ready(mem_ready),
                  .interrupt(interrupt), .interrupt_ack(interrupt_ack));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(tx), .data(mem_data_in[7:0]), .send(uart_send), .busy(uart_busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(rx), .data(uart_data), .interrupt(uart_interrupt), .interrupt_clear(interrupt_ack[1]), .nreset(nreset));

    assign interrupt = {uart_interrupt, timer_interrupt};

    assign memory_selector = mem_address[15:MEMORY_SELECTOR_START_BIT];
    assign cpu_clk = cpu_timer[`CPU_CLOCK_BIT];
    assign nerror = !error;
    assign nhlt = !hlt;
    assign nwfi = !wfi;
    assign ram_address = mem_address[RAM_BITS-1:0];

    assign ram_selected = memory_selector == 0;
    assign uart_selected = memory_selector == 6;
    assign ports_selected = memory_selector == 7;

    assign uart_rdata = {7'h0, uart_busy, uart_data};

    assign mem_data_out = ram_selected ? ram_rdata : uart_rdata;

    assign uart_send = nreset & mem_valid & mem_ready & uart_selected & !mem_nwr;

    initial begin
        $readmemh("asm/data.hex", ram);
    end

    always @(posedge clk) begin
        if (interrupt_ack[0])
            timer_interrupt <= 0;
        else if (cpu_timer == {`CPU_TIMER_BITS{1'b1}})
            timer_interrupt <= 1;
        if (cpu_timer[`RESET_BIT - 1])
            nreset <= 1;
        cpu_timer <= cpu_timer + 1;
    end

    always @(posedge cpu_clk) begin
        if (mem_valid & !mem_ready) begin
            case (1'b1)
                ram_selected: begin
                    if (!mem_nwr)
                        ram[ram_address] <= mem_data_in;
                    ram_rdata <= ram[ram_address];
                end
                ports_selected: begin
                    if (!mem_nwr)
                        led <= mem_data_in[0];
                end
            endcase
        end
        mem_ready <= nreset & mem_valid;
    end
endmodule
