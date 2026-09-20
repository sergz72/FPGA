module logic_probe_spi_dac
/*
             ----------
DAC_OUT_HI---|+ COMP1 |
             |        |-----COMP_HI
IN------+----|-       |
        |    ----------
        |
        |    ----------
        +----|+ COMP2 |
             |        |-----COMP_LO
DAC_OUT_LO---|-       |
             ----------

COMP_LO = IN > DAC_OUT_LO
COMP_HI = IN < DAC_OUT_HI

*/
#(parameter
  FREQ_COUNTERS_WIDTH = 24,
  TIME_COUNTERS_WIDTH = 23,
  TIME_PERIOD = 7200000,
  DAC_BITS = 4
)
(
    input  wire clk,
    input  wire comp_data_hi,
    input  wire comp_data_lo,
    output wire spi_tx,
    input  wire spi_rx,
    input  wire spi_sck,
    input  wire spi_cs,
    output reg interrupt = 0,
    output reg[DAC_BITS-1:0] dac_out
);
    localparam SPI_DATA_REG_WIDTH = FREQ_COUNTERS_WIDTH*3+24;
    localparam LED_COUNTER_WIDTH = TIME_COUNTERS_WIDTH-7;

    reg[TIME_COUNTERS_WIDTH-1:0] counter_low, counter_high, counter_z, time_counter;
    reg[FREQ_COUNTERS_WIDTH-1:0] freq_counter_low, freq_counter_high, freq_counter_rs;
    wire reset, rs_clock;
    reg rs;
    wire freq_counter_high_clk, freq_counter_low_clk, freq_counter_rs_clk;
    wire[7:0] counter_low_hi8, counter_high_hi8, counter_z_hi8;

    reg[DAC_BITS-1:0] dac_reg;

    reg[SPI_DATA_REG_WIDTH-1:0] spi_data_reg;
    reg spi_cs_prev = 1;
    reg spi_sck_prev = 0;
    wire spi_data_load, spi_data_shift;

    assign freq_counter_high_clk = interrupt ? clk : !comp_data_hi;
    assign freq_counter_low_clk = interrupt ? clk : !comp_data_lo;
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

    assign rs_clock = comp_data_lo & comp_data_hi;

    // rs trigger
    always @(negedge rs_clock) begin
        rs <= comp_data_lo;
    end

    always @(posedge clk) begin
        if (spi_data_load | spi_data_shift) begin
            spi_data_reg <= spi_data_load 
                ? {counter_high_hi8, counter_low_hi8, counter_z_hi8, freq_counter_low, freq_counter_high, freq_counter_rs}
                : {spi_data_reg[SPI_DATA_REG_WIDTH-2:0], 1'b0};
        end
        if (spi_data_shift)
            dac_reg <= {dac_reg[DAC_BITS-2:0], spi_rx};
        if (reset)
            dac_out <= dac_reg;
        spi_cs_prev <= spi_cs;
        spi_sck_prev <= spi_sck;
    end

    always @(posedge clk) begin
        if (reset) begin
            time_counter <= 0;
            interrupt <= 0;
        end
        else begin
            if (time_counter == TIME_PERIOD)
                interrupt <= 1;
            else
                time_counter <= time_counter + 1;
        end
    end

    always @(posedge clk) begin
        if (reset)
            counter_low <= 0;
        else begin
            if (!comp_data_lo & !interrupt)
                counter_low <= counter_low + 1;
        end
    end

    always @(posedge clk) begin
        if (reset)
            counter_high <= 0;
        else begin
            if (!comp_data_hi & !interrupt)
                counter_high <= counter_high + 1;
        end
    end

    always @(posedge clk) begin
        if (reset)
            counter_z <= 0;
        else begin
            if (comp_data_hi & comp_data_lo & !interrupt)
                counter_z <= counter_z + 1;
        end
    end

    always @(posedge freq_counter_high_clk) begin
        if (reset)
            freq_counter_high <= 0;
        else begin
            if (!interrupt)
                freq_counter_high <= freq_counter_high + 1;
        end
    end

    always @(posedge freq_counter_low_clk) begin
        if (reset)
            freq_counter_low <= 0;
        else begin
            if (!interrupt)
                freq_counter_low <= freq_counter_low + 1;
        end
    end

    always @(posedge freq_counter_rs_clk) begin
        if (reset)
            freq_counter_rs <= 0;
        else begin
            if (!interrupt)
                freq_counter_rs <= freq_counter_rs + 1;
        end
    end
endmodule
