module spi_lcd
#(parameter FIFO_BITS = 12, CLOCK_DIVIDER = 4, CLOCK_DIVIDER_BITS = 3)
(
    input wire clk,
    input wire nreset,
    input wire [9:0] data_in,
    input wire req,
    output wire ack,
    output wire fifo_full,
    output reg done,
    output reg sck,
    output wire mosi,
    output reg ncs,
    output reg dc
);
    wire tx_fifo_empty;
    reg tx_fifo_rreq;
    wire tx_fifo_rack;
    wire [9:0] tx_data;
    reg [7:0] spi_data;
    reg send;
    reg [CLOCK_DIVIDER_BITS-1:0] clock_divider;
    reg [3:0] bit_counter;

    assign mosi = spi_data[7];

    fifo #(.WIDTH(10), .SIZE_BITS(FIFO_BITS))
        tx_fifo(.nrst(nreset), .clk(clk), .wreq(req), .wack(ack), .rreq(tx_fifo_rreq), .rack(tx_fifo_rack),
                .data_in(data_in), .data_out(tx_data), .full(fifo_full), .empty(tx_fifo_empty));

    always @(posedge clk) begin
        if (!nreset) begin
            done <= 0;
            sck <= 0;
            tx_fifo_rreq <= 0;
            send <= 0;
            clock_divider <= 0;
            bit_counter <= 0;
            ncs <= 1;
        end
        else if (send) begin
            if (clock_divider == CLOCK_DIVIDER - 1) begin
                clock_divider <= 0;
                if (bit_counter == 8) begin
                    send <= 0;
                    bit_counter <= 0;
                end
                else begin
                    if (sck) begin
                        bit_counter <= bit_counter + 1;
                        spi_data <= {spi_data[6:0], 1'b0};
                    end
                    sck <= !sck;
                end
            end
            else
                clock_divider <= clock_divider + 1;
        end
        else begin
            if (tx_fifo_rack) begin
                tx_fifo_rreq <= 0;
                {ncs, dc, spi_data} <= tx_data;
                send <= 1;
            end
            else begin
                done <= tx_fifo_empty;
                if (!tx_fifo_empty & !tx_fifo_rreq)
                    tx_fifo_rreq <= 1;
            end
        end
    end
endmodule
