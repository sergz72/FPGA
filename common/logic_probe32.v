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
    output reg [31:0] data,
    input wire [2:0] address,
    input wire data_request,
    output reg data_ready = 0,
    output reg interrupt = 0,
    input wire interrupt_clear
);
    localparam TO16 = 32 - COUNTERS_WIDTH;

    reg[COUNTERS_WIDTH-1:0] counter_low, counter_high, counter_z, freq_counter_low, freq_counter_high, freq_counter_rs, time_counter;
    reg rs;
    wire freq_counter_high_clk, freq_counter_low_clk, freq_counter_rs_clk;

    assign freq_counter_high_clk = interrupt ? clk : comp_data_hi;
    assign freq_counter_low_clk = interrupt ? clk : comp_data_lo;
    assign freq_counter_rs_clk = interrupt ? clk : rs;

    always @ (posedge clk) // rs trigger simulation
        rs <= comp_data_hi | (rs & !comp_data_lo);

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
        data_ready <= data_request;
        if (data_request) begin
            case (address)
                0: data <= {counter_high[COUNTERS_WIDTH-1:COUNTERS_WIDTH-16], counter_low[COUNTERS_WIDTH-1:COUNTERS_WIDTH-16]};
                1: data <= {16'h0, counter_z[COUNTERS_WIDTH-1:COUNTERS_WIDTH-16]};
                2: data <= {{{TO16{1'b0}}, freq_counter_low[COUNTERS_WIDTH-1:16]}, freq_counter_low[15:0]};
                3: data <= {{{TO16{1'b0}}, freq_counter_high[COUNTERS_WIDTH-1:16]}, freq_counter_high[15:0]};
                default: data <= {{{TO16{1'b0}}, freq_counter_rs[COUNTERS_WIDTH-1:16]}, freq_counter_rs[15:0]};
            endcase
        end
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
