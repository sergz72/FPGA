module led_handler
#(parameter SPI_BITS = 3, NUM_LEDS = 4, NUM_INTERRUPTS = 4)
(
    //spi
    input wire [SPI_BITS - 1: 0] sdi,
    output wire [SPI_BITS - 1: 0] sdo,
    input wire sclk,
    input wire sncs,
    //leds
    output reg [NUM_LEDS - 1:0] leds,
    //interrupts
    input wire [NUM_INTERRUPTS - 1:0] interrupts
);
    reg [NUM_LEDS - 1:0] input_reg;
    reg [NUM_LEDS + NUM_INTERRUPTS - 1:0] output_reg;

    assign sdo = output_reg[NUM_LEDS + NUM_INTERRUPTS - 1:NUM_LEDS+NUM_INTERRUPTS-SPI_BITS];

    always @(posedge sclk) begin
        if (!sncs) begin
            input_reg <= {input_reg[NUM_LEDS-SPI_BITS - 1:0], sdi};
            output_reg <= {output_reg[NUM_LEDS+NUM_INTERRUPTS-SPI_BITS - 1:0], {SPI_BITS{1'b0}}};
        end
        else begin
            output_reg <= {input_reg, interrupts};
            leds <= input_reg;
        end
    end
endmodule
