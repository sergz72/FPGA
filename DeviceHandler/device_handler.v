module device_handler
#(parameter SPI_BITS = 3, IO_BITS = 10)
(
    input wire clk,
    input wire nreset,
    //spi
    input wire [SPI_BITS - 1: 0] sdi,
    output wire [SPI_BITS - 1: 0] sdo,
    input wire sclk,
    input wire sncs,
    //io
    input wire [IO_BITS - 1:0] module_in,
    output wire [IO_BITS - 1:0] module_out,
    output wire [IO_BITS - 1:0] module_oe
);
    localparam MODE_NONE = 4'h0;
    localparam MODE_DDS  = 4'h1;

    reg [31:0] dds_code = 0;
    reg [IO_BITS - 1:0] dds_ram[0:255];
    wire [7:0] dds_out;
    wire [7:0] dds_ram_address;
    wire [IO_BITS - 1:0] dds_ram_data;
    reg [IO_BITS - 1:0] dds_result = 0;

    reg prev_sncs = 1;

    reg [35:0] input_reg;
    reg [31:0] output_reg;
    wire [3:0] device_id;
    reg [3:0] mode = MODE_NONE;

    function [IO_BITS - 1:0] module_oe_f(input [3:0] m);
        case (m)
            MODE_DDS: module_oe_f = {IO_BITS{1'b1}};
            default: module_oe_f = 0;
        endcase
    endfunction

    function [IO_BITS - 1:0] module_out_f(input [3:0] m);
        case (m)
            MODE_DDS: module_out_f = dds_result;
            default: module_out_f = 0;
        endcase
    endfunction

    assign module_oe = module_oe_f(mode);
    assign module_out = module_out_f(mode);

    assign device_id = input_reg[3:0];
    assign dds_ram_address = input_reg[11:4];
    assign dds_ram_data = input_reg[IO_BITS + 11:12];
    assign sdo = output_reg[31:31-SPI_BITS+1];

    dds #(.OUT_WIDTH(8)) devide_dds(.clk(clk), .code(dds_code), .out(dds_out));

    always @(posedge sclk) begin
        if (!sncs) begin
            input_reg <= {input_reg[35-SPI_BITS:0], sdi};
            output_reg <= {output_reg[31-SPI_BITS:0], {SPI_BITS{1'b0}}};
        end
        else begin
            case (device_id)
                8: output_reg <= 0;
                default: begin end
            endcase
        end
    end

    always @(posedge clk) begin
        dds_result <= nreset ? dds_ram[dds_out] : {IO_BITS{1'b0}};
        if (!nreset) begin
            mode <= MODE_NONE;
            prev_sncs <= 1;
        end
        else begin
            if (!prev_sncs && sncs) begin // posedge ncs
                case (device_id)
                    0: mode <= input_reg[7:4];
                    1: dds_ram[dds_ram_address] <= dds_ram_data;
                    2: dds_code <= input_reg[35:4];
                    default: begin end
                endcase
            end
            prev_sncs <= sncs;
        end
    end
endmodule
