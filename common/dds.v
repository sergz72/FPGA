module dds
#(parameter WIDTH = 32, OUT_WIDTH = 1)
(
    input wire clk,
    input wire [WIDTH - 1:0] code,
    output [OUT_WIDTH - 1:0] out
);
    reg [WIDTH - 1:0] counter = 0;

    assign out = counter[WIDTH - 1: WIDTH - OUT_WIDTH];
    
    always @(posedge clk) begin
        counter <= counter + code;
    end
endmodule
