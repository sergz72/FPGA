module logicProbe
/*
             ----------
DAC1_OUT-----|- COMP1 |
             |        |-----COMP_HI
IN------+----|+       |
        |    ----------
        |
        |    ----------
        +----|- COMP2 |
             |        |-----COMP_LO
DAC2_OUT-----|+       |
             ----------

COMP_LO = IN < DAC2_OUT
COMP_HI = IN > DAC1_OUT

*/
#(parameter BITS = 16)
(
    input wire clk,
    input wire [BITS - 1:0] comp_data_hi,
    input wire [BITS - 1:0] comp_data_lo,
    input wire [1:0] mode;
    output wire dac_clk;
    output wire dac_din;
    output wire dac_sync;
    output wire [BITS - 1:0] led_cathodes = 0;
    output wire [2:0] led_anodes = 0;
);
    reg update;

    always @(posedge clk) begin
        
    end
endmodule
