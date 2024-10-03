module tiny32_tb;
    localparam ROM_BITS = 10;
    localparam RAM_BITS = 10;

    wire [31:0] address;
    wire hlt, error, wfi, nrd;
    wire [3:0] nwr;
    wire [1:0] stage;
    wire [31:0] data_in;
    reg [7:0] interrupt;
    reg clk, nreset, ready;
    wire mem_clk;
    wire [RAM_BITS - 1:0] ram_address;
    wire [ROM_BITS - 1:0] rom_address;
    wire rom_selected, ram_selected;
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

    tiny32 cpu(.clk(clk), .nrd(nrd), .nwr(nwr), .wfi(wfi), .nreset(nreset), .address(address), .data_in(mem_rdata), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(ready), .interrupt(interrupt));

    always #1 clk <= ~clk;
    
    assign mem_clk = nrd & (nwr === 4'b1111);
    assign ram_address = address[RAM_BITS + 1:2];
    assign rom_address = address[ROM_BITS + 1:2];
    assign rom_selected = address[31:30] == 0;
    assign ram_selected = address[31:30] == 1;
    assign mem_rdata = rom_selected ? rom_rdata : ram_rdata;

    initial begin
        $dumpfile("tiny32_tb.vcd");
        $dumpvars(0, tiny32_tb);
        $monitor("time=%t clk=%d stage=0x%x nreset=%d nrd=%d nwr=0x%x hlt=%d error=%d wfi=%d address=0x%x, data_in=0x%x mem_rdata=0x%x",
                 $time, clk, stage, nreset, nrd, nwr, hlt, error, wfi, address, data_in, mem_rdata);
        clk = 0;
        nreset = 0;
        ready = 1;
        interrupt = 0;
        #20
        nreset = 1;
        #10000
        $finish;
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
        if (rom_selected)
            rom_rdata <= rom[rom_address];
    end

endmodule
