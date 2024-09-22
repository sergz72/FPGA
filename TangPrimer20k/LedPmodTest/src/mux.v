module mux
#(parameter WIDTH = 4, SEL_BITS = 1)
(
    input wire [(WIDTH << SEL_BITS) - 1:0] code,
    input wire [SEL_BITS - 1:0] sel,
    output wire [WIDTH - 1:0] out
);
    function [WIDTH - 1:0] f2(input [(WIDTH << 2) - 1:0] code, input [1:0] sel);
        case (sel)
            0: f2 = code[WIDTH - 1:0];
            1: f2 = code[WIDTH * 2 - 1:WIDTH];
            2: f2 = code[WIDTH * 3 - 1:WIDTH * 2];
            3: f2 = code[WIDTH * 4 - 1:WIDTH * 3];
        endcase
    endfunction

    function [WIDTH - 1:0] f3(input [(WIDTH << 3) - 1:0] code, input [2:0] sel);
        case (sel)
            0: f3 = code[WIDTH - 1:0];
            1: f3 = code[WIDTH * 2 - 1:WIDTH];
            2: f3 = code[WIDTH * 3 - 1:WIDTH * 2];
            3: f3 = code[WIDTH * 4 - 1:WIDTH * 3];
            4: f3 = code[WIDTH * 5 - 1:WIDTH * 4];
            5: f3 = code[WIDTH * 6 - 1:WIDTH * 5];
            6: f3 = code[WIDTH * 7 - 1:WIDTH * 6];
            7: f3 = code[WIDTH * 8 - 1:WIDTH * 7];
        endcase
    endfunction

    generate
        case (SEL_BITS)
            1: assign out = sel ? code[(WIDTH << 1) - 1:WIDTH] : code[WIDTH - 1: 0];
            2: assign out = f2(code, sel);
            3: assign out = f3(code, sel);
        endcase
    endgenerate
endmodule
