module i2c_slave
(
    input wire clk,
    input wire reset,
    input wire sda_in,
    output reg sda_out = 1,
    input wire scl,
    input wire [6:0] address,
    output wire address_match,
    output reg start = 0,
    output reg [7:0] wr_data0,
    output reg [7:0] wr_data1,
    output reg [7:0] wr_data2,
    output reg [7:0] wr_data3,
    output reg [7:0] wr_data4,
    input wire [7:0] rd_data0,
    input wire [7:0] rd_data1,
    input wire [7:0] rd_data2,
    input wire [7:0] rd_data3,
    input wire [7:0] rd_data4
);
    reg [5:0] bit_count;
    reg [7:0] in_address = 0;
    reg [7:0] rd_data_reg;
    reg prev_sda = 1;
    reg prev_scl = 1;

    assign address_match = address == in_address[7:1];

    always @(posedge clk) begin
        if (reset == 0) begin
            sda_out <= 1;
            start <= 0;
            in_address <= 0;
        end
        else begin
            if (prev_sda != sda_in && scl == 1) begin
                start <= prev_sda;
                bit_count <= 0;
                sda_out <= 1;
                if (prev_sda)
                    in_address <= 0;
            end
            else if (start == 1 && prev_scl != scl) begin
                if (scl == 1) begin // posedge scl
                    case (bit_count)
                        0,1,2,3,4,5,6,7: in_address <= {in_address[6:0], sda_in};
                        8: begin end
                        default:
                            if (in_address[0] == 0 && address_match == 1) begin // write
                                case (bit_count)
                                    9,10,11,12,13,14,15,16: wr_data0 <= {wr_data0[6:0], sda_in};
                                    18,19,20,21,22,23,24,25: wr_data1 <= {wr_data1[6:0], sda_in};
                                    27,28,29,30,31,32,33,34: wr_data2 <= {wr_data2[6:0], sda_in};
                                    36,37,38,39,40,41,42,43: wr_data3 <= {wr_data3[6:0], sda_in};
                                    45,46,47,48,49,50,51,52: wr_data4 <= {wr_data4[6:0], sda_in};
                                endcase
                            end
                    endcase
                    bit_count <= bit_count + 1;
                end
                else begin // negedge scl
                    if (address_match == 1) begin
                        if (in_address[0] == 0) begin // write
                            case (bit_count)
                                8,17,26,35,44,53: sda_out <= !address_match;
                                default:
                                    sda_out <= 1;
                            endcase
                        end
                        else begin // read
                            case (bit_count)
                                0: rd_data_reg <= rd_data0;
                                9,10,11,12,13,14,15,16,
                                18,19,20,21,22,23,24,25,
                                27,28,29,30,31,32,33,34,
                                36,37,38,39,40,41,42,43,
                                45,46,47,48,49,50,51.52: begin
                                    sda_out <= rd_data_reg[7];
                                    rd_data_reg <= {rd_data_reg[6:0], 1'b0};
                                end
                                17: begin
                                    sda_out <= 1;
                                    rd_data_reg <= rd_data1;
                                end
                                26: begin
                                    sda_out <= 1;
                                    rd_data_reg <= rd_data2;
                                end
                                35: begin
                                    sda_out <= 1;
                                    rd_data_reg <= rd_data3;
                                end
                                44: begin
                                    sda_out <= 1;
                                    rd_data_reg <= rd_data4;
                                end
                                53: sda_out <= 1;
                            endcase
                        end
                    end
                end
            end
        end
        prev_scl <= scl;
        prev_sda <= sda_in;
    end

endmodule

module i2c_slave_tb;
    reg clk, scl, sda_in, reset;
    wire sda_out;
    reg [6:0] address;
    reg [7:0] rd_data0, rd_data1, rd_data2, rd_data3, rd_data4;
    wire [7:0] wr_data0, wr_data1, wr_data2, wr_data3, wr_data4;
    wire start, address_match;

    i2c_slave s(.clk(clk), .reset(reset), .scl(scl), .sda_in(sda_in), .sda_out(sda_out), .address(address), .start(start),
                .address_match(address_match), .rd_data0(rd_data0), .rd_data1(rd_data1), .rd_data2(rd_data2),
                .rd_data3(rd_data3), .rd_data4(rd_data4), .wr_data0(wr_data0), .wr_data1(wr_data1),
                .wr_data2(wr_data2), .wr_data3(wr_data3), .wr_data4(wr_data4));

    always #1 clk = ~clk;

    initial begin
        $dumpfile("i2c_slave_tb.vcd");
        $dumpvars(0, i2c_slave_tb);
        $monitor("time=%t reset=%d scl=%d sda_in=%d sda_out=%d start=%d address_match=%d wr_data0=0x%h wr_data1=0x%h wr_data2=0x%h wr_data3=0x%h wr_data4=0x%h",
                 $time, reset, scl, sda_in, sda_out, start, address_match, wr_data0, wr_data1, wr_data2, wr_data3, wr_data4);
        sda_in = 1;
        scl = 1;
        clk = 1;
        reset = 0;
        address = 'h55;
        #10
        reset = 1;
        #10
        sda_in = 0;
        #10
        scl = 0; // start, bit 7
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 6
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 5
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 4
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 3
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 2
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 1
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 0, write
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // ack
        sda_in = 1;
        #10
        scl = 1;


        #10
        scl = 0; // bit 7
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 6
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 5
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 4
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 3
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 2
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 1
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 0
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // ack
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 7
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 6
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 5
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 4
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 3
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 2
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // bit 1
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // bit 0
        sda_in = 0;
        #10
        scl = 1;

        #10
        scl = 0; // ack
        sda_in = 1;
        #10
        scl = 1;

        #10
        scl = 0; // stop 
        sda_in = 0;
        #10
        scl = 1;
        #10
        sda_in = 1;
        #100

        $finish;
    end
endmodule
