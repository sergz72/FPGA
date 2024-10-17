module spi_ram_controller
#(parameter READ_COMMAND = 3, WRITE_COMMAND = 2, WREN_COMMAND = 6, ADDRESS_SIZE = 16, DATA_SIZE = 16, CHIP_COUNT = 1)
(
    input wire clk,
    input wire [ADDRESS_SIZE - 1:0] address,
    input wire [CHIP_COUNT * DATA_SIZE-1:0] data_in,
    output wire [CHIP_COUNT * DATA_SIZE-1:0] data_out,
    input wire nrd,
    input wire nwr,
    output reg busy = 0,
    output wire sck,
    output wire [CHIP_COUNT - 1:0] mosi,
    input wire [CHIP_COUNT - 1:0] miso,
    output wire ncs,
    input wire nreset
);
    localparam SPI_DATA_BITS = 8 + DATA_SIZE + ADDRESS_SIZE;
    reg [SPI_DATA_BITS - 1:0] spi_data [0: CHIP_COUNT - 1];
    reg [7:0] bit_counter;
    reg start = 0;
    reg start2 = 0;
    reg prev_reset = 0;
    reg internal_cs = 1;
    reg done = 1;
    reg [DATA_SIZE-1:0] data_out_reg [0: CHIP_COUNT - 1];
    wire data_out_shift, send_wren, spi_data_shift;

    assign ncs = nrd & nwr & internal_cs;
    assign sck = done | clk;

    assign data_out_shift = bit_counter < DATA_SIZE;
    assign send_wren = WREN_COMMAND != 0 && !prev_reset;
    assign spi_data_shift = bit_counter != 0;

    genvar i;
    generate
        for (i = 0; i < CHIP_COUNT; i = i + 1) begin
            assign mosi[i] = spi_data[i][SPI_DATA_BITS - 1];
            assign data_out[(i + 1) * DATA_SIZE-1:i * DATA_SIZE] = data_out_reg[i];

            always @(posedge clk) begin
                if (data_out_shift)
                    data_out_reg[i] <= {data_out_reg[i][DATA_SIZE - 2:0], miso};
            end

            always @(negedge clk) begin
                if (nreset) begin
                    if (send_wren)
                        spi_data[i][SPI_DATA_BITS-1:SPI_DATA_BITS-8] <= WREN_COMMAND;
                    else if (!ncs) begin
                        if (!start) begin
                            spi_data[i][DATA_SIZE-1:0] <= data_in[(i + 1) * DATA_SIZE-1:i * DATA_SIZE];
                            spi_data[i][DATA_SIZE + ADDRESS_SIZE - 1:DATA_SIZE] <= address;
                            spi_data[i][DATA_SIZE + ADDRESS_SIZE+7:DATA_SIZE + ADDRESS_SIZE] <= nrd ? WRITE_COMMAND : READ_COMMAND;
                        end
                        else if (start2 & spi_data_shift) begin
                            spi_data[i] <= {spi_data[i][SPI_DATA_BITS-2:0], 1'b0};
                        end
                    end
                end
            end
        end
    endgenerate

    always @(negedge clk) begin
        if (!nreset) begin
            start <= 0;
            start2 <= 0;
            prev_reset <= 0;
            internal_cs <= 1;
            done <= 1;
        end
        else begin
            if (send_wren) begin
                bit_counter <= 7;
                internal_cs <= 0;
                start <= 1;
            end
            else begin
                if (!ncs) begin
                    if (!start) begin
                        bit_counter <= SPI_DATA_BITS - 1;
                        busy <= 1;
                    end
                    else if (!start2) begin
                        start2 <= 1;
                        done <= 0;
                    end
                    else begin
                        if (spi_data_shift)
                            bit_counter <= bit_counter - 1;
                        else begin
                            busy <= 0;
                            internal_cs <= 1;
                            done <= 1;
                        end
                    end
                end
                else
                    start2 <= 0;
                start <= !ncs;
            end
        end
        prev_reset <= nreset;
    end
endmodule

module spi_ram_controller_tb;
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
