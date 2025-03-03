module main
#(parameter MCLK_DDS = 64'd270000000, MCLK_PWM = 32'd270000000, FCLK = 27000000)
(
    input wire clk,
    input wire clk_dds,
    input wire clk_pwm,
    input wire nreset,
    input wire sck,
    input wire mosi,
    input wire ncs,
    output wire miso,
    output wire interrupt,
    output wire [3:0] dds_out,
    output wire [3:0] pwm_out,
    input wire [1:0] freq_in
);
    localparam COMMAND_LENGTH = 15 * 8;
    localparam ID1 = 8'h1; // dds
    localparam ID2 = 8'h4; // pwm
    localparam ID3 = 8'h2; // frequency counter
    localparam ID4 = 8'h0;

    localparam DDS_TYPE = 16'd6; //ad9959
    localparam LEVEL_METER_TYPE = 16'h0;
    localparam MAX_MV = 16'd3300;
    localparam MAX_ATTENUATOR = 8'h0;
    localparam SET_FREQUENCY_COMMAND_LENGTH = 14 * 8;
    localparam OUTPUT_ENABLE_COMMAND_LENGTH = 5 * 8;

    localparam FREQ_COUNTER_CHANNELS = 8'd2;
    localparam FREQ_COUNTER_RESOLUTION = 8'd4;
    localparam FREQ_COUNTER_MEASURE_TYPE = 8'd6; //Herz
    localparam FREQ_COUNTER_VALUE_TYPE = 8'd0; //Ones
    localparam FREQ_COUNTER_NUMBERS_BEFORE_POINT = 8'd9;

    localparam PWM_CHANNELS = 8'd4;
    localparam PWM_BITS = 8'd32;
    localparam PWM_DDS_CLOCK = 8'd0;
    localparam SET_PERIOD_AND_DUTY_COMMAND_LENGTH = 11 * 8;

    reg [31:0] dds_code [0:3];
    reg [31:0] dds_code_bak [0:3];
    reg [31:0] pwm_period [0:3];
    reg [31:0] pwm_duty [0:3];
    reg [31:0] pwm_duty_bak [0:3];

    reg[COMMAND_LENGTH - 1:0] command = 0;
    reg[COMMAND_LENGTH - 1:0] response = 0;
    reg[7:0] cnt = 0;
    reg prev_sck = 0;
    reg prev_ncs = 1;
    reg rsck = 0;
    reg rncs = 1;
    reg [3:0] dds_output_enabled = 0, pwm_output_enabled = 0;
    reg interrupt_clear = 0;

    wire [1:0] dds_channel;
    wire [1:0] pwm_channel;
    wire [1:0] enable_channel;
    wire enable;
    wire interrupt1, interrupt2;
    wire [31:0] frequency_code1, frequency_code2;

    assign miso = ncs ? 1'bz : response[COMMAND_LENGTH - 1];
    assign dds_channel = command[SET_FREQUENCY_COMMAND_LENGTH - 31: SET_FREQUENCY_COMMAND_LENGTH - 32];
    assign enable_channel = command[9:8];
    assign enable = command[7:0] != 0;
    assign interrupt = interrupt1 & interrupt2;

    assign pwm_channel = command[SET_PERIOD_AND_DUTY_COMMAND_LENGTH - 31: SET_PERIOD_AND_DUTY_COMMAND_LENGTH - 32];

    dds dds_instance1(.clk(clk_dds), .code(dds_code[0]), .out(dds_out[0]));
    dds dds_instance2(.clk(clk_dds), .code(dds_code[1]), .out(dds_out[1]));
    dds dds_instance3(.clk(clk_dds), .code(dds_code[2]), .out(dds_out[2]));
    dds dds_instance4(.clk(clk_dds), .code(dds_code[3]), .out(dds_out[3]));

    frequency_counter #(.COUNTER_WIDTH(32)) fc1(.nreset(nreset), .clk(clk), .iclk(freq_in[0]), .clk_frequency_minus1(FCLK - 1), .code(frequency_code1), .interrupt(interrupt1),
                             .interrupt_clear(interrupt_clear));
    frequency_counter #(.COUNTER_WIDTH(32)) fc2(.nreset(nreset), .clk(clk), .iclk(freq_in[1]), .clk_frequency_minus1(FCLK - 1), .code(frequency_code2), .interrupt(interrupt2),
                             .interrupt_clear(interrupt_clear));

    pwm pwm1(.clk(clk_pwm), .nreset(nreset), .out(pwm_out[0]), .period(pwm_period[0]), .duty(pwm_duty[0]));
    pwm pwm2(.clk(clk_pwm), .nreset(nreset), .out(pwm_out[1]), .period(pwm_period[1]), .duty(pwm_duty[1]));
    pwm pwm3(.clk(clk_pwm), .nreset(nreset), .out(pwm_out[2]), .period(pwm_period[2]), .duty(pwm_duty[2]));
    pwm pwm4(.clk(clk_pwm), .nreset(nreset), .out(pwm_out[3]), .period(pwm_period[3]), .duty(pwm_duty[3]));

    always @(posedge clk) begin
        if (!nreset) begin
            cnt <= 0;
            command <= 0;
            response <= 0;
            dds_output_enabled <= 0;
            dds_code[0] <= 0;
            dds_code[1] <= 0;
            dds_code[2] <= 0;
            dds_code[3] <= 0;
            dds_code_bak[0] <= 0;
            dds_code_bak[1] <= 0;
            dds_code_bak[2] <= 0;
            dds_code_bak[3] <= 0;
            interrupt_clear <= 0;
            pwm_output_enabled <= 0;
            pwm_period[0] <= 1;
            pwm_period[1] <= 1;
            pwm_period[2] <= 1;
            pwm_period[3] <= 1;
            pwm_duty[0] <= 0;
            pwm_duty[1] <= 0;
            pwm_duty[2] <= 0;
            pwm_duty[3] <= 0;
            pwm_duty_bak[0] <= 0;
            pwm_duty_bak[1] <= 0;
            pwm_duty_bak[2] <= 0;
            pwm_duty_bak[3] <= 0;
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
                                    0: response <= { //dds
                                            DDS_TYPE[7:0], DDS_TYPE[15:8],
                                            LEVEL_METER_TYPE[7:0], LEVEL_METER_TYPE[15:8],
                                            MCLK_DDS[7:0], MCLK_DDS[15:8], MCLK_DDS[23:16], MCLK_DDS[31:24],
                                            MCLK_DDS[39:32], MCLK_DDS[47:40], MCLK_DDS[55:48], MCLK_DDS[63:56],
                                            MAX_MV[7:0], MAX_MV[15:8],
                                            MAX_ATTENUATOR};
                                    1: response <= { //pwm
                                            MCLK_PWM[7:0], MCLK_PWM[15:8], MCLK_PWM[23:16], MCLK_PWM[31:24],
                                            PWM_CHANNELS, PWM_BITS, PWM_DDS_CLOCK, 64'h0};
                                    2: response <= { //frequency counter
                                            FREQ_COUNTER_CHANNELS, FREQ_COUNTER_RESOLUTION, FREQ_COUNTER_MEASURE_TYPE, FREQ_COUNTER_VALUE_TYPE,
                                            FREQ_COUNTER_NUMBERS_BEFORE_POINT, 80'h0};
                                    default: response <= {COMMAND_LENGTH{1'b0}};
                                endcase
                            end
                            4: begin
                                response <= {frequency_code1[7:0], frequency_code1[15:8], frequency_code1[23:16], frequency_code1[31:24],
                                             frequency_code2[7:0], frequency_code2[15:8], frequency_code2[23:16], frequency_code2[31:24],
                                             {COMMAND_LENGTH-64{1'b0}}}; // get result
                                interrupt_clear <= 1;
                            end
                            default: response <= {COMMAND_LENGTH{1'b0}}; // get status
                        endcase
                    end
                    OUTPUT_ENABLE_COMMAND_LENGTH: begin
                        response <= {COMMAND_LENGTH{1'b0}};
                        if (command[OUTPUT_ENABLE_COMMAND_LENGTH - 9: OUTPUT_ENABLE_COMMAND_LENGTH - 16] == 3 && // dds_command
                            command[OUTPUT_ENABLE_COMMAND_LENGTH - 17: OUTPUT_ENABLE_COMMAND_LENGTH - 24] == 5) begin // enable_output
                            case (command[OUTPUT_ENABLE_COMMAND_LENGTH - 1: OUTPUT_ENABLE_COMMAND_LENGTH - 8])
                                0: begin //dds
                                    dds_output_enabled[enable_channel] <= enable;
                                    dds_code[enable_channel] <= enable ? dds_code_bak[enable_channel] : 32'h0;
                                end
                                1: begin
                                    pwm_output_enabled[enable_channel] <= enable;
                                    pwm_duty[enable_channel] <= enable ? pwm_duty_bak[enable_channel] : 32'h0;
                                end
                            endcase
                        end
                    end
                    SET_PERIOD_AND_DUTY_COMMAND_LENGTH: begin
                        response <= {COMMAND_LENGTH{1'b0}};
                        if (command[SET_PERIOD_AND_DUTY_COMMAND_LENGTH - 9: SET_PERIOD_AND_DUTY_COMMAND_LENGTH - 16] == 3 && // pwm_command
                            command[SET_PERIOD_AND_DUTY_COMMAND_LENGTH - 17: SET_PERIOD_AND_DUTY_COMMAND_LENGTH - 24] == 2) begin // set period_and_duty
                            pwm_period[pwm_channel] <= {command[63:56], command[55:48], command[47:40], command[39:32]};
                            pwm_duty_bak[pwm_channel] <= {command[31:24], command[23:16], command[15:8], command[7:0]};
                            if (pwm_output_enabled[pwm_channel])
                                pwm_duty[pwm_channel] <= {command[31:24], command[23:16], command[15:8], command[7:0]};
                        end
                    end
                    SET_FREQUENCY_COMMAND_LENGTH: begin
                        response <= {COMMAND_LENGTH{1'b0}};
                        if (command[SET_FREQUENCY_COMMAND_LENGTH - 9: SET_FREQUENCY_COMMAND_LENGTH - 16] == 3 && // dds_command
                            command[SET_FREQUENCY_COMMAND_LENGTH - 17: SET_FREQUENCY_COMMAND_LENGTH - 24] == 2) begin // set frequency code
                            dds_code_bak[dds_channel] <= {command[55:48], command[63:56], command[71:64], command[79:72]};
                            if (dds_output_enabled[dds_channel])
                                dds_code[dds_channel] <= {command[55:48], command[63:56], command[71:64], command[79:72]};
                        end
                    end
                    default: begin
                        if (!interrupt)
                            interrupt_clear <= 0;
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
