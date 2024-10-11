module main
#(parameter ROM_BITS = 4, RESET_BIT = 3, TIMER_BIT = 23, COUNTER_BITS = 24)
(
    input wire clk,
    output wire nhlt,
    output wire nwfi,
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
    reg interrupt = 0;
    wire in_interrupt;
    wire wfi;

    reg [15:0] rom [0:(1<<ROM_BITS)-1];

    initial begin
        $readmemh("asm/a.out", rom);
    end

    tiny16 cpu(.clk(clk), .rd(nrd), .wr(nwr), .reset(nreset), .address(address), .data_in(data_out), .data_out(data_in), .stage(stage),
               .hlt(hlt), .interrupt(interrupt), .in_interrupt(in_interrupt), .wfi(wfi));

    assign nhlt = !hlt;
    assign nwfi = !wfi;
    assign data_out = rom_rdata;
    assign rom_address = address[ROM_BITS-1:0];
    assign rom_selected = address[15:14] == 0;
    assign port_selected = address[15:14] == 3;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    always @(negedge clk) begin
        if (counter[RESET_BIT])
            nreset <= 1;
    end

    always @(negedge clk) begin
        if (in_interrupt)
            interrupt <= 0;
        else if (counter[TIMER_BIT:0] == 0)
            interrupt <= 1;
    end

    always @(posedge clk) begin
        if (!nwr & port_selected)
            led <= data_in[0];
    end

    always @(negedge clk) begin
        if (rom_selected)
            rom_rdata <= rom[rom_address];
    end
endmodule