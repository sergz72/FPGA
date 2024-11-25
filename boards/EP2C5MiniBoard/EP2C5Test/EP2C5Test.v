module EP2C5Test
(
	input wire clk,
	output wire led1,
	output wire led2,
	output wire led3
);
	reg [26:0] counter = 0;
	
	assign led1 = counter[26];
	assign led2 = counter[25];
	assign led3 = counter[24];
	
	always @(posedge clk) begin
		counter <= counter + 1;
	end
	
endmodule
