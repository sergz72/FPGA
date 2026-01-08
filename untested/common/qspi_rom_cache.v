module qspi_rom_cache
#(parameter
ADDRESS_WIDTH = 22,
DATA_WIDTH = 32,
CACHE_MEMORY_SIZE = 64,
CACHE_BLOCK_SIZE = 16
)
(
    input wire clk,
    input wire nreset,
    input wire [ADDRESS_WIDTH - 1:0] cpu_address,
    output reg [DATA_WIDTH - 1:0] cpu_data,
    input wire cpu_req,
    output reg cpu_ack,
    output wire rom_sck,
    output wire [3:0] rom_sio_out,
    input wire [3:0] rom_sio_in,
    output reg rom_sio_oe,
    output reg rom_ncs
);
    localparam CACHE_WIDTH = ADDRESS_WIDTH - $clog2(CACHE_BLOCK_SIZE) - $clog2(CACHE_MEMORY_SIZE) + 1;
    localparam CACHE_INIT_VALUE = 1 << (CACHE_WIDTH - 1);
    localparam CACHE_MEMORY_BITS = $clog2(CACHE_MEMORY_SIZE);
    localparam CACHE_BLOCK_BITS = $clog2(CACHE_BLOCK_SIZE);
    localparam STATE_WIDTH = 4;
    localparam STATE_INIT =  1;
    localparam STATE_IDLE =  2;
    localparam STATE_FETCH = 4;

    reg [STATE_WIDTH - 1:0] state;
    reg [CACHE_WIDTH -1:0] cache_p[0: CACHE_MEMORY_SIZE - 1];
    reg [CACHE_MEMORY_BITS:0] counter;
    wire [CACHE_MEMORY_BITS:0] cache_p_address;
    wire [CACHE_WIDTH-1:0] cache_hit;
    reg [DATA_WIDTH-1:0] cache[0:CACHE_BLOCK_SIZE*CACHE_MEMORY_SIZE-1];

    assign rom_sck <= rom_ncs ? 1'b0 : !clk;
    assign cache_p_address = state == STATE_INIT ? counter : cpu_address[CACHE_MEMORY_BITS+CACHE_BLOCK_BITS-1:CACHE_BLOCK_BITS];
    assign cache_hit = {1'b0, cpu_address[ADDRESS_WIDTH-1:CACHE_MEMORY_BITS+CACHE_BLOCK_BITS]};

    always @(posedge clk) begin
        if (!nreset) begin
            state <= STATE_INIT;
            cpu_ack <= 0;
            rom_sio_oe <= 0;
            rom_ncs <= 1;
            cache_p_address <= 0;
        end
        else begin
            case (state)
                STATE_INIT: begin
                    if (counter == CACHE_MEMORY_SIZE)
                        state <= STTAE_IDLE;
                    else
                        cache_p[cache_p_address] <= CACHE_INIT_VALUE;
                    counter <= counter + 1;
                end
                STATE_IDLE: begin
                    if (cpu_req) begin
                        if (cache_p[cache_p_address] == cache_hit) begin
                            cpu_data <= cache[{cache_p_address, cpu_address[CACHE_BLOCK_BITS-1:0]}];
                            cpu_ack <= 1;
                        end
                        else begin
                            state <= STATE_FETCH;
                            cache_p[cache_p_address] <= cache_hit;
                            //todo
                        end
                    end
                    else
                        cpu_ack <= 0;
                end
                STATE_FETCH: begin
                    //todo
                end
            endcase
        end
    end
endmodule
