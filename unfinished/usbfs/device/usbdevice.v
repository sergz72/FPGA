module usbdevice
#(parameter FIFO_BITS = 6)
(
    // 48 MHz clock
    input wire clk,
    input wire nreset,
    input wire dm_in,
    input wire dp_in,
    output reg [4:0] packet_start = 5'b10000,
    output reg oe = 0,
    output reg dm_out = 0,
    output reg dp_out = 1
    /*output wire fifo_empty,
    output wire [7:0] in_packet_length,
    output wire [7:0] in_packet_data
    input wire  [6:0] packet_address
    input wire packet_data_req,
    output wire packet_data_ack,
    input wire nwr,
    input wire send,
    output wire send_ack,
    input wire [7:0] out_packet_length,
    input wire [7:0] out_packet_data*/
);
    localparam MAX_PACKET_SIZE = 64;
    localparam SYNC_WORD = 8'h80;
    localparam ACK = 8'hD2;
    localparam NAK = 8'h5A;

    localparam STAGE_WAITIDLE = 0;
    localparam STAGE_WAITIDLE2 = 1;
    localparam STAGE_IDLE = 2;
    localparam STAGE_SYNC = 3;
    localparam STAGE_RECEIVE_BYTE = 4;
    localparam STAGE_DECODE_PACKET_ID = 5;
    localparam STAGE_SAVE_BYTE = 6;
    localparam STAGE_PACKET_END = 7;
    localparam STAGE_SEND_START = 8;
    localparam STAGE_SEND_BYTE = 9;
    localparam STAGE_SEND_ACK = 10;
    localparam STAGE_SEND_EOP = 11;

    reg [3:0] stage = STAGE_WAITIDLE, stage_after;
    reg [7:0] received_data;
    //reg [FIFO_BITS-1:0] packet_no;
    reg [5:0] packet_byte;
    reg [2:0] bit_no;
    reg [11:0] idle_counter;
    reg [1:0] counter;
    wire k, j, se0, se1;
    reg prev_k;
    wire [3:0] received_data_not;

    wire crc5_ok, crc16_ok, received_bit, crc5_invert, crc16_invert;
    reg crc_nreset;
    reg crc_calc_enable;
    reg [4:0] crc5;
    reg[15:0] crc16;

    wire out_token, in_token, setup_token, data0, data1, data2;

    //reg [7:0] packet_data [0:(1 << FIFO_BITS) * MAX_PACKET_SIZE - 1];
    reg [7:0] token_data [0:1];
    reg [6:0] addr;
    reg [3:0] endp;

    reg [7:0] data_to_send;

    assign k = dp_in == 1 && dm_in == 0;
    assign j = dp_in == 0 && dm_in == 1;
    assign se0 = dp_in == 0 && dm_in == 0;
    assign se1 = dp_in == 1 && dm_in == 1;

    assign received_bit = (k & prev_k) | (j & !prev_k);
    assign crc5_ok = crc5 == 5'b01100;
    assign crc16_ok = crc16 == 16'b1000000000001101;
    assign crc5_invert = received_bit ^ crc5[4];
    assign crc16_invert = received_bit ^ crc16[15];  

    assign received_data_not = {!received_data[7], !received_data[6], !received_data[5], !received_data[4]};

    assign out_token = packet_start == 5'b00001;
    assign in_token = packet_start == 5'b01001;
    assign setup_token = packet_start == 5'b01101;
    assign data0 = packet_start == 5'b00011;
    assign data1 = packet_start == 5'b01011;
    assign data2 = packet_start == 5'b00111;

    // crc5 calculator
    always @(posedge clk) begin
        if (!crc_nreset)
          crc5 <= 5'b11111;
        else if (crc_calc_enable & !se0 & !se1) begin
            crc5[4] <= crc5[3];
            crc5[3] <= crc5[2];
            crc5[2] <= crc5[1] ^ crc5_invert;
            crc5[1] <= crc5[0];
            crc5[0] <= crc5_invert;
        end
    end

    // crc16 calculator
    always @(posedge clk) begin
        if (!crc_nreset)
          crc16 <= 16'b1111111111111111;
        else if (crc_calc_enable & !se0 & !se1) begin
            crc16[15] <= crc16[14] ^ crc16_invert;
            crc16[14] <= crc16[13];
            crc16[13] <= crc16[12];
            crc16[12] <= crc16[11];
            crc16[11] <= crc16[10];
            crc16[10] <= crc16[9];
            crc16[9] <= crc16[8];
            crc16[8] <= crc16[7];
            crc16[7] <= crc16[6];
            crc16[6] <= crc16[5];
            crc16[5] <= crc16[4];
            crc16[4] <= crc16[3];
            crc16[3] <= crc16[2];
            crc16[2] <= crc16[1] ^ crc16_invert;
            crc16[1] <= crc16[0];
            crc16[0] <= crc16_invert;
        end
    end

    always @(posedge clk) begin
        if (!nreset) begin
            stage <= STAGE_WAITIDLE;
            oe <= 0;
            dp_out <= 1;
            dm_out <= 0;
            idle_counter <= 0;
            counter <= 0;
            packet_start <= 5'b10000;
            bit_no <= 0;
            //packet_no <= 0;
            crc_nreset <= 0;
        end
        else begin
            if (stage == STAGE_IDLE)
                counter <= 0;
            else
                counter <= counter + 1;

            case (stage)
                STAGE_WAITIDLE: begin
                    packet_start <= 5'b10000; // no packet
                    if (k) begin
                        idle_counter <= idle_counter + 1;
                        if (idle_counter == 2048) begin
                            stage <= STAGE_IDLE;
                            idle_counter <= 0;
                        end
                    end
                    else
                        idle_counter <= 0;
                end
                STAGE_WAITIDLE2: begin
                    if (k)
                        stage <= STAGE_IDLE;
                end
                STAGE_IDLE: begin
                    if (j) begin
                        stage_after <= STAGE_SYNC;
                        stage <= STAGE_RECEIVE_BYTE;
                        received_data <= 0;
                        prev_k <= 1;
                    end
                end
                STAGE_SYNC: begin
                    if (received_data == SYNC_WORD) begin
                        stage <= STAGE_RECEIVE_BYTE;
                        stage_after <= STAGE_DECODE_PACKET_ID;
                        received_data <= 0;
                    end
                    else
                        stage <= STAGE_WAITIDLE;
                end
                STAGE_DECODE_PACKET_ID: begin
                    if (received_data_not == received_data[3:0]) begin
                        packet_start <= {1'b0, received_data[3:0]};
                        stage <= STAGE_RECEIVE_BYTE;
                        stage_after <= STAGE_SAVE_BYTE;
                        received_data <= 0;
                        packet_byte <= 0;
                        crc_nreset <= 1;
                    end
                    else
                        stage <= STAGE_WAITIDLE;
                end
                STAGE_RECEIVE_BYTE: begin
                    crc_calc_enable <= counter == 0;
                    if (counter == 1) begin
                        if (se1)
                            stage <= STAGE_WAITIDLE;
                        else if (se0)
                            stage <= stage_after == STAGE_SYNC ? STAGE_WAITIDLE : STAGE_PACKET_END;
                        else begin
                            received_data[bit_no] <= received_bit;
                            if (bit_no == 7)
                                stage <= stage_after;
                            bit_no <= bit_no + 1;
                            prev_k <= k;
                        end
                    end
                end
                STAGE_SAVE_BYTE: begin
                    if (setup_token | out_token | in_token)
                        token_data[packet_byte[0]] <= received_data;
                    //packet_data[{packet_no, packet_byte}] <= received_data;
                    packet_byte <= packet_byte + 1;
                    received_data <= 0;
                    stage <= STAGE_RECEIVE_BYTE;
                end
                STAGE_PACKET_END: begin
                    if (crc5_ok & setup_token) begin
                        case (1'b1)
                            setup_token: begin // SETUP
                              addr <= token_data[0][6:0];
                              endp <= {token_data[0][7], token_data[1][2:0]};
                            end
                        endcase
                        stage_after <= STAGE_SEND_ACK;
                        stage <= STAGE_SEND_START;
                    end
                    else
                        stage <= STAGE_WAITIDLE2;
                    crc_nreset <= 0;
                    //packet_no <= packet_no + 1;
                end
                STAGE_SEND_START: begin
                    if (k) begin
                        idle_counter <= idle_counter + 1;
                        if (idle_counter == 16) begin
                            oe <= 1;
                            data_to_send <= 8'h80;
                            stage <= STAGE_SEND_BYTE;
                            idle_counter <= 0;
                        end
                    end
                    else
                        idle_counter <= 0;
                end
                STAGE_SEND_BYTE: begin
                    if (counter == 0) begin
                        if (!data_to_send[bit_no]) begin
                            dp_out <= !dp_out;
                            dm_out <= !dm_out;
                        end
                        if (bit_no == 7)
                            stage <= stage_after;
                        bit_no <= bit_no + 1;
                    end
                end
                STAGE_SEND_ACK: begin
                    stage_after <= STAGE_SEND_EOP;
                    data_to_send <= ACK;
                    stage <= STAGE_SEND_BYTE;
                end
                STAGE_SEND_EOP: begin
                    if (counter == 0) begin
                        if (idle_counter == 2) begin
                            oe <= 0;
                            dp_out <= 1;
                            stage <= STAGE_WAITIDLE2;
                        end
                        else begin
                            dm_out <= 0;
                            dp_out <= 0;
                            idle_counter <= idle_counter + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
