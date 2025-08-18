module hyperram_emulator
#(parameter
LATENCY = 6,
MEMORY_BITS=21 // 2Mx32
)
(
    input wire clk,
    input wire nreset,
    input wire ncs,
    inout wire rwds,
    inout wire [7:0] data
);
    localparam RAM_BITS = MEMORY_BITS + 2;

    localparam STATE_A47       = 1;
    localparam STATE_A39       = 2;
    localparam STATE_A31       = 4;
    localparam STATE_A23       = 8;
    localparam STATE_A15       = 16;
    localparam STATE_A7        = 32;
    localparam STATE_NOP       = 64;
    localparam STATE_READ      = 128;
    localparam STATE_WRITE     = 256;

    reg rwds_out;
    reg data_noe;
    reg [7:0] data_out;

    reg [8:0] state;
    reg is_read;

    reg [4:0] nop_counter;

    reg clk1, clk2;

    wire dobled_clock;

    reg [31:0] address;

    reg [7:0] memory[0:(1<<RAM_BITS)-1];

    assign dobled_clock = clk1 | clk2;

    assign data = data_noe ? 8'hz : data_out;
    assign rwds = data_noe ? 1'bz : rwds_out;

    always @(negedge clk) begin
        clk1 <= 1;
        #1
        clk1 <= 0;
    end

    always @(posedge clk) begin
        clk2 <= 1;
        #1
        clk2 <= 0;
    end

    always @(posedge dobled_clock) begin
        if (!nreset | ncs) begin
            data_noe <= 1;
            state <= STATE_A47;
        end
        else begin
            case (state)
                STATE_A47: begin
                    data_noe <= 1;
                    is_read <= data[7];
                    address[31:28] <= data[3:0];
                    nop_counter <= rwds ? LATENCY * 4 - 2 : LATENCY * 2 - 2;
                    state <= STATE_A39;
                end
                STATE_A39: begin
                    address[27:20] <= data;
                    state <= STATE_A31;
                end
                STATE_A31: begin
                    address[19:12] <= data;
                    state <= STATE_A23;
                end
                STATE_A23: begin
                    address[11:4] <= data;
                    state <= STATE_A15;
                end
                STATE_A15: state <= STATE_A7;
                STATE_A7: begin
                    address[3:0] <= {data[2:0], 1'b0};
                    state <= STATE_NOP;
                end
                STATE_NOP: begin
                    if (nop_counter == 0) begin
                        state <= is_read ? STATE_READ : STATE_WRITE;
                        data_noe <= !is_read;
                        rwds_out <= 0;
                    end
                    else
                        nop_counter <= nop_counter - 1;
                end
                STATE_READ: begin
                    rwds_out <= !rwds_out;
                    data_out <= memory[address[RAM_BITS-1:0]];
                    address <= address + 1;
                end
                STATE_WRITE: begin
                    if (!rwds)
                        memory[address[RAM_BITS-1:0]] <= data;
                    address <= address + 1;
                end
            endcase
        end
    end

endmodule
