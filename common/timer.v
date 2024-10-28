module timer
#(parameter BITS = 32, MHZ_TIMER_BITS = 4, MHZ_TIMER_VALUE = 26)
(
    input wire clk,
    input wire nwr,
    input wire nreset,
    input wire [BITS-1:0] value,
    output reg interrupt = 0,
    input wire interrupt_clear
);
    reg [BITS-1:0] counter = 0;
    reg [MHZ_TIMER_BITS - 1:0] mhz_timer = 0;
    reg done = 1;

    always @(posedge clk) begin
        if (!nreset) begin
            counter <= 0;
            mhz_timer <= 0;
            interrupt <= 0;
            done <= 1;
        end
        else begin
            if (!nwr) begin
                counter <= value;
                mhz_timer <= 0;
                interrupt <= 0;
                done <= 0;
            end
            else if (counter != 0) begin
                if (mhz_timer == MHZ_TIMER_VALUE) begin
                    mhz_timer <= 0;
                    counter <= counter - 1;
                end
                else
                    mhz_timer <= mhz_timer + 1;
            end
            else if (!done) begin
                interrupt <= 1;
                done <= 1;
            end
            else if (interrupt_clear)
                interrupt <= 0;
        end
    end

endmodule
