module main
#(parameter RAM_BITS = 12, RESET_BIT = 19)
(
    input wire clk,
    output wire nhlt,
    output wire nwfi,
    inout wire scl,
    inout wire sda,
    input wire button1,
    input wire button2,
    output reg [4:0] dac1_code,
    output reg [4:0] dac2_code
);
    wire [15:0] address;
    wire nwr, hlt;
    wire [15:0] data_in;
    reg [15:0] data_out;
    reg nreset = 0;
    reg [RESET_BIT:0] counter = 0;
    reg interrupt = 0;
    wire in_interrupt;
    wire wfi;
    wire mem_valid;
    reg mem_ready = 0;
    reg scl_out = 1;
    reg sda_out = 1;

    tiny16 #(.RAM_BITS(RAM_BITS)) cpu(.clk(clk), .nwr(nwr), .nreset(nreset), .address(address), .data_in(data_out), .data_out(data_in),
                                        .hlt(hlt), .interrupt(interrupt), .in_interrupt(in_interrupt), .wfi(wfi), .mem_valid(mem_valid), .mem_ready(mem_ready));

    assign nhlt = !hlt;
    assign nwfi = !wfi;

    assign scl = scl_out ? 1'bz : 0;
    assign sda = sda_out ? 1'bz : 0;

    always @(posedge clk) begin
        if (counter[RESET_BIT])
            nreset <= 1;
        counter <= counter + 1;
    end

    always @(negedge clk) begin
        mem_ready <= mem_valid;
        if (mem_valid) begin
            case (address[15:14])
                0: begin // i2c
                    if (nwr)
                        data_out <= {12'b0, button1, button2, scl, sda};
                    else
                        {scl_out, sda_out} <= data_in[1:0];
                end
                1: begin // logic probe
                end
                2: begin // dac1
                    if (!nwr)
                        dac1_code <= data_in[4:0];
                end
                3: begin // dac2
                    if (!nwr)
                        dac2_code <= data_in[4:0];
                end
            endcase
        end
    end
endmodule
