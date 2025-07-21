module main
#(parameter
  UART_CLOCK_DIV = 234,
  UART_CLOCK_COUNTER_BITS = 8,
  // about 100 ms delay
  RESET_BIT = 22,
  // 4k 32 bit words RAM
  RAM_BITS = 12,
  // 8k 32 bit words ROM
  ROM_BITS = 13,
  CPU_CLOCK_BIT = 0,
  SPI_LCD_FIFO_BITS = 12,
  SPI_LCD_CLOCK_DIVIDER = 4,
  SPI_LCD_CLOCK_DIVIDER_BITS = 3
)
(
    input wire clk,
    output wire hlt,
    output wire error,
    output wire wfi,
    output reg led = 1,
    output wire tx,
    input wire rx,
    output wire sck,
    output wire mosi,
    output wire ncs,
    output wire dc
);
    localparam IO_SELECTOR_START_BIT = 28;

    wire [31:0] io_address;
    wire io_req, io_nwr;
    wire [31:0] io_data_in, io_data_out;
    wire [7:0] irq, interrupt_ack;
    reg nreset = 0;
    wire cpu_clk;
    wire [31-IO_SELECTOR_START_BIT:0] io_selector;
    wire port_selected, uart_data_selected, spi_lcd_selected;
    reg io_ready;

    reg [RESET_BIT:0] timer = 0;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_req;
    wire uart_ack;
    wire [7:0] uart_data_out;

    wire spi_lcd_req, spi_lcd_ack, spi_lcd_fifo_full, spi_lcd_done;

    assign cpu_clk = timer[CPU_CLOCK_BIT];

    assign io_selector = io_address[31:IO_SELECTOR_START_BIT];

    assign port_selected = io_selector == 0;
    assign uart_data_selected = io_selector == 1;
    assign spi_lcd_selected = io_selector == 2;

    assign io_data_out = uart_data_selected ? {24'h0, uart_data_out} : {28'h0, spi_lcd_done, spi_lcd_fifo_full, uart_rx_fifo_empty, uart_tx_fifo_full};

    assign uart_req = uart_data_selected & io_req;

    assign spi_lcd_req = spi_lcd_selected & io_req & !io_nwr;

    tiny32 #(.ROM_BITS(ROM_BITS), .RAM_BITS(RAM_BITS))
        cpu(.clk(cpu_clk), .io_req(io_req), .io_nwr(io_nwr), .wfi(wfi), .nreset(nreset), .io_address(io_address), .io_data_in(io_data_out),
                .io_data_out(io_data_in), .error(error), .hlt(hlt), .io_ready(io_ready), .interrupt(irq), .interrupt_ack(interrupt_ack));

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(io_data_in[7:0]), .data_out(uart_data_out), .nwr(io_nwr), .req(uart_req), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty), .ack(uart_ack));


    spi_lcd !(.FIFO_BITS(SPI_LCD_FIFO_BITS), .CLOCK_DIVIDER(SPI_LCD_CLOCK_DIVIDER), .CLOCK_DIVIDER_BITS(SPI_LCD_CLOCK_DIVIDER_BITS))
        slcd(.clk(clk), .nreset(nreset), .data_in(io_data_in[9:0]), .req(spi_lcd_req), .ack(spi_lcd_ack),
                    .sck(sck), .mosi(mosi), .ncs(ncs), .dc(dc), .fifo_full(spi_lcd_fifo_full), .done(spi_lcd_done));

    assign irq = 8'h0; //{7'h0, timer_interrupt};

    always @(posedge clk) begin
        if (timer[RESET_DELAY_BIT])
            nreset <= 1;
        timer <= timer + 1;
    end

    always @(negedge cpu_clk) begin
        io_ready <= io_req & (port_selected | uart_ack);
        if (port_selected & io_req & !io_nwr)
            led <= io_data_in[0];
    end

endmodule
