module tiny16_tb;
    wire [15:0] address;
    wire hlt, error, rd, wr;
    wire [6:0] stage;
    reg [15:0] data_out;
    wire [15:0] data_in;
    reg clk, reset, ready;
    wire mem_clk;

    reg [15:0] ram [0:65535];

    initial begin
        $display("Loading program...");
        $readmemh("asm/a.out", ram);
    end

    tiny16 cpu(.clk(clk), .rd(rd), .wr(wr), .reset(reset), .address(address), .data_in(data_out), .data_out(data_in), .stage(stage),
                 .error(error), .hlt(hlt), .ready(ready));

    always #5 clk <= ~clk;
    
    assign mem_clk = rd & wr;

    initial begin
        $dumpfile("tiny16_tb.vcd");
        $dumpvars(0, tiny16_tb);
        $monitor("time=%t clk=%d stage=0x%x reset=%d rd=%d wr=%d hlt=%d error=%d address=%x, data_in=0x%x data_out=0x%x",
                 $time, clk, stage, reset, rd, wr, hlt, error, address, data_in, data_out);
        clk = 0;
        reset = 0;
        ready = 1;
        #20
        reset = 1;
        #10000
        $finish;
    end

    always @(negedge mem_clk) begin
        if (wr == 0)
            ram[address] <= data_in;
        else
            data_out <= ram[address];
    end
endmodule
