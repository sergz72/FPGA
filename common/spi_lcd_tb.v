module spi_lcd_tb;
    reg clk, nreset, req;
    reg [9:0] data_out;
    wire ack, fifo_full, done, sck, mosi, ncs, dc;

    spi_lcd slcd(.clk(clk), .nreset(nreset), .data_in(data_out), .req(req), .ack(ack),
                    .sck(sck), .mosi(mosi), .ncs(ncs), .dc(dc), .fifo_full(fifo_full), .done(done));

    always #1 clk <= ~clk;

    initial begin
        $dumpfile("spi_lcd_tb.vcd");
        $dumpvars(0, spi_lcd_tb);
        $monitor("time=%t clk=%d nreset=%d req=%d ack=%d data_out=%x sck=%d mosi=%d ncs=%d dc=%d fifo_full=%d done=%d",
                 $time, clk, nreset, req, ack, data_out, sck, mosi, ncs, dc, fifo_full, done);
        clk = 0;
        nreset = 0;
        req = 0;
        #5
        nreset = 1;
        data_out = 10'h055;
        req = 1;
        #5
        req = 0;
        #5
        data_out = 10'h1AA;
        req = 1;
        #5
        req = 0;
        #5
        data_out = 10'h300;
        req = 1;
        #5
        req = 0;
        #10000
        $finish;
    end
endmodule
