`include "main.vh"

module main
#(parameter CLK_FREQUENCY_DIV4 = 27000000/4, CLK_DIVIDER_BITS = 16, ROM_BITS = 9, RAM_BITS = 9, CHARACTER_ROM_BITS = 8)
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
    wire interrupt;
    reg interrupt_clear = 0;
    wire [27:0] frequency_code;
    reg [CLK_DIVIDER_BITS - 1:0] clk_divider = 0;
    wire hd_selected;
    wire [1:0] stage;
    reg scl = 1;
    reg sda = 1;

    reg [31:0] rom [0:(1<<ROM_BITS)-1];

`ifdef RAM
    reg [15:0] ram [0:(1<<RAM_BITS)-1];
`endif

`ifdef CHARACTER_ROM
    reg [15:0] characters_rom [0:(1<<CHARACTER_ROM_BITS)-1];
`endif

    initial begin
        $readmemh("asm/a.out", rom);
`ifdef CHARACTER_ROM
        $readmemh("characters.mem", characters_rom);
`endif        
    end

    pullup(scl_io);
    pullup(sda_io);

    assign scl_io = scl ? 1'bz : 0;
    assign sda_io = sda ? 1'bz : 0;

	assign io_clk = io_rd & io_wr;

    // cpu clock = 27M/64 = 421875Hz, cpu cpeed = 421875/4=105468 op/sec
    cpu cpu16(.clk(clk_divider[5]), .rd(rd), .reset(reset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd), .stage(stage),
                 .io_wr(io_wr), .io_data_out(io_data_in), .io_data_in(io_data_out), .io_address(io_address), .error(error), .interrupt(interrupt));

    frequency_counter fc(.clk(clk), .iclk(comp_data_hi), .clk_frequency_div4(CLK_FREQUENCY_DIV4), .code(frequency_code), .interrupt(interrupt),
                            .interrupt_clear(interrupt_clear));

    logic_probe_led #(.COUNTER_WIDTH(19))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .led_one(led_one), .led_zero(led_zero), .led_floating(led_floating),
                .led_pulse(led_pulse));

    always @(posedge clk) begin
        clk_divider <= clk_divider + 1;
    end

`ifndef INTEL
    always @(negedge clk_divider[CLK_DIVIDER_BITS-1]) begin
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
                    hd_data <= io_data_in[7:0];
                    {hd_dc, hd_e} <= io_address[1:0];
                end
            end
            1: begin
                io_data_out <= io_address[0] ? {4'b0, frequency_code[27:16]} : frequency_code[15:0];
                interrupt_clear <= !io_address[0];
            end
            2: begin
                if (io_wr == 0)
                    {scl, sda} <= io_data_in[1:0];
                else
                    io_data_out <= {13'b0, button, scl_io, sda_io};
            end
`ifdef RAM            
            3: begin
                if (io_wr == 0)
                    ram[io_address[RAM_BITS-1:0]] <= io_data_in;
                else
                    io_data_out <= ram[io_address[RAM_BITS-1:0]];
            end
`endif            
`ifdef CHARACTER_ROM
            4: io_data_out <= characters_rom[io_address[CHARACTER_ROM_BITS-1:0]];
`endif            
        endcase
    end

endmodule
