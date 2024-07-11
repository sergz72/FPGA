`include "alu.vh"

module alu
#(parameter BITS = 16)
(
    input wire clk,
    input wire [`ALU_OPID_WIDTH - 1:0] op_id,
    input wire [BITS - 1:0] op1,
    input wire [BITS - 1:0] op2,
    output reg [BITS - 1:0] out,
    output wire z, // zero flag
    output reg c // carry flag
);
    assign z = out == 0;

    always @(posedge clk) begin
        case (op_id)
            `ALU_OP_TEST: out <= op1; // TEST OP1
            `ALU_OP_NOT: out <= ~op1; // NOT OP1
            `ALU_OP_NEG: out <= -op1; // NEG OP1
            `ALU_OP_ADD: {c, out} <= {1'b0, op1} + {1'b0, op2}; // OP1 + OP2
            `ALU_OP_ADC: {c, out} <= {1'b0, op1} + {1'b0, op2} + {{BITS{1'b0}}, c}; // OP1 + OP2 + c
            `ALU_OP_SUB: {c, out} <= {1'b0, op1} - {1'b0, op2}; // OP1 - OP2
            `ALU_OP_SBC: {c, out} <= {1'b0, op1} - {1'b0, op2} - {{BITS{1'b0}}, c}; // OP1 - OP2 - c
            `ALU_OP_SHL: out <= op1 << 1; // shift left
            `ALU_OP_SHR: out <= op1 >> 1; // shift right
            // NOP
            default: begin end
        endcase
    end
endmodule

module alu_tb;
    reg clk;
    reg [3:0] op1;
    reg [3:0] op2;
    reg [3:0] op3;
    reg [`ALU_OPID_WIDTH - 1:0] op_id;
    wire [3:0] out;
    wire z, c;

    alu #(.BITS(4)) a(.clk(clk), .op_id(op_id), .op1(op1), .op2(op2), .op3(op3), .out(out), .z(z), .c(c));

    initial begin
        $monitor("time=%t op_id=%d op1=%d op2=%d op3=%d out=%d z=%d c=%d", $time, op_id, op1, op2, op3, out, z, c);
        
        clk = 0;
        op_id = `ALU_OP_TEST;
        op1 = 1;
        #1
        $display("TEST");
        clk = 1;

        #1
        clk = 0;
        op_id = `ALU_OP_NOT;
        op1 = 1;
        #1
        $display("NOT");
        clk = 1;

        #1
        clk = 0;
        op_id = `ALU_OP_NEG;
        op1 = 1;
        #1
        $display("NEG");
        clk = 1;

        $finish;
    end
endmodule