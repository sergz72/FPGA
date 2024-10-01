module tiny32_tb;
    wire [31:0] address;
    wire hlt, error, wfi, rd;
    wire [3:0] wr;
    wire [1:0] stage;
    wire [3:0] substage;
    reg [31:0] data_out;
    wire [31:0] data_in;
    reg [7:0] interrupt;
    reg clk, reset, ready;
    wire mem_clk;

    reg [31:0] rom [0:1023];
    reg [7:0] ram1 [0:1023];
    reg [7:0] ram2 [0:1023];
    reg [7:0] ram3 [0:1023];
    reg [7:0] ram4 [0:1023];

    initial begin
        $display("Loading program...");
        $readmemh("asm/code.hex", rom);
        $readmemh("asm/data1.hex", ram1);
        $readmemh("asm/data2.hex", ram2);
        $readmemh("asm/data3.hex", ram3);
        $readmemh("asm/data4.hex", ram4);
    end

    tiny32 cpu(.clk(clk), .rd(rd), .wr(wr), .wfi(wfi), .reset(reset), .address(address), .data_in(data_out), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(ready), .interrupt(interrupt), .substage(substage));

    always #1 clk <= ~clk;
    
    assign mem_clk = rd & (wr === 4'b1111);

    initial begin
        $dumpfile("tiny32_tb.vcd");
        $dumpvars(0, tiny32_tb);
        $monitor("time=%t clk=%d substage=0x%x, stage=0x%x reset=%d rd=%d wr=0x%x hlt=%d error=%d wfi=%d address=0x%x, data_in=0x%x data_out=0x%x",
                 $time, clk, substage, stage, reset, rd, wr, hlt, error, wfi, address, data_in, data_out);
        clk = 0;
        reset = 0;
        ready = 1;
        interrupt = 0;
        #20
        reset = 1;
        #10000
        $finish;
    end

    always @(negedge mem_clk) begin
        if (!wr[0])
            ram1[address] <= data_in[7:0];
        if (!wr[1])
            ram2[address] <= data_in[15:8];
        if (!wr[2])
            ram3[address] <= data_in[23:16];
        if (!wr[3])
            ram4[address] <= data_in[31:24];
        data_out <= {ram4[address], ram3[address], ram2[address], ram1[address]};
    end
endmodule
