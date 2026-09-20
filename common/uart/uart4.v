module uart4
#(parameter CLOCK_DIV = 234, CLOCK_COUNTER_BITS = 8) // 27 MHz clk, 115200 baud
(
    input wire clk,
    output wire tx,
    input wire [31:0] data,
    input wire send,
    output reg busy = 0
);
    reg [CLOCK_COUNTER_BITS - 1:0] counter;
    reg [5:0] bit_counter;
    reg [43:0] data_out = {44{1'h1}};

    assign tx = data_out[0];

    always @(posedge clk) begin
        if (send == 1) begin
            bit_counter <= 6'd44;
            data_out <= {1'b1, data[7:0], 3'b011, data[23:16], 3'b011, data[15:8], 3'b011, data[7:0], 2'b01};
            busy <= 1;
            counter <= 0;
        end
        else if (bit_counter != 0) begin
            if (counter == CLOCK_DIV - 1) begin
                counter <= 0;
                data_out <= {1'b1, data_out[42:1]};
                bit_counter = bit_counter - 1;
            end
            else
                counter <= counter + 1;
        end
        else
            busy <= 0;
    end
endmodule

module uart4_tb;
    reg clk;
    wire tx;
    reg [31:0] data;
    reg send;
    wire busy;

    uart4 #(.CLOCK_DIV(4), .CLOCK_COUNTER_BITS(2)) u(.clk(clk), .tx(tx), .data(data), .send(send), .busy(busy));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("uart4_tb.vcd");
        $dumpvars(0, uart4_tb);
        $monitor("time=%t tx=%d busy=%d", $time, tx, busy);
        clk = 0;
        data <= 32'h11223344;
        send = 0;
        #5
        send = 1;
        #5
        send = 0;
        #500
        data <= 32'h55667788;
        send = 1;
        #5
        send = 0;
        #500
        $finish;
    end
endmodule