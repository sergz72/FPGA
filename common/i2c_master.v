module i2c
#(parameter CLK_DIVIDER_BITS = 8) // 50 MHZ clock and 100 KHz i2c
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
    localparam START_SDA = 0;
    localparam START_SCL = 1;
    localparam WR1 = 2;
    localparam WR2 = 3;
    localparam WR3 = 4;
    localparam ACK1 = 5;
    localparam ACK2 = 6;
    localparam RESTART1 = 7;
    localparam RESTART2 = 8;
    localparam RESTART3 = 9;
    localparam STOP1 = 10;
    localparam STOP2 = 11;
    localparam RD1 = 12;
    localparam RD2 = 13;

    reg [CLK_DIVIDER_BITS - 1:0] counter = 0;
    reg [7:0] wr_data_mem [0:15];
    reg [7:0] rd_data_mem [0:15];
    reg [7:0] rd_data;
    reg [7:0] current_byte;
    reg [3:0] bit_count;
    reg [3:0] pointer;
    reg busy = 0;
    reg nack = 0;
    reg [3:0] wr_length;
    reg [3:0] rd_length;
    reg [3:0] stage;
    wire read, restart;

    assign data = rd == 0 ? rd_data : 8'bzzzzzzzz;
    assign read = pointer == wr_length && rd_length != 0;
    assign restart = wr_length > 1 && read;

    always @(posedge clk) begin
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
        if (busy == 0) begin
            counter <= 0;
            stage <= START_SDA;
            sda <= 1;
            scl <= 1;
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
                        pointer <= 0;
                        current_byte <= wr_data_mem[0];
                        bit_count <= 0;
                        stage <= WR1;
                    end
                    WR1: begin
                        sda <= current_byte[7];
                        current_byte <= {current_byte[6:0], 1'b0};
                        if (bit_count == 7) begin
                            bit_count <= 0;
                            pointer <= pointer + 1;
                            stage <= ACK1;
                        end
                        else begin
                            bit_count <= bit_count + 1;
                            stage <= WR2;
                        end
                    end
                    WR2: begin
                        scl <= 1;
                        stage <= WR3;
                    end
                    WR3: begin
                        scl <= 0;
                        stage <= WR1;
                    end
                    ACK1: begin
                        scl <= 1;
                        sda <= 1;
                        stage <= ACK2;
                    end
                    ACK2: begin
                        if (scl_in == 1) begin // Clock Stretching 
                            scl <= 0;
                            nack = sda_in == 1;
                            if (nack) begin
                                stage <= STOP1;
                                sda <= 0;
                            end
                            else if (restart) begin
                                stage <= RESTART1;
                                sda <= 1;
                            end
                            else if (read)
                                stage <= RD1;
                            else begin
                                current_byte <= wr_data_mem[pointer];
                                stage <= WR1;
                            end
                        end
                    end
                    STOP2: begin
                        sda <= 1;
                        busy <= 0;
                    end
                    RESTART1: begin
                        scl <= 1;
                        stage <= RESTART2;
                    end
                    RESTART2: begin
                        sda <= 0;
                        stage <= RESTART3;
                    end
                    RESTART3: begin
                        scl <= 0;
                        stage <= RD1;
                    end
                    RD1: begin
                        scl <= 1;
                        stage <= RD2;
                    end
                    RD2: begin
                        scl <= 0;
                        stage <= RD2;
                    end
                    // includes STOP1
                    default: begin
                        scl <= 1;
                        stage <= STOP2;
                    end
                endcase
            end
            counter <= counter + 1;
        end
    end
endmodule

module i2c_master_tb;
    reg clk, wr, rd, scl_in, sda_in;
    wire scl, dsa;
    reg [3:0] address;
    reg [7:0] data_out;
    wire [7:0] data;

    assign data = wr ? 8'bzzzzzzzz : data_out;

    i2c #(.CLK_DIVIDER_BITS(2)) i(.clk(clk), .wr(wr), .rd(rd), .address(address), .data(data), .scl(scl), .sda(sda),
            .scl_in(scl_in), .sda_in(sda_in));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("i2c_master_tb.vcd");
        $dumpvars(0, i2c_master_tb);
        $monitor("time=%t scl=%d sda=%d", $time, scl, sda);
        clk = 0;
        wr = 1;
        rd = 1;
        scl_in = 1;
        sda_in = 1;
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
