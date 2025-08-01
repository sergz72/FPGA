module sdram_controller
#(parameter
DATA_WIDTH = 32,
SDRAM_ADDRESS_WIDTH = 11,
SDRAM_COLUMN_ADDRESS_WIDTH = 8,
BANK_BITS = 2,
// burst length 1, cas latency 2
MODE_REGISTER_VALUE = 'h20
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
    output wire dqm[DATA_WIDTH/8-1:0]
);
    localparam NUM_BYTES = DATA_WIDTH/8;
    localparam ADDRESS_WIDTH = BANK_BITS+SDRAM_ADDRESS_WIDTH+SDRAM_COLUMN_ADDRESS_WIDTH;

    localparam STATE_MODE_REGISTER_SET = 1;
    localparam STATE_IDLE              = 2;
    localparam STATE_CAS               = 4;
    localparam STATE_WAIT1             = 8;
    localparam STATE_WAIT2             = 16;
    localparam STATE_READ              = 32;

    reg [5:0] state;
    wire is_read;
    wire req;

    assign sdram_clk = !clk;
    assign sdram_data_out = cpu_data_in;

    assign dqm[0] = cpu_nwr[0];

    assign is_read = cpu_nwr == {NUM_BYTES{1'b1}};
    
    assign req = cpu_req & !cpu_ack;

    genvar i;
    generate
        for (i = 1; i < NUM_BYTES; i = i + 1) begin
            assign dqm[i] = cpu_nwr[i];
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
        end
        else begin
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
                    if (req)
                        state <= STATE_CAS;
                    if (!cpu_req)
                        cpu_ack <= 0;
                end
                STATE_CAS: begin
                    sdram_ras <= 1;
                    sdram_cas <= 0;
                    sdram_nwe <= is_read;
                    // read/write with precharge
                    sdram_address <= {1'b1, cpu_address[SDRAM_ADDRESS_WIDTH-2:0]};
                    cpu_ack <= !is_read;
                    state <= is_read ? STATE_WAIT1 : STATE_IDLE;
                end
                STATE_WAIT1: state <= STATE_WAIT2;
                STATE_WAIT2: state <= STATE_READ;
                STATE_READ: begin
                    state <= STATE_IDLE;
                    cpu_ack <= 1;
                    cpu_data_out <= sdram_data_in;
                end
            endcase
        end
    end

endmodule
