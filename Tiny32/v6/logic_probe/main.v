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
  SPI_LCD_FIFO_BITS = 10,
  SPI_LCD_CLOCK_DIVIDER = 2,
  SPI_LCD_CLOCK_DIVIDER_BITS = 2,
  MHZ_TIMER_BITS = 6,
  MHZ_TIMER_VALUE = 32,
  //200 ms
  PROBE_TIME_PERIOD = 25920000
)
(
    input wire clk,
    input wire clk_probe,
    output wire nhlt,
    output wire nerror,
    output wire nwfi,
    output reg led,
    output wire tx,
    input wire rx,
    output wire sck,
    output wire mosi,
    output wire ncs,
    output wire dc,
    input wire button1,
    input wire button2,
    output reg [4:0] dac1_code,
    output reg [4:0] dac2_code,
    input wire comp_out_hi,
    input wire comp_out_lo
);
    localparam IO_SELECTOR_START_BIT = 29;

    wire [31:0] io_address;
    wire io_req, io_nwr;
    wire [31:0] io_data_in, io_data_out;
    wire [7:0] irq, interrupt_ack;
    reg nreset = 0;
    wire cpu_clk;
    wire [31-IO_SELECTOR_START_BIT:0] io_selector;
    wire port_selected, uart_data_selected, spi_lcd_selected;
    wire probe_selected, dac1_selected, dac2_selected, timer_selected;
    reg io_ready;

    reg [RESET_BIT:0] timer = 0;

    wire uart_rx_fifo_empty, uart_tx_fifo_full;
    wire uart_req;
    wire uart_ack;
    wire [7:0] uart_data_out;

    wire spi_lcd_req, spi_lcd_ack, spi_lcd_fifo_full, spi_lcd_done;

    wire timer_interrupt, timer_req, timer_ack;

    wire [31:0] probe_data;
    wire probe_req, probe_ack, probe_interrupt;
    reg probe_interrupt_clear = 0;
    reg probe_nreset = 0;

    wire hlt, error, wfi;

    assign nhlt = !hlt;
    assign nwfi = !wfi;
    assign nerror = !error;
    
    assign cpu_clk = timer[CPU_CLOCK_BIT];

    assign io_selector = io_address[31:IO_SELECTOR_START_BIT];

    assign port_selected = io_selector == 0;
    assign uart_data_selected = io_selector == 1;
    assign spi_lcd_selected = io_selector == 2;
    assign timer_selected = io_selector == 3;
    assign probe_selected = io_selector == 4;
    assign dac1_selected = io_selector == 5;
    assign dac2_selected = io_selector == 6;

    assign io_data_out = uart_data_selected
            ? {24'h0, uart_data_out}
            : (probe_selected ? probe_data : {26'h0, button1, button2, spi_lcd_done, spi_lcd_fifo_full, uart_rx_fifo_empty, uart_tx_fifo_full});

    assign uart_req = uart_data_selected & io_req;
    assign spi_lcd_req = spi_lcd_selected & io_req & !io_nwr;
    assign timer_req = timer_selected & io_req & !io_nwr;
    assign probe_req = probe_selected & io_req & io_nwr;

    tiny32 #(.ROM_BITS(ROM_BITS), .RAM_BITS(RAM_BITS))
        cpu(.clk(cpu_clk), .io_req(io_req), .io_nwr(io_nwr), .wfi(wfi), .nreset(nreset), .io_address(io_address), .io_data_in(io_data_out),
                .io_data_out(io_data_in), .error(error), .hlt(hlt), .io_ready(io_ready), .interrupt(irq), .interrupt_ack(interrupt_ack));

    uart_fifo #(.CLOCK_DIV(UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(UART_CLOCK_COUNTER_BITS))
        ufifo(.clk(clk), .tx(tx), .rx(rx), .data_in(io_data_in[7:0]), .data_out(uart_data_out), .nwr(io_nwr), .req(uart_req), .nreset(nreset),
                .full(uart_tx_fifo_full), .empty(uart_rx_fifo_empty), .ack(uart_ack));


    spi_lcd #(.FIFO_BITS(SPI_LCD_FIFO_BITS), .CLOCK_DIVIDER(SPI_LCD_CLOCK_DIVIDER), .CLOCK_DIVIDER_BITS(SPI_LCD_CLOCK_DIVIDER_BITS))
        slcd(.clk(clk), .nreset(nreset), .data_in(io_data_in[9:0]), .req(spi_lcd_req), .ack(spi_lcd_ack),
                    .sck(sck), .mosi(mosi), .ncs(ncs), .dc(dc), .fifo_full(spi_lcd_fifo_full), .done(spi_lcd_done));

    timer #(.MHZ_TIMER_BITS(MHZ_TIMER_BITS), .MHZ_TIMER_VALUE(MHZ_TIMER_VALUE))
        t(.clk(clk), .nreset(nreset), .req(timer_req), .ack(timer_ack), .value(io_data_in), .interrupt(timer_interrupt), .interrupt_clear(interrupt_ack[0]));

    logic_probe #(.TIME_PERIOD(PROBE_TIME_PERIOD))
        probe(.clk(clk_probe), .nreset(probe_nreset), .comp_data_hi(comp_out_hi), .comp_data_lo(comp_out_lo), .data(probe_data), .address(io_address[2:0]),
                .data_request(probe_req), .data_ready(probe_ack), .interrupt(probe_interrupt), .interrupt_clear(probe_interrupt_clear));

    assign irq = {6'h0, probe_interrupt, timer_interrupt};

    always @(posedge clk) begin
        if (timer[RESET_BIT])
            nreset <= 1;
        timer <= timer + 1;
    end

    always @(negedge cpu_clk) begin
        io_ready <= io_req & (port_selected | dac1_selected | dac2_selected | uart_ack | timer_ack | probe_ack | spi_lcd_ack);
        if (port_selected & io_req & !io_nwr)
            {probe_nreset, probe_interrupt_clear, led} <= io_data_in[2:0];
    end

    always @(negedge cpu_clk) begin
        if (dac1_selected & io_req & !io_nwr)
            dac1_code <= io_data_in[4:0];
    end

    always @(negedge cpu_clk) begin
        if (dac2_selected & io_req & !io_nwr)
            dac2_code <= io_data_in[4:0];
    end

endmodule
