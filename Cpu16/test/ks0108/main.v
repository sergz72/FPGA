module main
#(parameter CLK_FREQUENCY_DIV4 = 27000000/4, RESET_COUNTER_BITS = 16)
(
    input wire clk,
    input wire comp_data_hi,
    input wire comp_data_lo,
    output wire hlt,
    output wire error,
    inout wire scl_io,
    inout wire sda_io,
    // ks0108
    output wire ks_dc,
    output wire ks_cs1,
    output wire ks_cs2,
    output wire ks_e,
    output reg ks_reset = 0,
    output reg [7:0] ks_data,
    output wire led_one,
    output wire led_zero,
    output wire led_floating,
    output wire led_pulse
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
    wire interrupt;
    reg interrupt_clear = 0;
    wire [27:0] frequency_code;
    reg [RESET_COUNTER_BITS - 1:0] reset_counter = 0;
    wire ks_selected;
    wire [1:0] stage;
    reg scl = 1;
    reg sda = 1;

    reg [31:0] rom [0:2047];

    reg [15:0] ram [0:511];

    reg [15:0] characters_rom [0:511];

    initial begin
        $readmemh("asm/a.out", rom);
        $readmemh("characters.mem", characters_rom);
    end

    assign scl_io = scl ? 1'bz : 0;
    assign sda_io = sda ? 1'bz : 0;

	assign io_clk = io_rd & io_wr;

    cpu cpu16(.clk(clk), .rd(rd), .reset(ks_reset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd), .stage(stage),
                 .io_wr(io_wr), .io_data_out(io_data_in), .io_data_in(io_data_out), .io_address(io_address), .error(error), .interrupt(interrupt));

    frequency_counter fc(.clk(clk), .iclk(comp_data_hi), .clk_frequency_div4(CLK_FREQUENCY_DIV4), .code(frequency_code), .interrupt(interrupt),
                            .interrupt_clear(interrupt_clear));

    logic_probe_led #(.COUNTER_WIDTH(19))
        probe(.clk(clk), .comp_data_hi(comp_data_hi), .comp_data_lo(comp_data_lo),
                .led_one(led_one), .led_zero(led_zero), .led_floating(led_floating),
                .led_pulse(led_pulse));

    always @(posedge clk) begin
        if (reset_counter == {RESET_COUNTER_BITS{1'b1}})
            ks_reset <= 1;
        else
            reset_counter <= reset_counter + 1;
    end

    always @(negedge rd) begin
        data <= rom[address[10:0]];
    end

    assign ks_selected = io_address[12:10] == 3;
    assign {ks_dc, ks_cs1, ks_cs2, ks_e} = ks_selected ? {io_address[2:0], !io_wr} : 4'b0110;

    always @(negedge io_clk) begin
        case (io_address[12:10])
            0: begin
                if (io_wr == 0)
                    ram[io_address[8:0]] <= io_data_in;
                else
                    io_data_out <= ram[io_address[8:0]];
            end
            1: io_data_out <= characters_rom[io_address[8:0]];
            2: begin
                if (io_wr == 0)
                    {scl, sda} <= io_data_in[1:0];
                else
                    io_data_out <= {14'b0, scl_io, sda_io};
            end
            3: begin
                if (io_wr == 0)
                    ks_data <= io_data_in[7:0];
            end
            4: begin
                io_data_out <= frequency_code[15:0];
                interrupt_clear <= 1;
            end
            default: begin
                io_data_out <= {4'b0, frequency_code[27:16]};
                interrupt_clear <= 0;
            end
        endcase
    end

endmodule