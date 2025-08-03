module sdram_emulator
#(parameter
ADDRESS_WIDTH = 11,
COLUMN_ADDRESS_WIDTH = 8,
BANK_BITS = 2,
CAS_LATENCY = 2,
BURST_SIZE = 1
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
`ifndef GEN16
    inout wire [31:0] data,
    input wire [3:0] dqm
`else
    inout wire [15:0] data,
    input wire [1:0] dqm
`endif
);
`ifndef GEN16
    localparam DATA_WIDTH = 32;
`else
    localparam DATA_WIDTH = 16;
`endif
    localparam COMMAND_NONE          = 0;
    localparam COMMAND_BANK_ACTIVATE = 1;

    reg [7:0] memory1 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
    reg [7:0] memory2 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
`ifndef GEN16
    reg [7:0] memory3 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
    reg [7:0] memory4 [0:(1<<BANK_BITS)-1] [0:(1 << (ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH)) - 1];
`endif

    reg [ADDRESS_WIDTH-1:0] row_address;
    reg [COLUMN_ADDRESS_WIDTH-1:0] column_address;
    wire [ADDRESS_WIDTH+COLUMN_ADDRESS_WIDTH-1:0] memory_address;
    reg [3:0] nop_counter;
    reg command = COMMAND_NONE;
    reg cas_enable;
    reg [DATA_WIDTH-1:0] data_out;
    reg [1:0] read_burst_size, write_burst_size;
    wire woe;
    reg oe = 0;

    assign data = oe ? data_out : {DATA_WIDTH{1'bz}};

    assign memory_address = {row_address, column_address};

    assign woe = read_burst_size != 0 && nop_counter >= CAS_LATENCY - 1;

    always @(posedge clk) begin
        if (cke & !ncs) begin
            case ({ras, cas, nwe})
                3'b011: begin // BankActivate
                    row_address <= address;
                    nop_counter <= 0;
                    cas_enable <= 0;
                    command <= COMMAND_BANK_ACTIVATE;
                    read_burst_size <= 0;
                    write_burst_size <= 0;
                end
                3'b101: begin // Read
                    command <= COMMAND_NONE;
                    if (cas_enable) begin
                        column_address <= address[COLUMN_ADDRESS_WIDTH-1:0];
                        nop_counter <= 0;
                        cas_enable <= 0;
                        read_burst_size <= BURST_SIZE;
                    end
                end
                3'b100: begin // Write
                    command <= COMMAND_NONE;
                    if (cas_enable) begin
                        column_address <= address[COLUMN_ADDRESS_WIDTH-1:0] + 1;
                        if (!dqm[0])
                            memory1[ba][{row_address, address[COLUMN_ADDRESS_WIDTH-1:0]}] <= data[7:0];
                        if (!dqm[1])
                            memory2[ba][{row_address, address[COLUMN_ADDRESS_WIDTH-1:0]}] <= data[15:8];
`ifndef GEN16
                        if (!dqm[2])
                            memory3[ba][{row_address, address[COLUMN_ADDRESS_WIDTH-1:0]}] <= data[23:16];
                        if (!dqm[3])
                            memory4[ba][{row_address, address[COLUMN_ADDRESS_WIDTH-1:0]}] <= data[31:24];
`endif
                        cas_enable <= 0;
                        write_burst_size <= BURST_SIZE - 1;
                    end
                end
                3'b111: begin // nop
                    if (write_burst_size != 0) begin
                        if (!dqm[0])
                            memory1[ba][memory_address] <= data[7:0];
                        if (!dqm[1])
                            memory2[ba][memory_address] <= data[15:8];
`ifndef GEN16
                        if (!dqm[2])
                            memory3[ba][memory_address] <= data[23:16];
                        if (!dqm[3])
                            memory4[ba][memory_address] <= data[31:24];
`endif
                        write_burst_size <= write_burst_size - 1;
                        column_address <= column_address + 1;
                    end
                    else if (woe) begin // Read
                        oe <= 1;
`ifndef GEN16
                        data_out <= {memory4[ba][memory_address], memory3[ba][memory_address], memory2[ba][memory_address], memory1[ba][memory_address]};
`else
                        data_out <= {memory2[ba][memory_address], memory1[ba][memory_address]};
`endif
                        read_burst_size <= read_burst_size - 1;
                        column_address <= column_address + 1;
                    end
                    else
                        oe <= 0;
                    if (nop_counter == 1 && command == COMMAND_BANK_ACTIVATE) // BankActivate
                        cas_enable <= 1;
                    nop_counter <= nop_counter + 1;
                end
                default: begin
                    read_burst_size <= 0;
                    write_burst_size <= 0;
                    command <= COMMAND_NONE;
                end
            endcase
        end
    end
endmodule
