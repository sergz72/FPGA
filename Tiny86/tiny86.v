module tiny86
(
    input wire clk,
    input wire reset,
    output reg hlt,
    output reg error,
    output wire [15:0] address,
    input wire [7:0] data_in,
    output wire [7:0] data_out,
    output wire rd,
    output reg wr,
    input wire ready
);
    localparam MICROCODE_WIDTH = 16;
    localparam MICROCODE_SIZE = 512;

    localparam AX = 0;
    localparam BX = 1;
    localparam CX = 2;
    localparam DX = 3;
    localparam SI = 4;
    localparam DI = 5;
    localparam BP = 6;
    localparam SP = 7;

    reg [7:0] instructions [0:3];
    reg [15:0] registers [0:7];
    reg [15:0] pc;
    reg [3:0] stage;
    reg [3:0] stage2;
    reg start = 0;
    reg [MICROCODE_WIDTH - 1:0] microcode [0:MICROCODE_SIZE - 1];
    reg [MICROCODE_WIDTH - 1:0] current_microinstruction = 0;

    wire [1:0] instruction_length;

    initial begin
        $readmemh("microcode.mem", microcode);
    end

    always @(negedge clk) begin
        if (stage == 7) begin
            stage <= 0;
            start <= reset;
        end
        else
            stage <= stage + 1;
    end

    assign rd = !start || !stage[0];

    assign instruction_length = current_microinstruction[1:0];

    always @(posedge clk) begin
        if (reset == 0) begin
            pc <= 0;
            instructions[0] <= 0;
            stage <= 0;
        end
        else if (start) begin
            case (stage)
                0: begin
                    instructions[0] <= data_in;
                    current_microinstruction <= microcode[data_in];
                    stage2 <= 0;
                end
                2,4,6: begin
                    if (instruction_length > 0) begin
                        instructions[instruction_length] = data_in;
                        instruction_length <= instruction_length - 1;
                    end
                    else begin
                        case (stage2)
                            0: begin
                            end
                        endcase
                        stage2 <= stage2 + 1;
                    end
                end
            endcase
        end
    end
endmodule
