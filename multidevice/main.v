module main
#(parameter MCLK = 64'd270000000)
(
    input wire clk,
    input wire clk_dds,
    input wire nreset,
    input wire sck,
    input wire mosi,
    input wire ncs,
    output wire miso,
    output reg interrupt = 0,
    output wire [3:0] out
);
    localparam COMMAND_LENGTH = 15 * 8;
    localparam ID1 = 8'h1; // dds
    localparam ID2 = 8'h0;
    localparam ID3 = 8'h0;
    localparam ID4 = 8'h0;
    localparam DDS_TYPE = 16'd6; //ad9959
    localparam LEVEL_METER_TYPE = 16'h0;
    localparam MAX_MV = 16'd3300;
    localparam MAX_ATTENUATOR = 8'h0;
    localparam SET_FREQUENCY_COMMAND_LENGTH = 14 * 8;
    localparam OUTPUT_ENABLE_COMMAND_LENGTH = 5 * 8;

    reg [31:0] dds_code [0:3];
    reg [31:0] dds_code_bak [0:3];
    reg[COMMAND_LENGTH - 1:0] command = 0;
    reg[COMMAND_LENGTH - 1:0] response = 0;
    reg[7:0] cnt = 0;
    reg prev_sck = 0;
    reg prev_ncs = 1;
    reg rsck = 0;
    reg rncs = 1;
    reg [3:0] output_enabled = 0;

    wire [1:0] dds_channel;
    wire [1:0] enable_channel;
    wire enable;

    assign miso = ncs ? 1'bz : response[COMMAND_LENGTH - 1];
    assign dds_channel = command[SET_FREQUENCY_COMMAND_LENGTH - 31: SET_FREQUENCY_COMMAND_LENGTH - 32];
    assign enable_channel = command[9:8];
    assign enable = command[7:0] != 0;

    dds dds_instance1(.clk(clk_dds), .code(dds_code[0]), .out(out[0]));
    dds dds_instance2(.clk(clk_dds), .code(dds_code[1]), .out(out[1]));
    dds dds_instance3(.clk(clk_dds), .code(dds_code[2]), .out(out[2]));
    dds dds_instance4(.clk(clk_dds), .code(dds_code[3]), .out(out[3]));

    always @(posedge clk) begin
        if (!nreset) begin
            cnt <= 0;
            command <= 0;
            response <= 0;
            output_enabled <= 0;
            dds_code[0] <= 0;
            dds_code[1] <= 0;
            dds_code[2] <= 0;
            dds_code[3] <= 0;
            dds_code_bak[0] <= 0;
            dds_code_bak[1] <= 0;
            dds_code_bak[2] <= 0;
            dds_code_bak[3] <= 0;
        end
        else if (rncs) begin
            if (!prev_ncs) begin
                case (cnt)
                    16: begin
                        case (command[7:0])
                            0: begin// get id
                                response <= {ID1, ID2, ID3, ID4, {COMMAND_LENGTH-32{1'b0}}};
                            end
                            1: begin // get config
                                case (command[15:8]) // subdevice_id
                                    0: response <= {
                                            DDS_TYPE[7:0], DDS_TYPE[15:8],
                                            LEVEL_METER_TYPE[7:0], LEVEL_METER_TYPE[15:8],
                                            MCLK[7:0], MCLK[15:8], MCLK[23:16], MCLK[31:24], MCLK[39:32], MCLK[47:40], MCLK[55:48], MCLK[63:56],
                                            MAX_MV[7:0], MAX_MV[15:8],
                                            MAX_ATTENUATOR};
                                    default:
                                        response <= {COMMAND_LENGTH{1'b0}};
                                endcase
                            end
                            2: begin // get status
                                response <= {COMMAND_LENGTH{1'b0}};
                            end
                        endcase
                    end
                    OUTPUT_ENABLE_COMMAND_LENGTH: begin
                        response <= {COMMAND_LENGTH{1'b0}};
                        if (command[OUTPUT_ENABLE_COMMAND_LENGTH - 9: OUTPUT_ENABLE_COMMAND_LENGTH - 16] == 3 && // dds_command
                            command[OUTPUT_ENABLE_COMMAND_LENGTH - 17: OUTPUT_ENABLE_COMMAND_LENGTH - 24] == 5) begin // enable_output
                            output_enabled[enable_channel] <= enable;
                            dds_code[enable_channel] <= enable ? dds_code_bak[enable_channel] : 32'h0;
                        end
                    end
                    SET_FREQUENCY_COMMAND_LENGTH: begin
                        response <= {COMMAND_LENGTH{1'b0}};
                        if (command[SET_FREQUENCY_COMMAND_LENGTH - 9: SET_FREQUENCY_COMMAND_LENGTH - 16] == 3 && // dds_command
                            command[SET_FREQUENCY_COMMAND_LENGTH - 17: SET_FREQUENCY_COMMAND_LENGTH - 24] == 2) begin // set frequency code
                            dds_code_bak[dds_channel] <= {command[55:48], command[63:56], command[71:64], command[79:72]};
                            if (output_enabled[dds_channel])
                                dds_code[dds_channel] <= {command[55:48], command[63:56], command[71:64], command[79:72]};
                        end
                    end
                endcase
                cnt <= 0;
            end
        end
        else begin
            case (1'b1)
                rsck & !prev_sck: begin
                    command <= {command[COMMAND_LENGTH - 2:0], mosi};
                    cnt <= cnt + 1;
                end
                !rsck & prev_sck: begin
                    response <= {response[COMMAND_LENGTH - 2:0], 1'b0};
                end
            endcase
        end
    end

    always @(negedge clk) begin
        prev_sck <= rsck;
        prev_ncs <= rncs;
        rsck <= sck;
        rncs <= ncs;
    end

endmodule
