module qspi_rom_emulator
#(parameter MEMORY_BITS = 23)
(
    input wire sck,
    inout wire [3:0] sio,
    input wire ncs
);
    localparam STATE_WIDTH         = 12;
    localparam STATE_SPI_COMMAND   = 1;
    localparam STATE_QSPI_COMMAND  = 2;
    localparam STATE_QSPI_COMMAND2 = 4;
    localparam STATE_ADDRESS23     = 8;
    localparam STATE_ADDRESS19     = 16;
    localparam STATE_ADDRESS15     = 32;
    localparam STATE_ADDRESS11     = 64;
    localparam STATE_ADDRESS7      = 128;
    localparam STATE_ADDRESS3      = 256;
    localparam STATE_DUMMY1        = 512;
    localparam STATE_DUMMY2        = 1024;
    localparam STATE_DATA          = 2048;

    reg [STATE_WIDTH - 1:0] state;

    reg [3:0] mem_rdata;

    reg [3:0] memory [0:(1<<MEMORY_BITS)-1];

    reg [7:0] spi_command = 0;
    reg [3:0] qspi_command;

    reg [3:0] nbits;

    wire [3:0] sio_out;
    reg sio_oe1;
    reg sio_oe023;

    reg [23:0] address;
    reg [MEMORY_BITS-1:0] address_rd;

    assign sio[1] = sio_oe1 ? sio_out[1] : 1'bz;
    assign sio[0] = sio_oe023 ? sio_out[0] : 1'bz;
    assign sio[3:2] = sio_oe023 ? sio_out[3:2] : 2'bz;

    assign sio_out[0] = mem_rdata[0];
    assign sio_out[1] = mem_rdata[1];
    assign sio_out[2] = mem_rdata[2];
    assign sio_out[3] = mem_rdata[3];

    initial begin
        $readmemh("asm/flash.hex", memory);
    end

    always @(posedge sck or posedge ncs) begin
        if (ncs) begin
            state <= spi_command == 8'h38 ? STATE_QSPI_COMMAND : STATE_SPI_COMMAND;
            sio_oe1 <= 0;
            sio_oe023 <= 0;
        end
        else begin
            case (state)
                STATE_SPI_COMMAND: spi_command <= {spi_command[6:0], sio[0]};
                STATE_QSPI_COMMAND: begin
                    qspi_command[3:0] <= sio;
                    state <= STATE_QSPI_COMMAND2;
                end
                STATE_QSPI_COMMAND2: begin
                    if ({qspi_command, sio} == 8'h0B)
                        state <= STATE_ADDRESS23;
                end
                STATE_ADDRESS23: begin
                    address[23:20] <= sio;
                    state <= STATE_ADDRESS19;
                end
                STATE_ADDRESS19: begin
                    address[19:16] <= sio;
                    state <= STATE_ADDRESS15;
                end
                STATE_ADDRESS15: begin
                    address[15:12] <= sio;
                    state <= STATE_ADDRESS11;
                end
                STATE_ADDRESS11: begin
                    address[11:8] <= sio;
                    state <= STATE_ADDRESS7;
                end
                STATE_ADDRESS7: begin
                    address[7:4] <= sio;
                    state <= STATE_ADDRESS3;
                end
                STATE_ADDRESS3: begin
                    address[3:0] <= sio;
                    state <= STATE_DUMMY1;
                end
                STATE_DUMMY1: state <= STATE_DUMMY2;
                STATE_DUMMY2: begin state <= STATE_DATA; sio_oe1 <= 1; sio_oe023 <= 1; end
                default: begin end
            endcase
        end
    end

    always @(negedge sck) begin
        case (state)
            STATE_DUMMY1: address_rd <= {address[MEMORY_BITS-2:0], 1'b0};
            STATE_DATA: begin
                mem_rdata <= memory[address_rd];
                address_rd <= address_rd + 1;
            end
            default: begin end
        endcase
    end
endmodule
