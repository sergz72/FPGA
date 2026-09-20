module logic_probe_spi
/*
             ----------
DAC_OUT_HI---|- COMP1 |
             |        |-----COMP_HI
IN------+----|+       |
        |    ----------
        |
        |    ----------
        +----|- COMP2 |
             |        |-----COMP_LO
DAC_OUT_LO---|+       |
             ----------

COMP_LO = IN < DAC_OUT_LO
COMP_HI = IN > DAC_OUT_HI

*/
#(parameter
  FREQ_COUNTERS_WIDTH = 24,
  TIME_COUNTERS_WIDTH = 21,
  TIME_PERIOD = 1200000
)
(
    input  wire clk,
    input  wire comp_data_hi,
    input  wire comp_data_lo,
    output wire spi_tx,
    input  wire spi_sck,
    input  wire spi_cs,
    output reg interrupt = 0,
    output reg led_zero = 0,
    output reg led_z = 0,
    output reg led_one = 0,
    output wire led_pulse
);
    localparam SPI_DATA_REG_WIDTH = FREQ_COUNTERS_WIDTH*3+24;
    localparam LED_COUNTER_WIDTH = TIME_COUNTERS_WIDTH-7;

    reg[TIME_COUNTERS_WIDTH-1:0] counter_low, counter_high, counter_z, time_counter;
    reg[FREQ_COUNTERS_WIDTH-1:0] freq_counter_low, freq_counter_high, freq_counter_rs;
    wire reset, rs_clock;
    reg rs;
    wire freq_counter_high_clk, freq_counter_low_clk, freq_counter_rs_clk;
    wire[7:0] counter_low_hi8, counter_high_hi8, counter_z_hi8;
    wire [LED_COUNTER_WIDTH-1:0] led_counter;
    reg[7:0] led_zero_compare, led_z_compare, led_one_compare;

    reg[SPI_DATA_REG_WIDTH-1:0] spi_data_reg;
    reg spi_cs_prev = 1;
    reg spi_sck_prev = 0;
    wire spi_data_load, spi_data_shift;

    reg pulse1, pulse2, pulse3;

    assign freq_counter_high_clk = interrupt ? clk : comp_data_hi;
    assign freq_counter_low_clk = interrupt ? clk : comp_data_lo;
    assign freq_counter_rs_clk = interrupt ? clk : rs;

    // rising edge of cpi_cs
    assign reset = spi_cs && !spi_cs_prev;
    // falling edge of cpi_cs
    assign spi_data_load = !spi_cs && spi_cs_prev;
    // rising edge of cpi_sck
    assign spi_data_shift = !spi_cs && (!spi_sck_prev && spi_sck);
    assign spi_tx = spi_data_reg[SPI_DATA_REG_WIDTH-1];

    assign counter_low_hi8 = counter_low[TIME_COUNTERS_WIDTH-1:TIME_COUNTERS_WIDTH-8];
    assign counter_high_hi8 = counter_high[TIME_COUNTERS_WIDTH-1:TIME_COUNTERS_WIDTH-8];
    assign counter_z_hi8 = counter_z[TIME_COUNTERS_WIDTH-1:TIME_COUNTERS_WIDTH-8];

    assign led_counter = time_counter[LED_COUNTERS_WIDTH-1:0];

    assign led_pulse = pulse1 | pulse2 | pulse3;

    assign rs_clock = comp_data_lo | comp_data_hi;

    // rs trigger
    always @(posedge rs_clock) begin
        rs <= comp_data_lo;
    end

    always @(posedge clk) begin
        if (reset) begin
            time_counter <= 0;
            interrupt <= 0;
        end
        else begin
            if (time_counter == TIME_PERIOD) begin
                interrupt <= 1;
                led_zero <= 0;
                led_z <= 0;
                led_one <= 0;
                if (spi_data_load) begin
                    spi_data_reg <= {counter_high_hi8, counter_low_hi8, counter_z_hi8, freq_counter_low, freq_counter_high, freq_counter_rs};
                    led_zero_compare <= counter_low_hi8;
                    led_z_compare <= counter_z_hi8;
                    led_one_compare <= counter_high_hi8;
                end
                else if (spi_data_shift)
                    spi_data_reg <= {spi_data_reg[SPI_DATA_REG_WIDTH-2:0], 1'b0};
            end
            else begin
                if (led_counter == led_zero_compare)
                    led_zero <= 0;
                else if (led_counter == 0)
                    led_zero <= 1;
                if (led_counter == led_z_compare)
                    led_z <= 0;
                else if (led_counter == 0)
                    led_z <= 1;
                if (led_counter == led_one_compare)
                    led_one <= 0;
                else if (led_counter == 0)
                    led_one <= 1;
                time_counter <= time_counter + 1;
            end
        end
        spi_cs_prev <= spi_cs;
        spi_sck_prev <= spi_sck;
    end

    always @(posedge clk) begin
        if (reset)
            counter_low <= 0;
        else begin
            if (comp_data_lo & !interrupt)
                counter_low <= counter_low + 1;
        end
    end

    always @(posedge clk) begin
        if (reset)
            counter_high <= 0;
        else begin
            if (comp_data_hi & !interrupt)
                counter_high <= counter_high + 1;
        end
    end

    always @(posedge clk) begin
        if (reset)
            counter_z <= 0;
        else begin
            if (!comp_data_hi & !comp_data_lo & !interrupt)
                counter_z <= counter_z + 1;
        end
    end

    always @(posedge freq_counter_high_clk) begin
        if (reset) begin
            freq_counter_high <= 0;
            pulse1 <= 0;
        end
        else begin
            if (!interrupt) begin
                freq_counter_high <= freq_counter_high + 1;
                pulse1 <= 1;
            end
        end
    end

    always @(posedge freq_counter_low_clk) begin
        if (reset) begin
            freq_counter_low <= 0;
            pulse2 <= 0;
        end
        else begin
            if (!interrupt) begin
                freq_counter_low <= freq_counter_low + 1;
                pulse2 <= 1;
            end
        end
    end

    always @(posedge freq_counter_rs_clk) begin
        if (reset) begin
            freq_counter_rs <= 0;
            pulse3 <= 0;
        end
        else begin
            if (!interrupt) begin
                freq_counter_rs <= freq_counter_rs + 1;
                pulse3 <= 1;
            end
        end
    end
endmodule
