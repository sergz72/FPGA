`include "tiny32.vh"

module tiny32_tb;
    localparam ROM_BITS = 11;
    localparam RAM_BITS = 10;

    wire [31:0] address;
    wire hlt, error, wfi, mem_valid;
    wire [3:0] mem_nwr;
    wire [`STAGE_WIDTH - 1:0] stage;
    wire [31:0] data_in;
    reg [7:0] interrupt, interrupt_ack;
    reg clk, nreset, mem_ready;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;
    wire rom_selected, ram_selected, uart_selected;
    reg [31:0] ram_rdata, rom_rdata;
    wire [31:0] mem_rdata;

    reg [31:0] rom [0:(1<<ROM_BITS) - 1];
    reg [7:0] ram1 [0:(1<<RAM_BITS) - 1];
    reg [7:0] ram2 [0:(1<<RAM_BITS) - 1];
    reg [7:0] ram3 [0:(1<<RAM_BITS) - 1];
    reg [7:0] ram4 [0:(1<<RAM_BITS) - 1];

    initial begin
        $display("Loading program...");
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    tiny32 cpu(.clk(clk), .mem_valid(mem_valid), .mem_nwr(mem_nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .mem_ready(mem_ready), .interrupt(interrupt), .interrupt_ack(interrupt_ack));

    always #1 clk <= ~clk;
    
    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];
    assign rom_selected  = address[31:28] == 0;
    assign uart_selected = address[31:28] == 1;
    assign ram_selected  = address[31:28] == 4;
    assign mem_rdata = rom_selected ? rom_rdata : ram_rdata;

    integer i;
    initial begin
        $dumpfile("tiny32_tb.vcd");
        $dumpvars(0, tiny32_tb);
        $monitor("time=%t clk=%d stage=0x%x nreset=%d mem_valid=%d mem_ready=%d mem_nwr=0x%x hlt=%d error=%d wfi=%d address=0x%x, data_in=0x%x mem_rdata=0x%x",
                 $time, clk, stage, nreset, mem_valid, mem_ready, mem_nwr, hlt, error, wfi, address, data_in, mem_rdata);
        clk = 0;
        nreset = 0;
        mem_ready = 0;
        interrupt = 0;
        #20
        nreset = 1;
        for (i = 0; i < 1000; i = i + 1) begin
            #100
            if (hlt | error)
              $finish;
        end
        $finish;
    end

    always @(negedge clk) begin
        if (mem_valid & ram_selected) begin
            if (!mem_nwr[0])
                ram1[ram_address] <= data_in[7:0];
            if (!mem_nwr[1])
                ram2[ram_address] <= data_in[15:8];
            if (!mem_nwr[2])
                ram3[ram_address] <= data_in[23:16];
            if (!mem_nwr[3])
                ram4[ram_address] <= data_in[31:24];
            ram_rdata <= {ram4[ram_address], ram3[ram_address], ram2[ram_address], ram1[ram_address]};
        end
        mem_ready <= mem_valid & (rom_selected | ram_selected | uart_selected);
    end

    always @(negedge clk) begin
        if (mem_valid & rom_selected)
            rom_rdata <= rom[rom_address];
    end

endmodule
