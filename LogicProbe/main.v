module logicProbe
/*
             ----------
DAC_OUT------|- COMP1 |
             |        |-----COMP_HI
IN------+----|+       |
        |    ----------
        |
        |    ----------
        +----|- COMP2 |
             |        |-----COMP_LO
0.4v---------|+       |
             ----------

COMP_LO = IN < 0.4v
COMP_HI = IN > DAC_OUT

*/
#(parameter BITS = 16)
(
    input wire clk,
    input wire [BITS - 1:0] comp_data_hi,
    input wire [BITS - 1:0] comp_data_lo,
    input wire [1:0] mode;
    output wire [3:0] dac_value; // R2R DAC 4 bit
    output wire [BITS - 1:0] led_cathodes = 0;
    output wire [2:0] led_anodes = 0;
);
    function [3:0] build_dac_value(input [1:0] mode)
        case (mode)
            0: build_dac_value = 7; // 1.4v - for 1.8v logic
            1: build_dac_value = 10; // 2.0v - for 2.5v logic
            default: build_dac_value = 12; // 2.4v - for 3.3/5v logic
        endcase
    endfunction

    assign dac_value = build_dac_value(mode);
    
endmodule
