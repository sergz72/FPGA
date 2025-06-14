module pwm2
#(parameter WIDTH = 32)
(
    input wire clk,
    input wire nreset,
    input wire nwr,
    output reg wack = 0,
    input wire [WIDTH-1:0] period,
    input wire [WIDTH-1:0] cmp,
    output reg out = 0
);
    reg [WIDTH-1:0] counter = 0;
    reg [WIDTH-1:0] period_reg = 0;
    reg [WIDTH-1:0] cmp_reg = 0;
    wire nreset_or_nwr;

    assign nreset_or_nwr = !nreset | !nwr;

    always @(posedge clk) begin
        wack <= nreset & !nwr;
        if (nreset_or_nwr || counter == 0)
            out <= 0;
        else if (counter == cmp_reg)
            out <= 1;
        if (nreset_or_nwr || counter == period_reg)
            counter <= 0;
        else
            counter <= counter + 1;
        if (!nreset)
            period_reg <= 0;
        else if (!nwr) begin
            period_reg <= period;
            cmp_reg <= cmp;
        end
    end

endmodule
