module main
#(parameter RAM_BITS = 12, RESET_BIT = 19, TIME_PERIOD = 2700000)
(
    input wire clk,
    input wire clk_probe,
    output wire nhlt,
    output wire nwfi,
    inout wire scl,
    inout wire sda,
    input wire button1,
    input wire button2,
    output reg [4:0] dac1_code,
    output reg [4:0] dac2_code,
    input wire comp_out_hi,
    input wire comp_out_lo
);
    wire [15:0] address;
    wire nwr, hlt;
    wire [15:0] data_in, probe_data, data_selector;
    reg [15:0] data_out;
    reg nreset = 0;
    reg [RESET_BIT:0] counter = 0;
    wire interrupt;
    wire in_interrupt;
    reg interrupt_clear = 0;
    wire wfi;
    wire mem_valid;
    reg mem_ready = 0;
    reg scl_out = 1;
    reg sda_out = 1;

    wire probe_data_request, probe_data_ready, probe_selected;

    tiny16 #(.RAM_BITS(RAM_BITS)) cpu(.clk(clk), .nwr(nwr), .nreset(nreset), .address(address), .data_in(data_selector), .data_out(data_in),
                                        .hlt(hlt), .interrupt(interrupt), .in_interrupt(in_interrupt), .wfi(wfi), .mem_valid(mem_valid), .mem_ready(mem_ready));

    logic_probe #(.TIME_PERIOD(TIME_PERIOD))
        probe(.clk(clk_probe), .nreset(nreset), .comp_data_hi(comp_out_hi), .comp_data_lo(comp_out_lo), .data(probe_data), .address(address[3:0]),
                .data_request(probe_data_request), .data_ready(probe_data_ready), .interrupt(interrupt), .interrupt_clear(interrupt_clear));

    assign nhlt = !hlt;
    assign nwfi = !wfi;

    assign scl = scl_out ? 1'bz : 0;
    assign sda = sda_out ? 1'bz : 0;

    assign probe_selected = address[15:14] == 1;

    assign probe_data_request = mem_valid & probe_selected;

    assign data_selector = probe_selected ? probe_data : data_out;

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
                        {interrupt_clear, scl_out, sda_out} <= data_in[2:0];
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
