module pwm3
#(parameter WIDTH = 32)
(
    input wire clk,
    input wire nreset,
    input wire req,
    output reg ack = 0,
    input wire [WIDTH-1:0] data,
    input wire address,
    output reg out = 0
);
    reg [WIDTH-1:0] counter = 0;
    reg [WIDTH-1:0] period_reg = 0;
    reg [WIDTH-1:0] cmp_reg = 0;
    wire nreset_or_req;

    assign nreset_or_req = !nreset | req;

    always @(posedge clk) begin
        ack <= nreset & req;
        if (nreset_or_req || counter == 0)
            out <= 0;
        else if (counter == cmp_reg)
            out <= 1;
        if (nreset_or_req || counter == period_reg)
            counter <= 0;
        else
            counter <= counter + 1;
        if (!nreset)
            period_reg <= 0;
        else if (req) begin
            if (address)
                cmp_reg <= data;
            else
                period_reg <= data;
        end
    end

endmodule
