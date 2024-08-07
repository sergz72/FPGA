module i2c
#(parameter CLK_DIVIDER = 250) // 50 MHZ clock and 100 KHz i2c
(
    input wire clk,
    input wire wr,
    input wire rd,
    input wire [3:0] address,
    inout wire [7:0] data,
    output reg scl = 1,
    output reg sda = 1,
    input wire scl_in,
    input wire sda_in
);
    localparam CLK_DIVIDER_BITS = $log2(CLK_DIVIDER) + 1;
    localparam START_SDA = 0;
    localparam START_SCL = 1;

    reg [CLK_DIVIDER_BITS - 1:0] counter = 0;
    reg [7:0] wr_data_mem [0:15];
    reg [7:0] rd_data_mem [0:15];
    reg [7:0] rd_data;
    reg busy = 0;
    reg nack = 0;
    reg [3:0] wr_length;
    reg [3:0] rd_length;
    reg [3:0] stage;

    assign data = rd == 0 ? rd_data : 8'bzzzzzzzz;

    always @(posedge clk) begin
        if (busy == 0) begin
            counter <= 0;
            stage <= START_SDA;
            sda <= 1;
            scl <= 1;
            if (wr == 0) begin
                if (address < 15)
                    wr_data_mem[address] <= data;
                else begin
                    wr_length <= data[3:0] + 1;
                    rd_length <= data[7:4];
                    busy <= 1;
                end
            end
            else if (rd == 0) begin
                if (address < 15)
                    rd_data <= rd_data_mem[address];
                else
                    rd_data <= {6'b000000, nack, busy};
            end
        end
        else begin
            if (counter == 0) begin
                case (stage)
                    START_SDA: begin
                        sda <= 0;
                        stage <= START_SCL;
                    end
                    START_SCL: begin
                        scl <= 0;
                        stage <= START_SCL;
                    end
                endcase
            end
            counter <= counter + 1;
        end
    end
endmodule

module i2c_tb;
    reg clk, wr, rd;
    wire scl, dsa;
    reg [3:0] address;
    reg [7:0] data_out;
    wire data;

    assign data = wr ? 8'bzzzzzzzz : data_out;

    i2c #(.CLK_DIVIDER(2)) i(.clk(clk), .wr(wr), .rd(rd), .address(address), .data(data), .scl(scl), .sda(sda));

    always #1 clk = ~clk;

    initial begin
        $monitor("time=%t scl=%d sda=%d", $time, scl, sda);
        clk = 0;
        wr = 1;
        rd = 1;
        address = 0;
        data_out = 8'h22;
        #10
        wr = 0;
        #10
        wr = 1;
        address = 1;
        data_out = 8'h11;
        #10
        wr = 0;
        #10
        wr = 1;
        address = 2;
        data_out = 8'h33;
        #10
        wr = 0;
        #10
        wr = 1;
        address = 15;
        data_out = 8'h20;
        #10
        wr = 0;
        #10
        wr = 1;
        #10000
        $finish;
    end
endmodule
