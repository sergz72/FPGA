module cpu16_tb;
    wire [15:0] address;
    wire rd, hlt, io_rd, io_wr;
    wire [15:0] io_data;
    reg [31:0] data;
    reg clk, reset;

    reg [31:0] rom [15:0];

    initial begin
        rom[0] = 0; // NOP
        rom[1] = 32'h00030001; // jmp 3
        rom[2] = 31; //hlt
        rom[3] = 32'h00050009; // call 5
        rom[4] = 32'h00000001; // jmp 0
        rom[5] = 32'h00000011; // return
        rom[6] = 31; //hlt
    end

    cpu cpu16(.clk(clk), .reset(reset), .address(address), .data(data), .rd(rd), .hlt(hlt), .io_rd(io_rd),
                 .io_wr(io_wr), .io_data(io_data));

    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t reset=%d rd=%d hlt=%d address=%d, data=0x%x io_rd=%d io_wr=%d io_data=%d",
                 $time, reset, rd, hlt, address, data, io_rd, io_wr, io_data);
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
