module sdram_controller
#(parameter
DATA_WIDTH = 32,
SDRAM_ADDRESS_WIDTH = 11,
SDRAM_COLUMN_ADDRESS_WIDTH = 8,
BANK_BITS = 2,
// burst length 1, cas latency 2
MODE_REGISTER_VALUE = 'h20,
AUTOREFRESH_LATENCY = 3,
CAS_LATENCY = 2,
BANK_ACTIVATE_LATENCY = 2,
PRECHARGE_LATENCY = 2,
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
    output wire sdram_cke,
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
    localparam REFRESH_COUNTER_BITS = $clog2(CLK_FREQUENCY / 65536) - 1;
    localparam ADDRESS_TO_TEN = SDRAM_ADDRESS_WIDTH - 10;
    localparam [ADDRESS_TO_TEN-1:0] ADDRESS_ADD = 'h1;

    localparam STATE_INIT = 1;
    localparam STATE_IDLE = 2;
    localparam STATE_NOP  = 4;
    localparam STATE_CAS  = 8;
    localparam STATE_READ = 16;

    reg [4:0] state, next_state;
    wire is_read;
    wire req;

    reg [2:0] nop_counter;

    reg [REFRESH_COUNTER_BITS-1:0] refresh_counter;
    reg refresh;

    reg [1:0] init_counter;
    wire init_3_or_0;

    assign sdram_cke = 1'b1;
    
    assign sdram_clk = !clk;
    assign sdram_data_out = cpu_data_in;

    assign sdram_dqm[0] = cpu_nwr[0];

    assign is_read = cpu_nwr == {NUM_BYTES{1'b1}};
    
    assign req = cpu_req & !cpu_ack;

    assign init_3_or_0 = init_counter[1] ^ init_counter[0];

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
            state <= STATE_INIT;
            refresh_counter <= 1;
            refresh <= 0;
            init_counter <= 3;
        end
        else begin
            if (refresh_counter == 0)
                refresh <= 1;
            else if (!sdram_ras & !sdram_cas) // auto-refresh
                refresh <= 0;
            refresh_counter <= refresh_counter + 1;
            case (state)
                STATE_INIT: begin
                    sdram_ncs <= 0;
                    sdram_cas <= init_counter == 3;
                    sdram_ras <= 0;
                    sdram_nwe <= init_3_or_0;
                    sdram_address <= init_counter == 0 ? MODE_REGISTER_VALUE : {ADDRESS_ADD, 10'h0};
                    state <= STATE_NOP;
                    nop_counter <= AUTOREFRESH_LATENCY - 1;
                    next_state <= init_counter != 0 ? STATE_INIT : STATE_IDLE;
                    init_counter <= init_counter - 1;
                end
                STATE_IDLE: begin
                    // bank activate or auto-refresh
                    sdram_ncs <= !req & !refresh;
                    sdram_ras <= !req & !refresh;
                    sdram_cas <= !refresh;
                    sdram_nwe <= 1;
                    sdram_address <= cpu_address[ADDRESS_WIDTH-BANK_BITS-1:SDRAM_COLUMN_ADDRESS_WIDTH];
                    sdram_ba <= cpu_address[ADDRESS_WIDTH-1:ADDRESS_WIDTH-BANK_BITS];
                    if (refresh | req)
                        state <= STATE_NOP;
                    nop_counter <= refresh ? AUTOREFRESH_LATENCY - 1 : BANK_ACTIVATE_LATENCY - 1;
                    next_state <= refresh ? STATE_IDLE : STATE_CAS;
                    if (!cpu_req)
                        cpu_ack <= 0;
                end
                STATE_NOP: begin
                    sdram_ras <= 1;
                    sdram_cas <= 1;
                    sdram_nwe <= 1;
                    if (nop_counter == 0)
                        state <= next_state;
                    else
                        nop_counter <= nop_counter - 1;
                end
                STATE_CAS: begin
                    sdram_ras <= 1;
                    sdram_cas <= 0;
                    sdram_nwe <= is_read;
                    // read/write with precharge
                    sdram_address <= {ADDRESS_ADD, cpu_address[9:0]};
                    cpu_ack <= !is_read;
                    state <= STATE_NOP;
                    nop_counter <= is_read ? CAS_LATENCY - 1 : PRECHARGE_LATENCY - 1;
                    next_state <= is_read ? STATE_READ : STATE_IDLE;
                end
                STATE_READ: begin
                    state <= STATE_NOP;
                    cpu_ack <= 1;
                    cpu_data_out <= sdram_data_in;
                    nop_counter <= PRECHARGE_LATENCY - 1;
                    next_state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
