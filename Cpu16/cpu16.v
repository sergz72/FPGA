`include "alu.vh"

/*

Clock diagramm

1. register to register operation

stage rd alu_clk io_rd io_wr comment
0     0  0       1     1     instruction read
1     0  0       1     1     instruction decode
2     1  1       1     1     alu operation

1. io to register operation

stage rd alu_clk io_rd io_wr comment
0     0  0       1     1     instruction read
1     0  0       0     1     instruction decode, io read init
2     1  0       0     1     io read
3     1  1       1     1     alu operation

1. register to io operation

stage rd alu_clk io_rd io_wr io_data comment
0     0  0       1     1     x        instruction read
1     0  0       1     1     x        instruction decode
2     1  1       1     1     x        alu operation
3     1  1       1     0     data     io write
4     1  1       1     1     data     io data hold

*/

module cpu
#(parameter BITS = 16)
(
    input wire clk,
    input wire reset,
    // External flash interface
    output wire [BITS - 1:0] address,
    input wire [BITS * 2 - 1:0] data,
    output wire rd,
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
    wire [BITS-1:0] alu_op1, alu_op2, alu_op3, alu_out, next_address, io_data_out;
    wire [`ALU_OPID_WIDTH - 1:0] alu_op_id;
    wire alu_clk, io_data_direction;
    wire [2:0] max_stage;

    // execution stage
    reg [2:0] stage;
    reg idecoder_reset;

    alu #(.BITS(BITS)) m_alu(.clk(alu_clk), .op_id(alu_op_id), .op1(alu_op1), .op2(alu_op2), .op3(alu_op3), .c(c), .z(z), .out(alu_out));
    idecoder #(.BITS(BITS))
        m_idecoder(.stage(stage), .reset(idecoder_reset), .instruction(data), .alu_op_id(alu_op_id), .address(address), .io_address(io_address),
                    .alu_op1(alu_op1), .alu_op2(alu_op2), .alu_op3(alu_op3), .hlt(hlt), .c(c), .z(z), .alu_out(alu_out), .io_rd(io_rd),
                    .io_wr(io_wr), .io_data_in(io_data), .io_data_out(io_data_out), .alu_clk(alu_clk), .io_data_direction(io_data_direction),
                    .max_stage(max_stage), .error(error));
    
    assign rd = ~reset | stage[1];
    assign io_data = io_data_direction ? {BITS{1'bz}} : io_data_out;

    always @(posedge clk) begin
        if (reset == 0) begin
            idecoder_reset <= 0;
            stage <= 0;
        end
        else begin
            idecoder_reset <= 1;
            if (hlt == 0) begin
                if (stage == max_stage)
                    stage <= 0;
                else
                    stage <= stage + 1;
            end
        end
    end
endmodule
