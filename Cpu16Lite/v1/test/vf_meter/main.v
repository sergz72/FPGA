`include "main.vh"

module main
#(parameter CLK_FREQUENCY_DIV4 = 27000000/4,
// 3.375 interrupts/sec
TIMER_BITS = 23,
// about 20 ms delay
RESET_DELAY_BIT = 19,
// div = 64
CPU_CLOCK_BIT = 5,
// 50 hz refresh rate
LOGIC_PROBE_COUNTER_WIDTH = 19,
// 512 bytes ROM
ROM_BITS = 9)
(
    input wire clk,
    input wire comp_data_hi,
    input wire comp_data_lo,
    output wire hlt,
    output wire error,
    inout wire scl_io,
    inout wire sda_io,
    input wire button,
    // hd44780
    output reg hd_dc = 0,
    output reg hd_e = 0,
`ifdef INTEL
    input wire reset,
`endif
    output reg [7:0] hd_data,
    output wire led_one,
    output wire led_zero,
    output wire led_floating,
    output wire led_pulse
);
`ifndef INTEL
    reg reset = 0;
`endif
    wire [15:0] address;
    reg [31:0] data;
    wire rd;
    wire io_rd;
    wire io_wr;
    wire [15:0] io_data_in;
    wire [15:0] io_address;
    reg [15:0] io_data_out;
	wire io_clk;
    reg interrupt = 0;
    reg interrupt_clear = 0;
    wire fc_interrupt;
    reg fc_interrupt_clear = 0;
    wire [27:0] frequency_code;
    reg [TIMER_BITS - 1:0] timer = 0;
    wire hd_selected;
    wire [1:0] stage;
    reg scl = 1;
    reg sda = 1;

    wire led_onen, led_pulsen, led_zeron, led_floatingn;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];

    initial begin
        $readmemh("asm/a.out", rom);
    end

    assign led_one = !led_onen;
    assign led_zero = !led_zeron;
    assign led_floating = !led_floatingn;
    assign led_pulse = !led_pulsen;

    assign scl_io = scl ? 1'bz : 0;
    assign sda_io = sda ? 1'bz : 0;

	assign io_clk = io_rd & io_wr;

    // cpu clock = 27M/64 = 421875Hz, cpu cpeed = 421875/4=105468 op/sec
    cpu cpu16(.clk(timer[CPU_CLOCK_BIT]), .rd(rd), .reset(reset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd), .stage(stage),
                 .io_wr(io_wr), .io_data_out(io_data_in), .io_data_in(io_data_out), .io_address(io_address), .error(error), .interrupt(interrupt), .ready(1));

    frequency_counter fc(.clk(clk), .iclk(comp_data_hi), .clk_frequency_div4(CLK_FREQUENCY_DIV4), .code(frequency_code), .interrupt(fc_interrupt),
                            .interrupt_clear(fc_interrupt_clear));

    logic_probe_led #(.COUNTER_WIDTH(LOGIC_PROBE_COUNTER_WIDTH))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .led_one(led_onen), .led_zero(led_zeron), .led_floating(led_floatingn),
                .led_pulse(led_pulsen));

    always @(posedge clk) begin
        if (timer == {TIMER_BITS{1'b1}})
            interrupt <= 1;
        else if (interrupt_clear)
            interrupt <= 0;
        timer <= timer + 1;
    end

`ifndef INTEL
    always @(negedge timer[RESET_DELAY_BIT]) begin
        reset <= 1;
    end
`endif

    always @(negedge rd) begin
        data <= rom[address[ROM_BITS-1:0]];
    end

    always @(negedge io_clk) begin
        case (io_address[15:14])
            0: begin
                if (io_wr == 0) begin
                    hd_data <= io_data_in[7:0];
                    {hd_dc, hd_e} <= io_address[1:0];
                end
            end
            1: begin
                io_data_out <= io_address[0] ? {fc_interrupt, 3'b0, frequency_code[27:16]} : frequency_code[15:0];
                fc_interrupt_clear <= !io_address[0];
            end
            2: begin
                if (io_wr == 0)
                    {scl, sda} <= io_data_in[1:0];
                else
                    io_data_out <= {13'b0, button, scl_io, sda_io};
            end
            3: interrupt_clear <= io_data_in[0];
        endcase
    end

endmodule
