module qspi_psram_controller_tb;
    reg clk;
    reg [15:0] address;
    reg [15:0] data_out;
    reg [31:0] data_out2;
    wire [15:0] data_in;
    wire [31:0] data_in2;
    reg nrd;
    reg nwr;
    wire busy, busy2;
    wire sck;
    wire mosi;
    wire [1:0] mosi2;
    reg miso;
    reg [1:0] miso2;
    wire ncs, ncs2;
    reg nreset;

    always #1 clk <= ~clk;

    spi_ram_controller c(.clk(clk), .address(address), .data_out(data_in), .data_in(data_out), .nrd(nrd), .nwr(nwr), .busy(busy),
                         .sck(sck), .mosi(mosi), .miso(miso), .ncs(ncs), .nreset(nreset));

    spi_ram_controller #(.CHIP_COUNT(2)) c2(.clk(clk), .address(address), .data_out(data_in2), .data_in(data_out2), .nrd(nrd), .nwr(nwr), .busy(busy2),
                                            .sck(sck), .mosi(mosi2), .miso(miso2), .ncs(ncs2), .nreset(nreset));

    initial begin
        $dumpfile("spi_ram_controller_tb.vcd");
        $dumpvars(0, spi_ram_controller_tb);
        $monitor("time=%t clk=%d nreset=%d nrd=%d nwr=%d address=%x data_out=%x data_in=%x data_out2=%x data_in2=%x busy=%d busy2=%d sck=%d mosi=%d miso=%d mosi2[0]=%d mosi2[1]=%d miso2[0]=%d miso2[1]=%d ncs=%d ncs2=%d",
                 $time, clk, nreset, nrd, nwr, address, data_in, data_out, data_in2, data_out2, busy, busy2, sck, mosi, miso, mosi2[0], mosi2[1], miso2[0], miso2[1], ncs, ncs2);
        clk = 0;
        nreset = 0;
        nrd = 1;
        nwr = 1;
        miso = 1;
        miso2 = 2'b11;
        address = 16'h55AA;
        data_out = 16'h3344;
        data_out2 = 32'h11223344;
        #20
        nreset = 1;
        #50
        nwr = 0;
        #200
        nwr = 1;
        #20
        $finish;
    end
endmodule
