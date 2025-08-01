module sdram_emulator
#(parameter
DATA_WIDTH = 32,
ADDRESS_WIDTH = 11,
COLUMN_ADDRESS_WIDTH = 8,
BANK_BITS = 2,
CAS_LATENCY = 2
)
(
    input wire clk,
    input wire cke,
    input wire [ADDRESS_WIDTH-1:0] address,
    input wire [BANK_BITS-1:0] ba,
    input wire ncs,
    input wire ras,
    input wire cas,
    input wire nwe,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    input wire dqm[DATA_WIDTH/8-1:0]
);
    reg [7:0] memory1 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
    reg [7:0] memory2 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
    reg [7:0] memory3 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
    reg [7:0] memory4 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
    reg [ADDRESS_WIDTH-1:0] row_address;
    reg [COLUMN_ADDRESS_WIDTH-1:0] column_address;
    wire [ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH-1:0] memory_address;
    reg [1:0] nop_counter;
    reg [2:0] command;
    reg cas_enable;

    assign memory_address = {column_address, row_address};

    always @(posedge clk) begin
        if (cke & !ncs) begin
            command <= {ras, cas, nwe};
            case ({ras, cas, nwe})
                3'b011: begin // BankActivate
                    row_address <= address;
                    nop_counter <= 0;
                    cas_enable <= 0;
                end
                3'b101: begin // Read
                    if (cas_enable) begin
                        column_address <= address[COLUMN_ADDRESS_WIDTH-1:0];
                        nop_counter <= 0;
                        cas_enable <= 0;
                    end
                end
                3'b100: begin // Write
                    if (cas_enable) begin
                        if (!dqm[0])
                            memory1[ba][{address[COLUMN_ADDRESS_WIDTH-1:0], row_address}] <= data_in[7:0];
                        if (!dqm[1])
                            memory2[ba][{address[COLUMN_ADDRESS_WIDTH-1:0], row_address}] <= data_in[15:8];
                        if (!dqm[2])
                            memory3[ba][{address[COLUMN_ADDRESS_WIDTH-1:0], row_address}] <= data_in[23:16];
                        if (!dqm[3])
                            memory4[ba][{address[COLUMN_ADDRESS_WIDTH-1:0], row_address}] <= data_in[31:24];
                        cas_enable <= 0;
                    end
                end
                3'b111: begin // nop
                    if (nop_counter == 2 && command == 3'b011) // BankActivate
                        cas_enable <= 1;
                    if (nop_counter == CAS_LATENCY - 1 && command == 3'b101) // Read
                        data_out <= {memory4[ba][memory_address], memory3[ba][memory_address], memory2[ba][memory_address], memory1[ba][memory_address]};
                    nop_counter <= nop_counter + 1;
                end
                default: begin end
            endcase
        end
    end
endmodule
