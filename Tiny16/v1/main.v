module main
#(parameter ROM_BITS = 4, CPU_CLOCK_BIT = 18, RESET_BIT = 21, COUNTER_BITS = 22)
(
    input wire clk,
    output wire nhlt,
    output reg led = 1
);
    wire [15:0] address;
    wire nrd, nwr, hlt;
    wire [3:0] stage;
    wire [15:0] data_out;
    wire [15:0] data_in;
    reg [15:0] rom_rdata;
    wire rom_selected, port_selected;
    wire [ROM_BITS-1:0] rom_address;
    reg nreset = 0;
    reg [COUNTER_BITS - 1:0] counter = 0;
//    wire mem_clk;

    reg [15:0] rom [0:(1<<ROM_BITS)-1];

    initial begin
        $readmemh("asm/a.out", rom);
    end

    tiny16 cpu(.clk(counter[CPU_CLOCK_BIT]), .rd(nrd), .wr(nwr), .reset(nreset), .address(address), .data_in(data_out), .data_out(data_in), .stage(stage),
                 .hlt(hlt));

//    assign mem_clk = rd & wr;
    assign nhlt = !hlt;
    assign data_out = rom_rdata;
    assign rom_address = address[ROM_BITS-1:0];
    assign rom_selected = address[15:14] == 0;
    assign port_selected = address[15:14] == 3;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    always @(posedge counter[RESET_BIT]) begin
        nreset <= 1;
    end

    always @(negedge nwr) begin
        if (port_selected)
            led <= data_in[0];
    end

    always @(negedge nrd) begin
        if (rom_selected)
            rom_rdata <= rom[rom_address];
    end
endmodule
