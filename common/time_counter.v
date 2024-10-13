module time_counter
#(parameter BITS = 32)
(
    input wire clk,
    input wire nrd,
    input wire nreset,
    output reg [BITS-1:0] value
);
    reg [BITS-1:0] counter = 0;

    always @(posedge clk) begin
        if (!nreset)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    always @(negedge clk) begin
        if (nrd)
            value <= counter;
    end

endmodule
