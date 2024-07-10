module main
(
    wire clk,
    wire reset,
    wire hlt,
    wire io_rd,
    wire io_wr,
    wire error,
    wire [15:0] io_data,
    wire [15:0] io_address
);
    wire rd;
    wire [15:0] address;
    reg [31:0] data;

    reg [31:0] rom [0:1024];

    initial begin
        $readmemh("asm/a.out", rom);
    end

    cpu cpu16(.clk(clk), .reset(reset), .address(address), .data(data), .rd(rd), .hlt(hlt), .io_rd(io_rd),
                 .io_wr(io_wr), .io_data(io_data), .io_address(io_address), .error(error));

    always @(negedge rd) begin
        data <= rom[address[9:0]];
    end

endmodule
