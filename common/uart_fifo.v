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
    reg send = 0;
    reg rx_fifo_wr = 1;
    reg tx_fifo_rd = 1;
    reg send_next = 0;
    wire [7:0] tx_data, rx_data;

    uart1tx #(.CLOCK_DIV(CLOCK_DIV), .CLOCK_COUNTER_BITS(CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(tx), .data(tx_data), .send(send), .busy(busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(CLOCK_DIV), .CLOCK_COUNTER_BITS(CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(rx), .data(rx_data), .interrupt(interrupt), .interrupt_clear(interrupt_clear), .nreset(nreset));

    fifo #(.WIDTH(8), .SIZE_BITS(RX_FIFO_BITS))
        rx_fifo(.nrst(nreset), .nrd(nrd), .nwr(rx_fifo_wr), .data_out(data_out), .data_in(rx_data), .full(rx_fifo_full), .empty(empty));
    fifo #(.WIDTH(8), .SIZE_BITS(TX_FIFO_BITS))
        tx_fifo(.nrst(nreset), .nwr(nwr), .nrd(tx_fifo_rd), .data_in(data_in), .data_out(tx_data), .full(full), .empty(tx_fifo_empty));

    always @(negedge clk) begin
        if (!nreset) begin
            interrupt_clear <= 0;
            send <= 0;
            send_next <= 0;
            rx_fifo_wr <= 1;
            tx_fifo_rd <= 1;
        end
        else begin
            if (!tx_fifo_empty & !busy) begin
                tx_fifo_rd <= 0;
                send_next <= 1;
            end
            if (send)
                send <= 0;
            if (send_next) begin
                tx_fifo_rd <= 1;
                send_next <= 0;
                send <= 1;
            end
            interrupt_clear <= interrupt;
            rx_fifo_wr <= !interrupt | rx_fifo_full;
        end
    end

endmodule

module uart_fifo_tb;
    reg clk;
    wire tx;
    reg [7:0] data_in;
    wire [7:0] data_out;
    reg nwr, nrd;
    wire full, empty;
    reg nreset;

    uart_fifo #(.CLOCK_DIV(8), .CLOCK_COUNTER_BITS(4))
        ufifo(.clk(clk), .tx(tx), .rx(tx), .data_in(data_in), .data_out(data_out), .nwr(nwr), .nrd(nrd), .nreset(nreset),
                .full(full), .empty(empty));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("uart_fifo_tb.vcd");
        $dumpvars(0, uart_fifo_tb);
        $monitor("time=%t clk=%d nreset=%d tx=%d nwr=%d nrd=%d data_in=%x data_out=%x full=%d empty=%d",
                    $time, clk, nreset, tx, nwr, nrd, data_in, data_out, full, empty);
        clk = 0;
        data_in = 8'h5A;
        nrd = 1;
        nwr = 1;
        nreset = 0;
        #5
        nreset = 1;
        #5
        nwr = 0;
        #5
        nwr = 1;
        #200
        nrd = 0;
        #5
        nrd = 1;
        data_in = 8'hA5;
        nwr = 0;
        #5
        nwr = 1;
        #200
        nrd = 0;
        #5
        nrd = 1;
        #5
        $finish;
    end
endmodule
