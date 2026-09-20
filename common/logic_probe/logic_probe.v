module logic_probe
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
  COUNTERS_WIDTH = 28,
  TIME_PERIOD = 2700000
)
(
    input wire clk,
    input wire nreset,
    input wire comp_data_hi,
    input wire comp_data_lo,
    output wire data,
    input wire clk_in,
    output reg interrupt = 0,
    input wire interrupt_clear
);
    reg[COUNTERS_WIDTH-1:0] counter_low, counter_high, counter_z, freq_counter_low, freq_counter_high, freq_counter_rs, time_counter;
    reg[COUNTERS_WIDTH*6-1:0] output_register;
    reg prev_clk_in;
    reg prev_interrupt;
    reg rs, nrs;
    wire freq_counter_high_clk, freq_counter_low_clk, freq_counter_rs_clk;

    assign data = output_register[COUNTERS_WIDTH*6-1];
    assign freq_counter_high_clk = interrupt ? clk : comp_data_hi;
    assign freq_counter_low_clk = interrupt ? clk : comp_data_lo;
    assign freq_counter_rs_clk = interrupt ? clk : rs;

    // rs trigger
    nor (rs, comp_data_lo, nrs);
    nor (nrs, comp_data_hi, rs);

    always @(posedge clk) begin
        if (!nreset || interrupt_clear) begin
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
        if (interrupt != prev_interrupt && interrupt) //posedge interrupt
            output_register <= {counter_low, counter_high, counter_z, freq_counter_low, freq_counter_high, freq_counter_rs};
        else if (clk_in != prev_clk_in && clk_in) // posedge clk_in
            output_register <= {output_register[COUNTERS_WIDTH*6-2:0], 1'b0};
        prev_clk_in <= clk_in;
        prev_interrupt <= interrupt;
    end

    always @(posedge clk) begin
        if (!nreset || interrupt_clear)
            counter_low <= 0;
        else begin
            if (comp_data_lo & !interrupt)
                counter_low <= counter_low + 1;
        end
    end

    always @(posedge clk) begin
        if (!nreset || interrupt_clear)
            counter_high <= 0;
        else begin
            if (comp_data_hi & !interrupt)
                counter_high <= counter_high + 1;
        end
    end

    always @(posedge clk) begin
        if (!nreset || interrupt_clear)
            counter_z <= 0;
        else begin
            if (!comp_data_hi & !comp_data_lo & !interrupt)
                counter_z <= counter_z + 1;
        end
    end

    always @(posedge freq_counter_high_clk) begin
        if (interrupt_clear)
            freq_counter_high <= 0;
        else begin
            if (!interrupt)
                freq_counter_high <= freq_counter_high + 1;
        end
    end

    always @(posedge freq_counter_low_clk) begin
        if (interrupt_clear)
            freq_counter_low <= 0;
        else begin
            if (!interrupt)
                freq_counter_low <= freq_counter_low + 1;
        end
    end

    always @(posedge freq_counter_rs_clk) begin
        if (interrupt_clear)
            freq_counter_rs <= 0;
        else begin
            if (!interrupt)
                freq_counter_rs <= freq_counter_rs + 1;
        end
    end
endmodule
