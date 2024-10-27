module uart_fifo
#(parameter RX_FIFO_BITS = 7, TX_FIFO_BITS = 7, CLOCK_DIV = 234, CLOCK_COUNTER_BITS = 8) // 27 MHz clk, 115200 baud
(
    input wire clk,
    input wire nreset,
    output wire tx,
    input wire rx,
    input wire [7:0] data_in,
    output wire [7:0] data_out,
    output wire full,
    output wire empty,
    input wire nrd,
    input wire nwr
);
    wire interrupt, busy, rx_fifo_full, tx_fifo_empty;
    reg interrupt_clear = 0;
    reg rx_fifo_wr = 1;
    reg send_next = 0;
    wire [7:0] tx_data, rx_data;

    uart1tx #(.CLOCK_DIV(CLOCK_DIV), .CLOCK_COUNTER_BITS(CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(tx), .data(tx_data), .send(send_next), .busy(busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(CLOCK_DIV), .CLOCK_COUNTER_BITS(CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(rx), .data(rx_data), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    fifo #(.WIDTH(8), .SIZE_BITS(RX_FIFO_BITS))
        rx_fifo(.nrst(nreset), .clk(clk), .nrd(nrd), .nwr(rx_fifo_wr), .data_out(data_out), .data_in(rx_data), .full(rx_fifo_full), .empty(empty));
    fifo #(.WIDTH(8), .SIZE_BITS(TX_FIFO_BITS))
        tx_fifo(.nrst(nreset), .clk(clk), .nwr(nwr), .nrd(!send_next), .data_in(data_in), .data_out(tx_data), .full(full), .empty(tx_fifo_empty));

    always @(negedge clk) begin
        if (!nreset) begin
            interrupt_clear <= 0;
            send_next <= 0;
            rx_fifo_wr <= 1;
        end
        else begin
            send_next <= !tx_fifo_empty & !busy;
            interrupt_clear <= interrupt;
            rx_fifo_wr <= !interrupt | rx_fifo_full;
        end
    end

endmodule
