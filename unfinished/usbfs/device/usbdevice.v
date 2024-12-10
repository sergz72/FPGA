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
    output wire dm_out,
    output wire dp_out
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

    localparam STAGE_WAITIDLE = 0;
    localparam STAGE_WAITIDLE2 = 1;
    localparam STAGE_IDLE = 2;
    localparam STAGE_SYNC = 3;
    localparam STAGE_RECEIVE_BYTE = 4;
    localparam STAGE_DECODE_PACKET_ID = 5;
    localparam STAGE_SAVE_BYTE = 6;
    localparam STAGE_PACKET_END = 7;

    reg [2:0] stage = STAGE_WAITIDLE, stage_after;
    reg [7:0] received_data;
    reg [FIFO_BITS-1:0] packet_no;
    reg [5:0] packet_byte;
    reg [2:0] bit_no;
    reg [11:0] idle_counter;
    reg [1:0] counter;
    wire k, j, se0, se1;
    reg prev_k;
    wire [3:0] received_data_not;

    reg [7:0] packet_data [0:(1 << FIFO_BITS) * MAX_PACKET_SIZE - 1];

    assign k = dp_in == 1 && dm_in == 0;
    assign j = dp_in == 0 && dm_in == 1;
    assign se0 = dp_in == 0 && dm_in == 0;
    assign se1 = dp_in == 1 && dm_in == 1;

    assign received_data_not = {!received_data[7], !received_data[6], !received_data[5], !received_data[4]};

    always @(posedge clk) begin
        if (!nreset) begin
            stage <= STAGE_WAITIDLE;
            oe <= 0;
            idle_counter <= 0;
            counter <= 0;
            packet_start <= 5'b10000;
            bit_no <= 0;
            packet_no <= 0;
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
                        if (idle_counter == 2048)
                            stage <= STAGE_IDLE;
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
                    end
                    else
                        stage <= STAGE_WAITIDLE;
                end
                STAGE_RECEIVE_BYTE: begin
                    if (counter == 1) begin
                        if (se1)
                            stage <= STAGE_WAITIDLE;
                        else if (se0)
                            stage <= stage_after == STAGE_SYNC ? STAGE_WAITIDLE : STAGE_PACKET_END;
                        else begin
                            received_data[bit_no] <= (k & prev_k) | (j & !prev_k);
                            if (bit_no == 7)
                                stage <= stage_after;
                            bit_no <= bit_no + 1;
                            prev_k <= k;
                        end
                    end
                end
                STAGE_SAVE_BYTE: begin
                    packet_data[{packet_no, packet_byte}] <= received_data;
                    packet_byte <= packet_byte + 1;
                    received_data <= 0;
                    stage <= STAGE_RECEIVE_BYTE;
                end
                STAGE_PACKET_END: begin
                    packet_no <= packet_no + 1;
                    stage <= STAGE_WAITIDLE2;
                end
            endcase
        end
    end
endmodule
