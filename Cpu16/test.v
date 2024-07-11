module cpu16_tb;
    wire [15:0] address;
    wire hlt, io_rd, io_wr, error;
    wire [15:0] io_data, io_address;
    reg [31:0] data;
    reg clk, reset;

    reg [31:0] rom [0:1023];

    initial begin
        $display("Loading rom.");
        $readmemh("asm/a.out", rom);
        $display(rom[0]);
    end

    cpu cpu16(.clk(clk), .reset(reset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd),
                 .io_wr(io_wr), .io_data(io_data), .io_address(io_address), .error(error));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu16_tb.vcd");
        $dumpvars(0, cpu16_tb);
        $monitor("time=%t reset=%d hlt=%d error=%d address=%x, data=0x%x io_rd=%d io_wr=%d io_data=%x io_address=%x",
                 $time, reset, hlt, error, address, data, io_rd, io_wr, io_data, io_address);
        clk = 0;
        reset = 0;
        #10
        reset = 1;
        #1000
        $finish;
    end

    always @(negedge clk) begin
        data <= rom[address[9:0]];
    end

endmodule
