module cpu16_tb;
    wire [15:0] address;
    wire hlt, io_rd, io_wr, error, rd;
    wire [1:0] stage;
    wire [15:0] io_data, io_address;
    reg [31:0] data;
    reg clk, reset, interrupt;
    reg [15:0] io_data_out;

    reg [31:0] rom [0:63];
    reg [15:0] ram [0:65535];

    initial begin
        $display("Loading rom.");
        $readmemh("asm/a.out", rom);
    end

    assign io_data = io_rd ? 16'bzzzzzzzzzzzzzzzz : io_data_out;

    cpu cpu16(.clk(clk), .rd(rd), .reset(reset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd), .stage(stage),
                 .io_wr(io_wr), .io_data(io_data), .io_address(io_address), .error(error), .interrupt(interrupt));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu16_tb.vcd");
        $dumpvars(0, cpu16_tb);
        $monitor("time=%t clk=%d stage=%d reset=%d rd=%d hlt=%d error=%d address=%x, data=0x%x io_rd=%d io_wr=%d io_data=%x io_address=%x interrupt=%d",
                 $time, clk, stage, reset, rd, hlt, error, address, data, io_rd, io_wr, io_data, io_address, interrupt);
        clk = 0;
        reset = 0;
        interrupt = 0;
        #20
        reset = 1;
        //#1000
        //interrupt = 1;
        #10000
        $finish;
    end

    always @(negedge io_rd or negedge io_wr) begin
        if (!io_rd)
            io_data_out <= ram[io_address];
        else
            ram[io_address] <= io_data;
    end

    always @(negedge rd) begin
        data <= rom[address[5:0]];
    end
endmodule
