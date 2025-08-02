module sdram_controller_16_to_32
#(parameter
SDRAM_ADDRESS_WIDTH = 13,
SDRAM_COLUMN_ADDRESS_WIDTH = 9,
BANK_BITS = 2,
// burst length 2, cas latency 2
//todo
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
    input wire [BANK_BITS+SDRAM_ADDRESS_WIDTH+SDRAM_COLUMN_ADDRESS_WIDTH-2:0] cpu_address,
    input wire [31:0] cpu_data_in,
    output wire [31:0] cpu_data_out,
    input wire cpu_req,
    input wire [3:0] cpu_nwr,
    output reg cpu_ack,
    //sdram io
    output wire sdram_clk,
    output reg [SDRAM_ADDRESS_WIDTH-1:0] sdram_address,
    output reg [BANK_BITS-1:0] sdram_ba,
    output reg sdram_ncs,
    output reg sdram_ras,
    output reg sdram_cas,
    output reg sdram_nwe,
    input wire [15:0] sdram_data_in,
    output wire [15:0] sdram_data_out,
    output wire [1:0] sdram_dqm
);
    localparam EXTRA_ADDRESS_BITS = SDRAM_ADDRESS_WIDTH - 11;
    localparam ADDRESS_WIDTH = BANK_BITS+SDRAM_ADDRESS_WIDTH+SDRAM_COLUMN_ADDRESS_WIDTH;
    localparam REFRESH_COUNTER_BITS = $clog2(CLK_FREQUENCY / 65536) - 1;

    localparam STATE_MODE_REGISTER_SET = 1;
    localparam STATE_IDLE              = 2;
    localparam STATE_NOP               = 4;
    localparam STATE_CAS               = 8;
    localparam STATE_READ              = 16;
    localparam STATE_READ2             = 32;

    reg [15:0] cpu_data_out1, cpu_data_out2,

    reg [5:0] state, next_state;
    wire is_read;
    wire req;

    reg [2:0] nop_counter;

    reg [REFRESH_COUNTER_BITS-1:0] refresh_counter;
    reg refresh;

    reg low_byte;

    assign sdram_clk = !clk;
    assign sdram_data_out = low_byte ? cpu_data_in[15:0] : cpu_data_in[31:16];

    assign sdram_dqm[0] = low_byte? cpu_nwr[0] : cpu_nwr[2];
    assign sdram_dqm[1] = low_byte? cpu_nwr[1] : cpu_nwr[3];

    assign is_read = cpu_nwr == 2'b11;
    
    assign req = cpu_req & !cpu_ack;

    assign cpu_data_out = {cpu_data_out2, cpu_data_out1};

    always @(posedge clk) begin
        if (!nreset) begin
            sdram_ncs <= 1;
            sdram_cas <= 1;
            sdram_ras <= 1;
            sdram_nwe <= 1;
            cpu_ack <= 0;
            state <= STATE_MODE_REGISTER_SET;
            refresh_counter <= 1;
            refresh <= 0;
        end
        else begin
            if (refresh_counter == 0)
                refresh <= 1;
            else if (!sdram_ras & !sdram_cas) // auto-refresh
                refresh <= 0;
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
                    sdram_address <= {{EXTRA_ADDRESS_BITS{1'b0}}, 1'b1, cpu_address[8:0], 1'b0};
                    low_byte <= 1;
                    state <= is_read ? STATE_NOP : STATE_READ2;
                    nop_counter <= CAS_LATENCY - 1;
                    next_state <= STATE_READ;
                end
                STATE_READ: begin
                    state <= STATE_READ2;
                    cpu_data_out1 <= sdram_data_in;
                end
                STATE_READ2: begin
                    low_byte <= 0;
                    state <= STATE_NOP;
                    cpu_ack <= 1;
                    cpu_data_out2 <= sdram_data_in;
                    nop_counter <= PRECHARGE_LATENCY - 1;
                    next_state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
