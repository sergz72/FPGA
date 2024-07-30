`include "alu.vh"

module alu
#(parameter BITS = 16)
(
    input wire clk,
    input wire [`ALU_OPID_WIDTH - 1:0] op_id,
    input wire [BITS - 1:0] op1,
    input wire [BITS - 1:0] op2,
    input wire [BITS - 1:0] op3,
    output reg [BITS - 1:0] out,
    output reg [BITS - 1:0] out2,
    output wire z, // zero flag
    output reg c // carry flag
);
    assign z = out == 0;

    always @(posedge clk) begin
        case (op_id)
            `ALU_OP_TEST, `ALU_OP_AND: out <= op1 & op2; // TEST/AND
            `ALU_OP_NEG: out <= -op1; // NEG OP1
            `ALU_OP_ADD: {c, out} <= {1'b0, op1} + {1'b0, op2}; // OP1 + OP2
            `ALU_OP_ADC: {c, out} <= {1'b0, op1} + {1'b0, op2} + {{BITS{1'b0}}, c}; // OP1 + OP2 + c
            `ALU_OP_SUB, `ALU_OP_CMP: {c, out} <= {1'b0, op1} - {1'b0, op2}; // OP1 - OP2
            `ALU_OP_SBC: {c, out} <= {1'b0, op1} - {1'b0, op2} - {{BITS{1'b0}}, c}; // OP1 - OP2 - c
            `ALU_OP_SHL: out <= op1 << op2; // shift left
            `ALU_OP_SHR: out <= op1 >> op2; // shift right
            `ALU_OP_OR: out <= op1 | op2;
            `ALU_OP_XOR: out <= op1 ^ op2;
            `ALU_OP_MUL: {out2, out} <= op1 * op2;
            `ALU_OP_DIV: {out2, out} <= {op2, op1} / {16'h0, op3};
            `ALU_OP_REM: {out2, out} <= {op2, op1} % {16'h0, op3};
            `ALU_OP_SETF: begin
                c <= op1[1];
                out <= op1[0] ? 0 : 1;
            end
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
    wire [3:0] out, out2;
    wire z, c;

    alu #(.BITS(4)) a(.clk(clk), .op_id(op_id), .op1(op1), .op2(op2), .op3(op3), .out(out), .out2(out2), .z(z), .c(c));

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
        op_id = `ALU_OP_NEG;
        op1 = 1;
        #1
        $display("NEG");
        clk = 1;

        $finish;
    end
endmodule