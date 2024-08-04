module i2c_slave
(
    input wire sda_in,
    output wire sda_out,
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
    reg stop = 0;
    reg [5:0] bit_count;
    reg [7:0] in_address = 0;
    reg ack = 1;
    reg send_ack = 1;
    reg sda_out_reg = 1;
    reg [7:0] rd_data_reg;
    reg post_start = 0;

    assign sda_out = ack & sda_out_reg;
    assign address_match = address != in_address[7:1];

    always @(negedge sda_in or posedge stop) begin
        if (stop == 1)
            start <= 0;
        else if (scl == 1)
            start <= 1;
    end

    always @(posedge sda_in or posedge start) begin
        if (sda_in == 0) // posedge start
            stop <= 0;
        else if (scl == 1)
            stop <= 1;
    end

    always @(negedge scl or posedge stop) begin
        ack <= send_ack;
        if (stop == 1)
            sda_out_reg <= 1;
        else if (start == 1 && address_match == 0) begin
            case (bit_count)
                0: rd_data_reg <= rd_data0;
                9,10,11,12,13,14,15,16,
                18,19,20,21,22,23,24,25,
                27,28,29,30,31,32,33,34,
                36,37,38,39,40,41,42,43,
                45,46,47,48,49,50,51.52: begin
                    sda_out_reg <= rd_data_reg[7];
                    rd_data_reg <= {rd_data_reg[6:0], 1'b0};
                end
                17: begin
                    sda_out_reg <= 1;
                    rd_data_reg <= rd_data1;
                end
                26: begin
                    sda_out_reg <= 1;
                    rd_data_reg <= rd_data2;
                end
                35: begin
                    sda_out_reg <= 1;
                    rd_data_reg <= rd_data3;
                end
                44: begin
                    sda_out_reg <= 1;
                    rd_data_reg <= rd_data3;
                end
                53: sda_out_reg <= 1;
            endcase
        end
    end

    always @(posedge scl or posedge start or posedge stop) begin
        if (stop == 1) begin
            send_ack <= 1;
            post_start <= 0;
        end
        else if (start == 1) begin
            if (post_start == 0) begin
                bit_count <= 0;
                in_address <= 0;
                post_start <= 1;
            end
            else begin
                case (bit_count)
                    0,1,2,3,4,5,6: in_address <= {in_address[6:0], sda_in};
                    7: begin
                        in_address <= {in_address[6:0], sda_in};
                        send_ack <= address_match;
                    end
                    8: send_ack <= 1;
                    default:
                    if (in_address[0] == 0 && address_match == 0) begin // write
                        case (bit_count)
                            9,10,11,12,13,14,15: wr_data0 <= {wr_data0[6:0], sda_in};
                            16: begin
                                wr_data0 <= {wr_data0[6:0], sda_in};
                                send_ack <= 0;
                            end
                            17: send_ack <= 1;
                            18,19,20,21,22,23,24: wr_data1 <= {wr_data1[6:0], sda_in};
                            25: begin
                                wr_data1 <= {wr_data1[6:0], sda_in};
                                send_ack <= 0;
                            end
                            26: send_ack <= 1;
                            27,28,29,30,31,32,33: wr_data2 <= {wr_data2[6:0], sda_in};
                            34: begin
                                wr_data2 <= {wr_data2[6:0], sda_in};
                                send_ack <= 0;
                            end
                            35: send_ack <= 1;
                            36,37,38,39,40,41,42: wr_data3 <= {wr_data3[6:0], sda_in};
                            43: begin
                                wr_data3 <= {wr_data3[6:0], sda_in};
                                send_ack <= 0;
                            end
                            44: send_ack <= 1;
                            45,46,47,48,49,50,51: wr_data4 <= {wr_data4[6:0], sda_in};
                            52: begin
                                wr_data4 <= {wr_data4[6:0], sda_in};
                                send_ack <= 0;
                            end
                            53: send_ack <= 1;
                        endcase
                    end
                endcase
                bit_count <= bit_count + 1;
            end
        end
    end

endmodule

module i2c_slave_tb;
    reg scl, sda_in;
    wire sda_out;
    reg [6:0] address;
    reg [7:0] rd_data0, rd_data1, rd_data2, rd_data3, rd_data4;
    wire [7:0] wr_data0, wr_data1, wr_data2, wr_data3, wr_data4;
    wire start, address_match;

    i2c_slave s(.scl, .sda_in, .sda_out, .address, .start, .address_match, .rd_data0, .rd_data1, .rd_data2, .rd_data3, .rd_data4,
                .wr_data0, .wr_data1, .wr_data2, .wr_data3, .wr_data4);

    initial begin
        $dumpfile("i2c_slave_tb.vcd");
        $dumpvars(0, i2c_slave_tb);
        $monitor("time=%t scl=%d sda_in=%d sda_out=%d start=%d address_match=%d wr_data0=0x%h wr_data1=0x%h wr_data2=0x%h wr_data3=0x%h wr_data4=0x%h",
                 $time, scl, sda_in, sda_out, start, address_match, wr_data0, wr_data1, wr_data2, wr_data3, wr_data4);
        sda_in = 1;
        scl = 1;
        address = 'h55;
        #1
        sda_in = 0;
        #1
        scl = 0; // start, bit 7
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 6
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 5
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 4
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 3
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 2
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 1
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 0, write
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // ack
        sda_in = 1;
        #1
        scl = 1;


        #1
        scl = 0; // start, bit 7
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 6
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 5
        sda_in = 1;        #1
        scl = 0; // start, bit 7
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 6
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 5
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 4
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 3
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 2
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 1
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 0, write
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // ack
        sda_in = 1;
        #1
        scl = 1;

        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 3
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 2
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // bit 1
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // bit 0
        sda_in = 0;
        #1
        scl = 1;

        #1
        scl = 0; // ack
        sda_in = 1;
        #1
        scl = 1;

        #1
        scl = 0; // stop 
        sda_in = 0;
        #1
        scl = 1;
        #1
        sda_in = 1;
        #10

        $finish;
    end
endmodule
