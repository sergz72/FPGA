module main
#(parameter
// 115200 at 27MHz
UART_CLOCK_DIV = 234,
// 115200 at 10MHz
//UART_CLOCK_DIV = 87,
UART_CLOCK_COUNTER_BITS = 8
)
(
    input wire clk,
    output wire tx,
    input wire rx
);
    localparam WAIT0 = 1;
    localparam WAIT  = 2;
    localparam READ  = 4;
    localparam PAUSE_READ = 8;
    localparam WRITE = 16;
    localparam PAUSE_WRITE = 32;

    reg nreset = 0;
    reg [25:0] timer = 0;
    reg [5:0] state = WAIT0;

    wire [7:0] uart_data;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    reg uart_req = 0;
    reg uart_nwr = 1;
    wire uart_ack;

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(uart_data), .data_out(uart_data), .nwr(uart_nwr), .req(uart_req), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty), .ack(uart_ack));

    always @(negedge clk) begin
        if (timer[3])
            nreset <= 1;
        timer <= timer + 1;
    end
    
    always @(posedge clk) begin
        if (!nreset) begin
            uart_req <= 0;
            uart_nwr <= 1;
            state <= WAIT0;
        end
        else begin
            case (state)
                WAIT0: begin
                    if (timer == 0)
                        state <= WAIT;
                end
                WAIT: state <= uart_rx_fifo_empty ? WAIT0 : READ;
                READ: begin
                    uart_req <= !uart_ack;
                    state <= uart_ack ? PAUSE_READ : READ;
                end
                PAUSE_READ: state <= uart_ack ? PAUSE_READ : WRITE;
                WRITE: begin
                    uart_req <= !uart_ack;
                    uart_nwr <= uart_ack;
                    state <= uart_ack ? PAUSE_WRITE : WRITE;
                end
                PAUSE_WRITE: state <= uart_ack ? PAUSE_WRITE : WAIT;
            endcase
        end
    end
endmodule
