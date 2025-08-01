module sdram_controller
#(parameter
DATA_WIDTH = 32,
SDRAM_ADDRESS_WIDTH = 11,
SDRAM_COLUMN_ADDRESS_WIDTH = 8,
BANK_BITS = 2,
// burst length 1, cas latency 2
MODE_REGISTER_VALUE = 'h20,
AUTOREFRESH_LATENCY = 3,
CLK_FREQUENCY = 25000000
)
(
    input wire clk,
    input wire nreset,
    //cpu io
    input wire [BANK_BITS+SDRAM_ADDRESS_WIDTH+SDRAM_COLUMN_ADDRESS_WIDTH-1:0] cpu_address,
    input wire [DATA_WIDTH-1:0] cpu_data_in,
    output reg [DATA_WIDTH-1:0] cpu_data_out,
    input wire cpu_req,
    input wire [DATA_WIDTH/8-1:0] cpu_nwr,
    output reg cpu_ack,
    //sdram io
    output wire sdram_clk,
    output reg [SDRAM_ADDRESS_WIDTH-1:0] sdram_address,
    output reg [BANK_BITS-1:0] sdram_ba,
    output reg sdram_ncs,
    output reg sdram_ras,
    output reg sdram_cas,
    output reg sdram_nwe,
    input wire [DATA_WIDTH-1:0] sdram_data_in,
    output wire [DATA_WIDTH-1:0] sdram_data_out,
    output wire [DATA_WIDTH/8-1:0] sdram_dqm
);
    localparam NUM_BYTES = DATA_WIDTH/8;
    localparam ADDRESS_WIDTH = BANK_BITS+SDRAM_ADDRESS_WIDTH+SDRAM_COLUMN_ADDRESS_WIDTH;
    localparam REFRESH_COUNTER_BITS = $clog2(CLK_FREQUENCY / 65536);

    localparam STATE_MODE_REGISTER_SET = 1;
    localparam STATE_IDLE              = 2;
    localparam STATE_NOP1              = 4;
    localparam STATE_NOP2              = 8;
    localparam STATE_CAS               = 16;
    localparam STATE_NOP3              = 32;
    localparam STATE_NOP4              = 64;
    localparam STATE_READ              = 128;
    localparam STATE_REFRESH           = 256;
    localparam STATE_WAIT              = 512;

    reg [9:0] state;
    wire is_read;
    wire req;

    reg [REFRESH_COUNTER_BITS-1:0] refresh_counter;
    reg [2:0] autorefresh_counter;

    assign sdram_clk = !clk;
    assign sdram_data_out = cpu_data_in;

    assign sdram_dqm[0] = cpu_nwr[0];

    assign is_read = cpu_nwr == {NUM_BYTES{1'b1}};
    
    assign req = cpu_req & !cpu_ack;

    genvar i;
    generate
        for (i = 1; i < NUM_BYTES; i = i + 1) begin : dqm_generate
            assign sdram_dqm[i] = cpu_nwr[i];
        end
    endgenerate

    always @(posedge clk) begin
        if (!nreset) begin
            sdram_ncs <= 1;
            sdram_cas <= 1;
            sdram_ras <= 1;
            sdram_nwe <= 1;
            cpu_ack <= 0;
            state <= STATE_MODE_REGISTER_SET;
            refresh_counter <= 1;
        end
        else begin
            if (refresh_counter != 0)
                refresh_counter <= refresh_counter + 1;
            case (state)
                STATE_MODE_REGISTER_SET: begin
                    sdram_ncs <= 0;
                    sdram_cas <= 0;
                    sdram_ras <= 0;
                    sdram_nwe <= 0;
                    sdram_address <= MODE_REGISTER_VALUE;
                    state <= STATE_IDLE;
                end
                STATE_IDLE: begin
                    sdram_ncs <= !req;
                    sdram_ras <= !req;
                    sdram_cas <= 1;
                    sdram_nwe <= 1;
                    // bank activate
                    sdram_address <= cpu_address[ADDRESS_WIDTH-BANK_BITS-1:SDRAM_COLUMN_ADDRESS_WIDTH];
                    sdram_ba <= cpu_address[ADDRESS_WIDTH-1:ADDRESS_WIDTH-BANK_BITS];
                    if (refresh_counter == 0) begin
                        refresh_counter <= 1;
                        state <= STATE_REFRESH;
                        autorefresh_counter <= 0;
                    end
                    else if (req)
                        state <= STATE_NOP1;
                    else begin
                    end
                    if (!cpu_req)
                        cpu_ack <= 0;
                end
                STATE_NOP1: begin
                    state <= STATE_NOP2;
                    sdram_ras <= 1;
                end
                STATE_NOP2: state <= STATE_CAS;
                STATE_CAS: begin
                    sdram_ras <= 1;
                    sdram_cas <= 0;
                    sdram_nwe <= is_read;
                    // read/write with precharge
                    sdram_address <= {1'b1, cpu_address[SDRAM_ADDRESS_WIDTH-2:0]};
                    cpu_ack <= !is_read;
                    state <= is_read ? STATE_NOP3 : STATE_IDLE;
                end
                STATE_NOP3: begin
                    state <= STATE_NOP4;
                    sdram_cas <= 1;
                end
                STATE_NOP4: state <= STATE_READ;
                STATE_READ: begin
                    state <= STATE_IDLE;
                    cpu_ack <= 1;
                    cpu_data_out <= sdram_data_in;
                end
                STATE_REFRESH: begin
                    sdram_ncs <= 0;
                    sdram_ras <= 0;
                    sdram_cas <= 0;
                    state <= STATE_WAIT;
                end
                STATE_WAIT: begin
                    sdram_ras <= 1;
                    sdram_cas <= 1;
                    if (autorefresh_counter == AUTOREFRESH_LATENCY)
                        state <= STATE_IDLE;
                    else
                        autorefresh_counter <= autorefresh_counter + 1;
                end
            endcase
        end
    end

endmodule
