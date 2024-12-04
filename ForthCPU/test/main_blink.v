`include "main_blink.vh"

module main
#(parameter ROM_BITS = 8, RAM_BITS = 8)
(
    input wire clk,
    output wire nerror,
    output wire nhlt,
    output wire nwfi,
    output reg led = 1
);
    localparam MEMORY_SELECTOR_START_BIT = 13;

    wire error, hlt, wfi;
    wire [15:0] mem_address, mem_data_in, mem_data_out;
    reg [15:0] ram_rdata;
    wire cpu_clk;
    wire mem_valid, mem_nwr;
    wire ram_selected, ports_selected;

    reg mem_ready = 0;
    wire [RAM_BITS - 1:0] ram_address;
    wire [15-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire [1:0] interrupt, interrupt_ack;

    reg nreset = 0;

    reg [`CPU_TIMER_BITS - 1:0] cpu_timer = 0;

    reg [15:0] ram [0:(1<<RAM_BITS)-1];

    forth_cpu #(.ROM_BITS(ROM_BITS))
              cpu(.clk(cpu_clk), .error(error), .hlt(hlt), .wfi(wfi), .nreset(nreset), .mem_address(mem_address), .mem_nwr(mem_nwr),
                  .mem_data_in(mem_data_out), .mem_data_out(mem_data_in), .mem_valid(mem_valid), .mem_ready(mem_ready),
                  .interrupt(interrupt), .interrupt_ack(interrupt_ack));


    assign interrupt = 0;

    assign memory_selector = mem_address[15:MEMORY_SELECTOR_START_BIT];
    assign cpu_clk = cpu_timer[`CPU_CLOCK_BIT];
    assign nerror = !error;
    assign nhlt = !hlt;
    assign nwfi = !wfi;
    assign ram_address = mem_address[RAM_BITS-1:0];

    assign ram_selected = memory_selector == 0;
    assign ports_selected = memory_selector == 7;

    assign mem_data_out = ram_rdata;

    always @(posedge clk) begin
        if (cpu_timer[`CPU_TIMER_BITS -1])
            nreset <= 1;
        cpu_timer <= cpu_timer + 1;
    end

    always @(negedge cpu_clk) begin
        if (mem_valid) begin
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
