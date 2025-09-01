`include "qspi_rom_controller.vh"

module qspi_rom_controller
(
    input wire clk,
    input wire nreset,
    input wire [23:0] cpu_address,
`ifdef QSPI_DATA_8_15
`ifdef QSPI_DATA_16_31
    output reg [31:0] cpu_data,
`else
    output reg [15:0] cpu_data,
`endif    
`else
    output reg [7:0] cpu_data,
`endif
    input wire cpu_req,
    output reg cpu_ack,
    output wire rom_sck,
    output wire [3:0] rom_sio_out,
    input wire [3:0] rom_sio_in,
    output reg rom_sio_oe0,
    output reg rom_sio_oe123,
    output reg rom_ncs
);
    localparam SPI_DATA_WIDTH = 8;
`ifdef QSPI_DATA_8_15
`ifdef QSPI_DATA_16_31
    localparam STATE_WIDTH  = 13;
`else
    localparam STATE_WIDTH  = 9;
`endif
`else
    localparam STATE_WIDTH  = 7;
`endif
    localparam STATE_INIT   = 1;
    localparam STATE_IDLE   = 2;
    localparam STATE_SEND   = 4;
    localparam STATE_DUMMY  = 8;
    localparam STATE_DUMMY2 = 16;
    localparam STATE_READ   = 32;
    localparam STATE_READ2  = 64;
`ifdef QSPI_DATA_8_15
    localparam STATE_READ3  = 128;
    localparam STATE_READ4  = 256;
`endif
`ifdef QSPI_DATA_16_31
    localparam STATE_READ5  = 512;
    localparam STATE_READ6  = 1024;
    localparam STATE_READ7  = 2048;
    localparam STATE_READ8  = 4096;
`endif

    reg [STATE_WIDTH - 1:0] state, next_state;

    reg [SPI_DATA_WIDTH-1:0] data0, data1, data2, data3;

    reg [2:0] nbits;

    reg next_ncs;

    wire req;

    assign rom_sck = rom_ncs ? 1'b0 : !clk;
    assign rom_sio_out[0] = data0[SPI_DATA_WIDTH-1];
    assign rom_sio_out[1] = data1[SPI_DATA_WIDTH-1];
    assign rom_sio_out[2] = data2[SPI_DATA_WIDTH-1];
    assign rom_sio_out[3] = data3[SPI_DATA_WIDTH-1];

    assign req = cpu_req & !cpu_ack;

    always @(posedge clk) begin
        if (!nreset) begin
            state <= STATE_INIT;
            cpu_ack <= 0;
            rom_sio_oe0 <= 1;
            rom_sio_oe123 <= 0;
            rom_ncs <= 1;
        end
        else begin
            case (state)
                STATE_INIT: begin
                    data0 = 8'h38;
                    rom_ncs <= 0;
                    state <= STATE_SEND;
                    next_state <= STATE_IDLE;
                    next_ncs <= 1;
                    nbits <= 7;
                end
                STATE_IDLE: begin
                    rom_sio_oe0   <= 1;
                    rom_sio_oe123 <= 1;
                    rom_ncs <= !req;
                    if (req) begin
                        // command is 0x0B - fast read
                        data0 = {1'b0, 1'b1, cpu_address[20], cpu_address[16], cpu_address[12], cpu_address[8], cpu_address[4], cpu_address[0]};
                        data1 = {1'b0, 1'b1, cpu_address[21], cpu_address[17], cpu_address[13], cpu_address[9], cpu_address[5], cpu_address[1]};
                        data2 = {1'b0, 1'b0, cpu_address[22], cpu_address[18], cpu_address[14], cpu_address[10], cpu_address[6], cpu_address[2]};
                        data3 = {1'b0, 1'b1, cpu_address[23], cpu_address[19], cpu_address[15], cpu_address[11], cpu_address[7], cpu_address[3]};
                        nbits <= 7;
                        state <= STATE_SEND;
                        next_state <= STATE_DUMMY;
                        next_ncs <= 0;
                    end
                    if (!cpu_req)
                        cpu_ack <= 0;
                end
                STATE_SEND: begin
                    data0 <= {data0[SPI_DATA_WIDTH-2:0], 1'b0};
                    data1 <= {data1[SPI_DATA_WIDTH-2:0], 1'b0};
                    data2 <= {data2[SPI_DATA_WIDTH-2:0], 1'b0};
                    data3 <= {data3[SPI_DATA_WIDTH-2:0], 1'b0};
                    if (nbits == 0) begin
                        state <= next_state;
                        rom_ncs <= next_ncs;
                    end
                    else
                        nbits <= nbits - 1;
                end
                STATE_DUMMY: begin
                    rom_sio_oe0   <= 0;
                    rom_sio_oe123 <= 0;
                    state <= STATE_DUMMY2;
                end
                STATE_DUMMY2: state <= STATE_READ;
                STATE_READ: begin state <= STATE_READ2; cpu_data[7:4] <= rom_sio_in; end
`ifdef QSPI_DATA_8_15
                STATE_READ2: begin state <= STATE_READ3; cpu_data[3:0] <= rom_sio_in; end
                STATE_READ3: begin state <= STATE_READ4; cpu_data[15:12] <= rom_sio_in; end
`ifdef QSPI_DATA_16_31
                STATE_READ4: begin state <= STATE_READ5; cpu_data[11:8] <= rom_sio_in; end
                STATE_READ5: begin state <= STATE_READ6; cpu_data[23:20] <= rom_sio_in; end
                STATE_READ6: begin state <= STATE_READ7; cpu_data[19:16] <= rom_sio_in; end
                STATE_READ7: begin state <= STATE_READ8; cpu_data[31:28] <= rom_sio_in; end
                STATE_READ8: begin state <= STATE_IDLE; cpu_ack <= 1; rom_ncs <= 1; cpu_data[27:24] <= rom_sio_in; end
`else                
                STATE_READ4: begin state <= STATE_IDLE; cpu_ack <= 1; rom_ncs <= 1; cpu_data[11:8] <= rom_sio_in; end
`endif                
`else
                STATE_READ2: begin state <= STATE_IDLE; cpu_ack <= 1; rom_ncs <= 1; cpu_data[3:0] <= rom_sio_in; end
`endif
            endcase
        end
    end

endmodule
