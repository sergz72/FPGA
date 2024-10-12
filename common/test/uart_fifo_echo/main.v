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
    localparam WRITE = 8;

    reg nreset = 0;
    reg [25:0] timer = 0;
    reg [3:0] state = WAIT0;

    wire [7:0] uart_data;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    reg uart_nrd = 1;
    reg uart_nwr = 1;

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(uart_data), .data_out(uart_data), .nwr(uart_nwr), .nrd(uart_nrd), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty));

    always @(negedge clk) begin
        if (timer[3])
            nreset <= 1;
        timer <= timer + 1;
    end
    
    always @(posedge clk) begin
        if (!nreset) begin
            uart_nrd <= 1;
            uart_nwr <= 1;
            state <= WAIT0;
        end
        else begin
            case (state)
                WAIT0: begin
                    if (timer == 0)
                        state <= WAIT;
                end
                WAIT: begin
                    if (!uart_rx_fifo_empty) begin
                        state <= READ;
                        uart_nrd <= 0;
                    end
                    else
                        state <= WAIT0;
                end
                READ: begin
                    uart_nrd <= 1;
                    uart_nwr <= 0;
                    state <= WRITE;
                end
                WRITE: begin
                    uart_nwr <= 1;
                    state <= WAIT;
                end
            endcase
        end
    end
endmodule
