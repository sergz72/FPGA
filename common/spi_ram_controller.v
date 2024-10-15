module spi_ram_controller
#(parameter READ_COMMAND = 3, WRITE_COMMAND = 2, WREN_COMMAND = 6, ADDRESS_SIZE = 16, DATA_SIZE = 16)
(
    input wire clk,
    input wire [ADDRESS_SIZE - 1:0] address,
    input wire [DATA_SIZE-1:0] data_in,
    output reg [DATA_SIZE-1:0] data_out,
    input wire rd,
    input wire wr,
    output reg busy = 0,
    output wire sck,
    output wire mosi,
    input wire miso,
    output wire cs,
    input wire reset
);
    localparam SPI_DATA_BITS = 8 + DATA_SIZE + ADDRESS_SIZE;
    reg [SPI_DATA_BITS - 1:0] spi_data;
    reg [7:0] bit_counter;
    reg start = 0;
    reg start2 = 0;
    reg prev_reset = 0;
    reg internal_cs = 1;
    reg done = 1;

    assign cs = rd & wr & internal_cs;
    assign sck = done | clk;
    assign mosi = spi_data[SPI_DATA_BITS - 1];

    always @(posedge clk) begin
        if (bit_counter < DATA_SIZE)
            data_out <= {data_out[DATA_SIZE - 2:0], miso};
    end

    always @(negedge clk) begin
        if (!reset) begin
            start <= 0;
            start2 <= 0;
            prev_reset <= 0;
            internal_cs <= 1;
            done <= 1;
        end
        else begin
            if (WREN_COMMAND != 0 && !prev_reset) begin
                spi_data[SPI_DATA_BITS-1:SPI_DATA_BITS-8] <= WREN_COMMAND;
                bit_counter <= 7;
                internal_cs <= 0;
                start <= 1;
            end
            else begin
                if (!cs) begin
                    if (!start) begin
                        bit_counter <= SPI_DATA_BITS - 1;
                        spi_data[DATA_SIZE-1:0] <= data_in;
                        spi_data[DATA_SIZE + ADDRESS_SIZE - 1:DATA_SIZE] <= address;
                        spi_data[DATA_SIZE + ADDRESS_SIZE+7:DATA_SIZE + ADDRESS_SIZE] <= rd ? WRITE_COMMAND : READ_COMMAND;
                        busy <= 1;
                    end
                    else if (!start2) begin
                        start2 <= 1;
                        done <= 0;
                    end
                    else begin
                        if (bit_counter != 0) begin
                            spi_data <= {spi_data[SPI_DATA_BITS-2:0], 1'b0};
                            bit_counter <= bit_counter - 1;
                        end
                        else begin
                            busy <= 0;
                            internal_cs <= 1;
                            done <= 1;
                        end
                    end
                end
                else
                    start2 <= 0;
                start <= !cs;
            end
        end
        prev_reset <= reset;
    end
endmodule

module spi_ram_controller_tb;
    reg clk;
    reg [15:0] address;
    reg [15:0] data_out;
    wire [15:0] data_in;
    reg rd;
    reg wr;
    wire busy;
    wire sck;
    wire mosi;
    reg miso;
    wire cs;
    reg reset;

    always #1 clk <= ~clk;

    spi_ram_controller c(.clk(clk), .address(address), .data_out(data_in), .data_in(data_out), .rd(rd), .wr(wr), .busy(busy),
                         .sck(sck), .mosi(mosi), .miso(miso), .cs(cs), .reset(reset));

    initial begin
        $dumpfile("spi_ram_controller_tb.vcd");
        $dumpvars(0, spi_ram_controller_tb);
        $monitor("time=%t clk=%d reset=%d rd=%d wr=%d address=%x data_out=%x data_in=%x busy=%d sck=%d mosi=%d miso=%d cs=%d",
                 $time, clk, reset, rd, wr, address, data_in, data_out, busy, sck, mosi, miso, cs);
        clk = 0;
        reset = 0;
        rd = 1;
        wr = 1;
        miso = 1;
        address = 16'h55AA;
        data_out = 16'h3344;
        #20
        reset = 1;
        #50
        wr = 0;
        #200
        wr = 1;
        #20
        $finish;
    end
endmodule
