module main
#(parameter ROM_BITS = 8, RAM_BITS = 8, WIDTH = 16)
(
    input wire clk,
    input wire nreset,
    output wire error,
    output wire hlt,
    output wire wfi,
    wire [WIDTH - 1:0] mem_address
);
    wire [WIDTH - 1:0] mem_data_in, mem_data_out;
    reg [WIDTH - 1:0] ram_rdata;
    wire mem_valid, mem_nwr;

    reg mem_ready = 0;
    wire [RAM_BITS - 1:0] ram_address;

    wire [1:0] interrupt, interrupt_ack;

    reg [WIDTH - 1:0] ram [0:(1<<RAM_BITS)-1];

    forth_cpu #(.ROM_BITS(ROM_BITS), .WIDTH(WIDTH))
              cpu(.clk(clk), .error(error), .hlt(hlt), .wfi(wfi), .nreset(nreset), .mem_address(mem_address), .mem_nwr(mem_nwr),
                  .mem_data_in(mem_data_out), .mem_data_out(mem_data_in), .mem_valid(mem_valid), .mem_ready(mem_ready),
                  .interrupt(interrupt), .interrupt_ack(interrupt_ack));

    assign interrupt = 0;

    assign ram_address = mem_address[RAM_BITS-1:0];

    assign mem_data_out = ram_rdata;

    always @(posedge clk) begin
        if (mem_valid & !mem_ready) begin
            if (!mem_nwr)
                ram[ram_address] <= mem_data_in;
            ram_rdata <= ram[ram_address];
        end
        mem_ready <= nreset & mem_valid;
    end
endmodule