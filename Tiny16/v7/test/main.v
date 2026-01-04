module main
#(parameter RAM_BITS = 12, RESET_BIT = 3, TIMER_BIT = 23, COUNTER_BITS = 24)
(
    input wire clk,
    output wire nerror,
    output wire nhlt,
    output wire nwfi,
    output reg led = 1
);
    wire [15:0] address;
    wire nwr, hlt, error;
    wire [15:0] data_in;
    reg [15:0] data_out = 16'h55AA;
    reg nreset = 0;
    reg [COUNTER_BITS - 1:0] counter = 0;
    reg interrupt = 0;
    wire in_interrupt;
    wire wfi;
    wire mem_valid;
    reg mem_ready = 0;

    tiny16 #(.RAM_BITS(RAM_BITS)) cpu(.clk(clk), .nwr(nwr), .nreset(nreset), .address(address), .data_in(data_out), .data_out(data_in), .error(error),
                                        .hlt(hlt), .interrupt(interrupt), .in_interrupt(in_interrupt), .wfi(wfi), .mem_valid(mem_valid), .mem_ready(mem_ready));

    assign nhlt = !hlt;
    assign nwfi = !wfi;
    assign nerror = !error;

    always @(posedge clk) begin
        if (counter[RESET_BIT])
            nreset <= 1;
        counter <= counter + 1;
    end

    always @(negedge clk) begin
        if (in_interrupt)
            interrupt <= 0;
        else if (counter[TIMER_BIT:0] == 0)
            interrupt <= 1;
    end

    always @(negedge clk) begin
        mem_ready <= mem_valid;
        if (!nwr && mem_valid)
            led <= data_in[0];
    end
endmodule
