module i2c
#(parameter CLK_DIVIDER = 125) // 50 MHZ clock and 400 KHz i2c
(
    input wire clk,
    input wire send,
    input wire [6:0] address,
    input wire [7:0] data1,
    input wire [7:0] data2,
    input wire [7:0] data3,
    input wire [7:0] data4,
    input wire [7:0] data5,
    input wire [7:0] data6,
    input wire [7:0] data7,
    input wire [7:0] data8,
    input wire [2:0] length,
    output reg scl = 1,
    output reg sda = 1,
    output reg busy = 0
);
    reg [$log2(CLK_DIVIDER):0] counter = 0;
    reg [3:0] byte;

    always @(posedge clk or posedge send) begin
        counter = counter + 1;
    end
endmodule

module i2c_tb;
    reg clk, send;
    wire busy, scl, dsa;

    i2c #(.CLK_DIVIDER(2)) i(.clk(clk), .send(send), .address(7'h11), .data1(8'h22), .data2(8'h33), .data4(8'h44),
                             .data5(8'h55), .data6(8'h66), .data7(8'h77), .data8(8'h88), .busy(busy), .scl(scl), .sda(sda));

    always #5 clk = ~clk;

    initial begin
        $monitor("time=%t scl=%d sda=%d busy=%d", $time, scl, dsa, busy);
        clk = 0;
        send = 0;
        #10
        send = 1;
        #1000
        $finish;
    end
endmodule
