`include "main.vh"

module main
#(parameter CLK_FREQUENCY_DIV4 = 27000000/4,
// 3.375 interrupts/sec
TIMER_BITS = 23,
// about 20 ms delay
RESET_DELAY_BIT = 19,
// div = 64
CPU_CLOCK_BIT = 5,
// 1024 words ROM
ROM_BITS = 10,
// 256 words characters ROM
CHARACTER_ROM_BITS = 8,
// 512 words RAM
RAM_BITS = 9
)
(
    input wire clk,
    output wire hlt,
    output wire error,
    inout wire scl_io,
    inout wire sda_io,
    input wire button,
    // ks0108
    output reg ks_dc = 0,
    output reg ks_e = 0,
    output reg ks_cs1 = 1,
    output reg ks_cs2 = 1,
    output reg reset,
`ifdef INTEL
    input wire reset_in,
`endif
    output reg [7:0] ks_data
);
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
    reg [TIMER_BITS - 1:0] timer = 0;
    wire ks_selected;
    wire [1:0] stage;
    reg scl = 1;
    reg sda = 1;
    wire wreset;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];
    reg [15:0] character_rom [0:(1<<CHARACTER_ROM_BITS)-1];
    reg [15:0] ram [0:(1<<RAM_BITS)-1];

    initial begin
        $readmemh("asm/a.out", rom);
        $readmemh("characters.mem", character_rom);
    end

`ifdef INTEL
    assign wreset = reset_in;
`else
    assign wreset = reset;
`endif

    assign scl_io = scl ? 1'bz : 0;
    assign sda_io = sda ? 1'bz : 0;

	assign io_clk = io_rd & io_wr;

    // cpu clock = 27M/64 = 421875Hz, cpu cpeed = 421875/4=105468 op/sec
    cpu cpu16(.clk(timer[CPU_CLOCK_BIT]), .rd(rd), .reset(wreset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd), .stage(stage),
                 .io_wr(io_wr), .io_data_out(io_data_in), .io_data_in(io_data_out), .io_address(io_address), .error(error), .interrupt(interrupt));

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
        case (io_address[15:13])
            0: begin
                if (io_wr == 0) begin
                    ks_data <= io_data_in[7:0];
                    {ks_cs1, ks_cs2, ks_dc, ks_e} <= io_address[3:0];
                end
            end
            1: begin
                if (io_wr == 0)
                    {scl, sda} <= io_data_in[1:0];
                else
                    io_data_out <= {13'b0, button, scl_io, sda_io};
            end
            2: interrupt_clear <= io_data_in[0];
            3: io_data_out <= character_rom[io_address[CHARACTER_ROM_BITS-1:0]];
            4: begin
                if (io_wr == 0)
                    ram[io_address[RAM_BITS-1:0]] <= io_data_in;
                else
                    io_data_out <= ram[io_address[RAM_BITS-1:0]];
            end
        endcase
    end

endmodule
