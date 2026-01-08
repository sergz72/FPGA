module qspi_psram_controller
#(parameter QSPI_MODE_ENGER_COMMAND = 8'h35, READ_COMMAND = 8'hEB, WRITE_COMMAND = 8'h38, ADDRESS_SIZE = 24, DATA_SIZE = 16, CHIP_COUNT = 2)
(
    input wire clk,
    input wire nreset,
    input wire [ADDRESS_SIZE - 1:0] cpu_address,
    input wire [CHIP_COUNT * DATA_SIZE - 1:0] cpu_data_in,
    output wire [CHIP_COUNT * DATA_SIZE - 1:0] cpu_data_out,
    input wire cpu_req,
    output reg cpu_ack,
    output wire psram_sck,
    output wire [CHIP_COUNT - 1:0] [3:0] psram_sio_out,
    input wire [CHIP_COUNT - 1:0] [3:0] psram_sio_in,
    output reg psram_sio_oe,
    output wire psram_ncs
);
    localparam SPI_DATA_BITS = 8 + DATA_SIZE + ADDRESS_SIZE;
    reg [SPI_DATA_BITS - 1:0] spi_data [0: CHIP_COUNT - 1];
    reg [DATA_SIZE - 1:0] data_out [0: CHIP_COUNT - 1];
    reg [7:0] bit_counter;

    assign psram_sck = !clk;

    genvar i;
    generate
        for (i = 0; i < CHIP_COUNT; i = i + 1) begin
            assign cpu_data_out[DATA_SIZE * i - 1: DATA_SIZE * (i - 1)] = data_out[i];
            assign ram_sio_out[i] = spi_data[i][SPI_DATA_BITS - 1: SPI_DATA_BITS - 4];

            always @(posedge clk) begin
                if (data_out_shift)
                    data_out[i] <= {data_out[i][DATA_SIZE - 4:0], psram_sio_in[i]};
            end

            always @(posedge clk) begin
                if (nreset) begin
                    if (!ncs) begin
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
