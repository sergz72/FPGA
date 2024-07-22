module LedTest
(
        input wire clk,
        output wire led_g,
        output wire led_r,
        output wire led_b
);
        reg [25:0] counter = 0;
        
        assign led_r = counter[25:24] != 0;
        assign led_g = counter[25:24] != 1;
        assign led_b = counter[25:24] != 2;
        
        always @(posedge clk) begin
                counter <= counter + 1;
        end
        
endmodule
