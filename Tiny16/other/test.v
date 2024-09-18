module test
(
  input wire clk,
  input wire wr,
  input wire [1:0] address_rd,
  input wire [1:0] address_rd2,
  input wire [1:0] address_rd3,
  input wire [1:0] address_wr,
  input wire [15:0] data_in,
  output reg [15:0] data_out,
  output reg [15:0] data_out2,
  output reg [15:0] data_out3
);

    reg [15:0] registers [0:3];

    always @(posedge clk) begin
        if (wr == 0)
            registers[address_wr] <= data_in;
			data_out <= registers[address_rd];
			data_out2 <= registers[address_rd2];
			data_out3 <= registers[address_rd3];
    end

endmodule