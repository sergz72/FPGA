module cpu16_tb;
    wire [15:0] address;
    wire hlt, io_rd, io_wr, error, rd;
    wire [2:0] stage;
    wire [15:0] io_data_in, io_address;
    reg [31:0] data;
    reg clk, reset, interrupt;
    reg [15:0] io_data_out;
    reg ready;

    reg [31:0] rom [0:255];
    reg [15:0] ram [0:65535];

    initial begin
        $display("Loading rom.");
        $readmemh("asm/a.out", rom);
    end

    cpu cpu16(.clk(clk), .rd(rd), .reset(reset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd), .stage(stage), .ready(ready),
                 .io_wr(io_wr), .io_data_in(io_data_out), .io_data_out(io_data_in), .io_address(io_address), .error(error), .interrupt(interrupt));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu16_tb.vcd");
        $dumpvars(0, cpu16_tb);
        $monitor("time=%t clk=%d stage=%d reset=%d rd=%d hlt=%d error=%d address=%x, data=0x%x io_rd=%d io_wr=%d io_data_in=%x io_data_out=%x io_address=%x interrupt=%d",
                 $time, clk, stage, reset, rd, hlt, error, address, data, io_rd, io_wr, io_data_in, io_data_out, io_address, interrupt);
        clk = 0;
        reset = 0;
        interrupt = 0;
        ready = 1;
        #20
        reset = 1;
        #1000
//        interrupt = 1;
        #100000
        $finish;
    end

    always @(negedge io_rd or negedge io_wr) begin
        if (!io_rd)
            io_data_out <= ram[io_address];
        else begin
            if (io_address == 'hFFFF)
                interrupt <= 0;
            else
                ram[io_address] <= io_data_in;
        end
    end

    always @(negedge rd) begin
        data <= rom[address[7:0]];
    end
endmodule
