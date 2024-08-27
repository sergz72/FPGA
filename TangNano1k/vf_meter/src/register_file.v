module register_file
#(parameter WIDTH = 16, SIZE = 8)
(
	input wire [SIZE - 1:0] rd_address,
	output reg [WIDTH - 1:0] rd_data,
	input wire [SIZE - 1:0] wr_address,
	input wire [WIDTH - 1:0] wr_data,
	input wire wr,
	input wire clk
);
	reg [WIDTH - 1:0] registers [0:(1 << SIZE) - 1];
	
	always @(posedge clk) begin
		if (wr == 0)
			registers[wr_address] <= wr_data;
		else
			rd_data <= registers[rd_address];
	end
endmodule

module register_file2
#(parameter WIDTH = 16, SIZE = 8)
(
	input wire [SIZE - 1:0] rd_address1,
	output reg [WIDTH - 1:0] rd_data1,
	input wire [SIZE - 1:0] rd_address2,
	output reg [WIDTH - 1:0] rd_data2,
	input wire [SIZE - 1:0] wr_address,
	input wire [WIDTH - 1:0] wr_data,
	input wire wr,
	input wire clk
);
	reg [WIDTH - 1:0] registers [0:(1 << SIZE) - 1];
	
	always @(posedge clk) begin
		if (wr == 0)
			registers[wr_address] <= wr_data;
		else begin
			rd_data1 <= registers[rd_address1];
			rd_data2 <= registers[rd_address2];
		end
	end
endmodule

module register_file3
#(parameter WIDTH = 16, SIZE = 8)
(
	input wire [SIZE - 1:0] rd_address1,
	output reg [WIDTH - 1:0] rd_data1,
	input wire [SIZE - 1:0] rd_address2,
	output reg [WIDTH - 1:0] rd_data2,
	input wire [SIZE - 1:0] rd_address3,
	output reg [WIDTH - 1:0] rd_data3,
	input wire [SIZE - 1:0] wr_address,
	input wire [WIDTH - 1:0] wr_data,
	input wire wr,
	input wire clk
);
	reg [WIDTH - 1:0] registers [0:(1 << SIZE) - 1];
	
	always @(posedge clk) begin
		if (wr == 0)
			registers[wr_address] <= wr_data;
		else begin
			rd_data1 <= registers[rd_address1];
			rd_data2 <= registers[rd_address2];
			rd_data3 <= registers[rd_address3];
		end
	end
endmodule

module register_files2
#(parameter WIDTH = 16, SIZE = 8)
(
	input wire [SIZE - 1:0] rd_address1,
	output wire [WIDTH - 1:0] rd_data1,
	input wire [SIZE - 1:0] rd_address2,
	output wire [WIDTH - 1:0] rd_data2,
	input wire [SIZE - 1:0] rd_address3,
	output wire [WIDTH - 1:0] rd_data3,
	input wire [SIZE - 2:0] wr_address1,
	input wire [WIDTH - 1:0] wr_data1,
	input wire wr1,
	input wire [SIZE - 2:0] wr_address2,
	input wire [WIDTH - 1:0] wr_data2,
	input wire wr2,
	input wire clk
);
	wire [WIDTH - 1:0] rd_data11, rd_data12, rd_data13, rd_data21, rd_data22, rd_data23;
	
	register_file3 #(.WIDTH(WIDTH), .SIZE(SIZE - 1))
		f1(.clk(clk), .rd_address1(rd_address1[SIZE - 2:0]), .rd_data1(rd_data11),
		   .rd_address2(rd_address2[SIZE - 2:0]), .rd_data2(rd_data12),
		   .rd_address3(rd_address3[SIZE - 2:0]), .rd_data3(rd_data13),
		   .wr_address(wr_address1), .wr_data(wr_data1), .wr(wr1));

	register_file3 #(.WIDTH(WIDTH), .SIZE(SIZE - 1))
		f2(.clk(clk), .rd_address1(rd_address1[SIZE - 2:0]), .rd_data1(rd_data21),
		   .rd_address2(rd_address2[SIZE - 2:0]), .rd_data2(rd_data22),
		   .rd_address3(rd_address3[SIZE - 2:0]), .rd_data3(rd_data23),
		   .wr_address(wr_address2), .wr_data(wr_data2), .wr(wr2));
			
	assign rd_data1 = rd_address1[SIZE - 1] ? rd_data21 : rd_data11;
	assign rd_data2 = rd_address2[SIZE - 1] ? rd_data22 : rd_data12;
	assign rd_data3 = rd_address3[SIZE - 1] ? rd_data23 : rd_data13;
	
endmodule
