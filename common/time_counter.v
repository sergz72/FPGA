module time_counter
#(parameter BITS = 32, MHZ_TIMER_BITS = 4, MHZ_TIMER_VALUE = 26)
(
    input wire clk,
    input wire nrd,
    input wire nreset,
    output reg [BITS-1:0] value
);
    reg [BITS-1:0] counter = 0;
    reg [MHZ_TIMER_BITS - 1:0] mhz_timer = 0;

    always @(posedge clk) begin
        if (!nreset) begin
            counter <= 0;
            mhz_timer <= 0;
        end
        else begin
            if (mhz_timer == MHZ_TIMER_VALUE) begin
                mhz_timer <= 0;
                counter <= counter + 1;
            end
            else
                mhz_timer <= mhz_timer + 1;
        end
    end

    always @(negedge clk) begin
        if (nrd)
            value <= counter;
    end

endmodule
