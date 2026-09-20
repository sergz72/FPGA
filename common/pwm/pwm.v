module pwm
#(parameter WIDTH = 32)
(
    input wire clk,
    input wire nreset,
    input wire [WIDTH-1:0] period,
    input wire [WIDTH-1:0] duty,
    output wire out
);
    reg [WIDTH-1:0] counter = 0;

    assign out = nreset && (counter < duty);

    always @(posedge clk) begin
        if (!nreset || counter >= period - 1)
            counter <= 0;
        else
            counter <= counter + 1;
    end

endmodule
