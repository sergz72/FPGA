module cpu16_tb;
    wire [15:0] address;
    wire rd, hlt, io_rd, io_wr, error;
    wire [15:0] io_data, io_address;
    reg [31:0] data;
    reg clk, reset;

    reg [31:0] rom [0:15];

    initial begin
        $display("Loading rom.");
        $readmemh("asm/a.out", rom);
        $display(rom[0]);
    end

    cpu cpu16(.clk(clk), .reset(reset), .address(address), .data(data), .rd(rd), .hlt(hlt), .io_rd(io_rd),
                 .io_wr(io_wr), .io_data(io_data), .io_address(io_address), .error(error));

    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t reset=%d rd=%d hlt=%d error=%d address=%d, data=0x%x io_rd=%d io_wr=%d io_data=%d",
                 $time, reset, rd, hlt, error, address, data, io_rd, io_wr, io_data);
        clk = 0;
        reset = 0;
        #10
        reset = 1;
        #1000
        $finish;
    end

    always @(negedge rd) begin
        data <= rom[address[3:0]];
    end

endmodule
