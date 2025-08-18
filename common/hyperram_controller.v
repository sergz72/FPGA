module hyperram_controller
#(parameter
LATENCY2X = 1,
LATENCY = 6,
MEMORY_BITS = 21 // 2Mx32
)
(
    input wire clk,
    input wire nreset,
    //cpu io
    input wire [MEMORY_BITS-1:0] cpu_address,
    input wire [31:0] cpu_data_in,
    output wire [31:0] cpu_data_out,
    input wire cpu_req,
    input wire [3:0] cpu_nwr,
    output reg cpu_ack,
    //hyperram io
    output reg hyperram_clk,
    output wire hyperram_nreset,
    output reg hyperram_ncs,
    input wire hyperram_rwds_in,
    output reg hyperram_rwds_out,
    output reg hyperram_data_noe,
    input wire [7:0] hyperram_data_in,
    output reg [7:0] hyperram_data_out
);
    localparam EXTRA_BITS      = 30 - MEMORY_BITS;
    localparam STATE_IDLE      = 1;
    localparam STATE_A39       = 2;
    localparam STATE_A31       = 4;
    localparam STATE_A23       = 8;
    localparam STATE_A15       = 16;
    localparam STATE_A7        = 32;
    localparam STATE_NOP       = 64;
    localparam STATE_READWRITE = 128;

    reg [7:0] cpu_data_out_bytes [0:3];
    wire [7:0] cpu_data_in_bytes [0:3];

    reg [7:0] state;
    wire is_read;
    wire req;

    reg [4:0] nop_counter;
    reg [1:0] byte_counter;

    wire [29:0] address;

    assign address = {{EXTRA_BITS{1'b0}}, cpu_address};

    assign is_read = cpu_nwr == 4'b1111;
    
    assign req = cpu_req & !cpu_ack;

    assign cpu_data_out = {cpu_data_out_bytes[3], cpu_data_out_bytes[2], cpu_data_out_bytes[1], cpu_data_out_bytes[0]};

    assign cpu_data_in_bytes[0] = cpu_data_in[7:0];
    assign cpu_data_in_bytes[1] = cpu_data_in[15:8];
    assign cpu_data_in_bytes[2] = cpu_data_in[23:16];
    assign cpu_data_in_bytes[3] = cpu_data_in[31:24];

    assign hyperram_nreset = nreset;

    always @(negedge clk) begin
        hyperram_clk <= ~hyperram_clk;
    end

    always @(posedge clk) begin
        if (!nreset) begin
            hyperram_ncs <= 1;
            hyperram_data_noe <= 1;
            cpu_ack <= 0;
            state <= STATE_IDLE;
        end
        else begin
            case (state)
                STATE_IDLE: begin
                    hyperram_ncs <= !req;
                    hyperram_data_noe <= !req;
                    hyperram_rwds_out <= LATENCY2X;
                    hyperram_data_out <= {is_read, 1'b0 /*memory space*/, 1'b1 /*linear burst*/, 1'b0, address[29:26]};
                    if (req)
                        state <= STATE_A39;
                    if (!cpu_req)
                        cpu_ack <= 0;
                end
                STATE_A39: begin
                    hyperram_data_out <= address[25:18];
                    state <= STATE_A31;
                end
                STATE_A31: begin
                    hyperram_data_out <= address[17:10];
                    state <= STATE_A23;
                end
                STATE_A23: begin
                    hyperram_data_out <= address[9:2];
                    state <= STATE_A15;
                end
                STATE_A15: begin
                    hyperram_data_out <= 8'h0;
                    state <= STATE_A7;
                end
                STATE_A7: begin
                    hyperram_data_out <= {5'h0, address[1:0], 1'b0};
                    state <= STATE_NOP;
                    nop_counter <= LATENCY * 2 * (LATENCY2X + 1) - 2;
                end
                STATE_NOP: begin
                    hyperram_data_noe <= is_read;
                    hyperram_rwds_out <= 0;
                    if (nop_counter == 0)
                        state <= STATE_READWRITE;
                    else
                        nop_counter <= nop_counter - 1;
                    byte_counter <= 0;
                end
                STATE_READWRITE: begin
                    hyperram_rwds_out <= cpu_nwr[byte_counter];
                    hyperram_data_out <= cpu_data_in_bytes[byte_counter];
                    if (!is_read || hyperram_rwds_in || byte_counter != 0) begin
                        cpu_data_out_bytes[byte_counter] <= hyperram_data_in;
                        if (byte_counter == 3) begin
                            state <= STATE_IDLE;
                            cpu_ack <= 1;
                        end
                        byte_counter <= byte_counter + 1;
                    end
                end
            endcase
        end
    end

endmodule
