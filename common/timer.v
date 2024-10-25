module timer
#(parameter BITS = 32)
(
    input wire clk,
    input wire nwr,
    input wire nreset,
    input wire [BITS-1:0] value,
    output reg interrupt = 0,
    input wire interrupt_clear
);
    reg [BITS-1:0] counter = 0;
    reg done = 0;

    always @(posedge clk) begin
        if (!nreset) begin
            counter <= 0;
            interrupt <= 0;
            done <= 1;
        end
        else if (!nwr) begin
            counter <= value;
            interrupt <= 0;
            done <= 0;
        end
        else if (counter != 0)
            counter <= counter - 1;
        else if (interrupt_clear)
            interrupt <= 0;
        else if (!done) begin
            interrupt <= 1;
            done <= 1;
        end
    end

endmodule
