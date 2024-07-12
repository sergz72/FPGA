`include "alu.vh"

/*

Clock diagramm

1. register to register operation

stage rd alu_clk io_rd io_wr comment
0     0  0       1     1     instruction read
1     0  0       1     1     instruction decode
2     1  1       1     1     alu operation

2. io to register operation

stage rd alu_clk io_rd io_wr comment
0     0  0       1     1     instruction read
1     0  0       0     1     instruction decode, io read init
2     1  0       0     1     io read
3     1  1       1     1     alu operation
4     1  1       1     1     alu result store

3. register to io operation

stage rd alu_clk io_rd io_wr io_data comment
0     0  0       1     1     x        instruction read
1     0  0       1     1     x        instruction decode
2     1  1       1     1     x        alu operation
3     1  1       1     0     data     io write
4     1  1       1     1     data     io data hold

4. operations without ALU (jmp/call/ret/mov register-register or immediate-register)

stage rd alu_clk io_rd io_wr comment
0     0  0       1     1     instruction read
1     0  0       1     1     instruction decode

5. operations without ALU with io read(mov io-register)

stage rd alu_clk io_rd io_wr comment
0     0  0       1     1     instruction read
1     0  0       0     1     instruction decode, io read init
2     1  0       0     1     io read

6. operations without ALU with io write(mov register-io)

stage rd alu_clk io_rd io_wr comment
0     0  0       1     1     instruction read
1     0  0       1     0     instruction decode, io write init
2     1  0       1     1     io data hold

*/

module cpu
#(parameter BITS = 16, STACK_BITS = 4)
(
    input wire clk,
    input wire reset,
    input wire interrupt,
    // External flash interface
    output wire [BITS - 1:0] address,
    input wire [BITS * 2 - 1:0] data,
    // halt flag
    output wire hlt,
    // error flag
    output wire error,
    // IO interface
    output wire io_rd,
    output wire io_wr,
    output wire [BITS - 1:0] io_address,
    inout wire [BITS - 1:0] io_data
);
    //ALU related
    wire c, z;
    wire [BITS-1:0] alu_op1, alu_op2, alu_op3, alu_out, alu_out2, io_data_out;
    wire [`ALU_OPID_WIDTH - 1:0] alu_op_id;
    wire alu_clk, io_data_direction;

    alu #(.BITS(BITS))
        m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out), .out2(alu_out2));
    idecoder #(.BITS(BITS), .STACK_BITS(STACK_BITS))
        m_idecoder(.clk(clk), .reset(reset), .instruction(data), .address(address), .io_address(io_address), .alu_op_id(alu_op_id),
                    .alu_op1(alu_op1), .alu_op2(alu_op2), .alu_op3(alu_op3), .hlt(hlt), .c(c), .z(z), .alu_out(alu_out), .alu_out2(alu_out2),
                    .io_rd(io_rd), .io_wr(io_wr), .io_data_in(io_data), .io_data_out(io_data_out), .alu_clk(alu_clk),
                    .io_data_direction(io_data_direction), .error(error), .interrupt(interrupt));
    
    assign io_data = io_data_direction ? {BITS{1'bz}} : io_data_out;

endmodule
