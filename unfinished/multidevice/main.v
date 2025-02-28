module main
#(parameter MCLK = 64'd270000000)
(
    input wire clk,
    input wire clk_dds,
    input wire sck,
    input wire mosi,
    input wire ncs,
    output wire miso,
    output reg interrupt = 0,
    output wire out
);
    localparam COMMAND_LENGTH = 15 * 8;
    localparam ID = 8'h1; // dds
    localparam TYPE = 16'd3; //ad9850
    localparam LEVEL_METER_TYPE = 16'h0;
    localparam MAX_MV = 16'd3300;
    localparam MAX_ATTENUATOR = 8'h0;
    localparam SET_FREQUENCY_COMMAND_LENGTH = 13 * 8;

    reg [31:0] dds_code = 0;
    reg[COMMAND_LENGTH - 1:0] command = 0;
    reg[COMMAND_LENGTH - 1:0] response = 0;
    reg[7:0] cnt = 0;
    reg prev_sck = 0;
    reg prev_ncs = 1;

    assign miso = ncs ? 1'bz : response[COMMAND_LENGTH - 1];

    dds dds_instance(.clk(clk_dds), .code(dds_code), .out(out));

    always @(posedge clk) begin
        if (ncs && !prev_ncs) begin
            case (cnt)
                8: begin
                    case (command[7:0])
                        0: begin// get id
                            response <= {ID, {COMMAND_LENGTH-8{1'b0}}};
                        end
                        1: begin // get config
                            response <= {
                                TYPE[7:0], TYPE[15:8],
                                LEVEL_METER_TYPE[7:0], LEVEL_METER_TYPE[15:8],
                                MCLK[7:0], MCLK[15:8], MCLK[23:16], MCLK[31:24], MCLK[39:32], MCLK[47:40], MCLK[55:48], MCLK[63:56],
                                MAX_MV[7:0], MAX_MV[15:8],
                                MAX_ATTENUATOR};
                        end
                        2: begin // get status
                            response <= {COMMAND_LENGTH{1'b0}};
                        end
                    endcase
                end
                SET_FREQUENCY_COMMAND_LENGTH: begin
                    response <= {COMMAND_LENGTH{1'b0}};
                    if (command[SET_FREQUENCY_COMMAND_LENGTH - 1: SET_FREQUENCY_COMMAND_LENGTH - 8] == 3 && // dds_command
                        command[SET_FREQUENCY_COMMAND_LENGTH - 9: SET_FREQUENCY_COMMAND_LENGTH - 16] == 2) begin // set frequency code
                        dds_code <= {command[55:48], command[63:56], command[71:64], command[79:72]};
                    end
                end
            endcase
            cnt <= 0;
        end
        else if (sck && !prev_sck && !ncs) begin
            command <= {command[COMMAND_LENGTH - 2:0], mosi};
            response <= {response[COMMAND_LENGTH - 2:0], 1'b0};
            cnt <= cnt + 1;
        end
        prev_sck <= sck;
        prev_ncs <= ncs;
    end

endmodule
