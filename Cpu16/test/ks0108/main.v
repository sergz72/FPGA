module main
(
    input wire clk,
    input wire reset,
    input wire interrupt,
    output wire hlt,
    output wire error,
    output wire scl,
    output wire sda,
    input wire scl_in,
    input wire sda_in
);
    wire [15:0] address;
    reg [31:0] data;
    wire rd;

    wire io_rd;
    wire io_wr;
    wire i2c_rd;
    wire i2c_wr;
    wire [15:0] io_data_in;
    wire [15:0] io_address;
    reg [15:0] io_data_out;
    wire [15:0] io_data_out2;
	wire io_clk;
    wire [15:0] io_data_sel;

    reg [31:0] rom [0:1023];

    reg [16:0] ram [0:511];

    reg [16:0] characters_rom [0:511];

    initial begin
        $readmemh("asm/a.out", rom);
        $readmemh("characters.mem", characters_rom);
    end

	assign io_clk = io_rd & io_wr;

    cpu cpu16(.clk(clk), .rd(rd), .reset(reset), .address(address), .data(data), .hlt(hlt), .io_rd(io_rd),
                 .io_wr(io_wr), .io_data_out(io_data_in), .io_data_in(io_data_sel), .io_address(io_address), .error(error), .interrupt(interrupt));

    i2c #(.CLK_DIVIDER_BITS(8)) i(.clk(clk), .wr(i2c_wr), .rd(i2c_rd), .address(io_address[3:0]), .data_in(io_data_in), .data_out(io_data_out2), .scl(scl), .sda(sda),
            .scl_in(scl_in), .sda_in(sda_in));

    function [15:0] f_io_data_sel(input [1:0] source);
        case (source)
            0,1: f_io_data_sel = io_data_out;
            default: f_io_data_sel = io_data_out2;
        endcase
    endfunction

    assign io_data_sel = f_io_data_sel(io_address[10:9]);
    assign i2c_wr = io_address[10:9] == 2 ? io_wr : 1;
    assign i2c_rd = io_address[10:9] == 2 ? io_rd : 1;

    always @(negedge rd) begin
        data <= rom[address[9:0]];
    end

    always @(negedge io_clk) begin
        case (io_address[10:9])
            0: begin
                if (io_wr == 0)
                    ram[io_address[8:0]] <= io_data_in;
                else
                    io_data_out <= ram[io_address[8:0]];
            end
            1: io_data_out <= characters_rom[io_address[8:0]];
        endcase
    end

endmodule
