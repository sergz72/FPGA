module main
#(parameter
  // 3.375 interrupts/sec
  TIMER_BITS = 23,
  // about 20 ms delay
  RESET_DELAY_BIT = 19,
  // 1k 32 bit words RAM
  RAM_BITS = 10,
  // 1k 32 bit words ROM
  ROM_BITS = 10,
  CPU_CLOCK_BIT = 0
)
(
    input wire clk,
    output wire hlt,
    output wire error,
    output wire wfi,
    output reg led = 1
);
    wire [31:0] io_address;
    wire io_req, io_nwr;
    wire [31:0] io_data_in, io_data_out;
    wire [7:0] irq, interrupt_ack;
    reg nreset = 0;
    wire cpu_clk;

    reg [TIMER_BITS - 1:0] timer = 0;
    reg timer_interrupt = 0;

    assign cpu_clk = timer[CPU_CLOCK_BIT];

    tiny32 #(.ROM_BITS(ROM_BITS), .RAM_BITS(RAM_BITS))
        cpu(.clk(cpu_clk), .io_req(io_req), .io_nwr(io_nwr), .wfi(wfi), .nreset(nreset), .io_address(io_address), .io_data_in(io_data_out),
                .io_data_out(io_data_in), .error(error), .hlt(hlt), .io_ready(1'b1), .interrupt(irq), .interrupt_ack(interrupt_ack));

    assign irq = {7'h0, timer_interrupt};

    assign io_data_out = 32'h12345678;

    always @(posedge clk) begin
        if (timer[RESET_DELAY_BIT])
            nreset <= 1;
        if (interrupt_ack[0])
            timer_interrupt <= 0;
        else if (timer == {TIMER_BITS{1'b1}})
            timer_interrupt <= 1;
        timer <= timer + 1;
    end

    always @(negedge cpu_clk) begin
        if (io_req & !io_nwr)
            led <= io_data_in[0];
    end

endmodule
