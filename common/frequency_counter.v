module frequency_counter_binary
#(parameter CLK_COUNTER_WIDTH = 32, COUNTER_WIDTH = 32)
(
    input wire clk,
    input wire iclk,
    input wire reset,
    input wire [CLK_COUNTER_WIDTH - 1:0] reset_value_div_2,
    output reg [COUNTER_WIDTH - 1:0] code,
    output reg update
);
    reg [CLK_COUNTER_WIDTH - 1:0] clk_counter;
    reg [COUNTER_WIDTH - 1:0] counter;
    reg [CLK_COUNTER_WIDTH - 1:0] reset_v;

    always @(posedge iclk) begin
        if (reset == 1)
            counter = counter + 1;
    end

    always @(posedge clk or negedge reset) begin
        if (reset == 0) begin
            clk_counter = 0;
            counter = 0;
            code = 0;
            update = 1;
            reset_v = reset_value_div_2;
        end
        else begin
            if (clk_counter == reset_v) begin
                clk_counter = 0;
                if (update == 0) begin
                    code = counter;
                    counter = 0;
                end
                update = ~update;
            end
            else
                clk_counter = clk_counter + 1;
        end
    end
endmodule

module frequency_counter_decade_counters
#(parameter COUNT = 8, CLK_COUNTER_WIDTH = 32)
(
    input wire clk,
    input wire iclk,
    input wire reset,
    input wire [CLK_COUNTER_WIDTH - 1:0] reset_value_div_2,
    output reg [COUNT * 4 - 1:0] code,
    output reg update
);
    reg [CLK_COUNTER_WIDTH - 1:0] clk_counter;
    reg [CLK_COUNTER_WIDTH - 1 - 1:0] reset_v;
    wire [COUNT * 4 - 1:0] value;
    reg reset_counters;
    wire counters_reset = reset & reset_counters;

    decade_counters counters(.clk(iclk), .reset(counters_reset), .value(value));

    always @(posedge clk or negedge reset) begin
        if (reset == 0) begin
            reset_counters = 1;
            reset_v = reset_value_div_2;
            code = 0;
            update = 1;
            clk_counter = 0;
        end
        else begin
            if (clk_counter == reset_v) begin
                clk_counter = 0;
                if (update == 0) begin
                    code = value;
                    reset_counters = 0;
                end
                update = ~update;
            end
            else begin
                reset_counters = 1;
                clk_counter = clk_counter + 1;
            end
        end
    end
endmodule

module frequency_counters_tb;
    reg clk, iclk, reset;
    wire [31:0] binary_code;
    wire [31:0] bcd_code;
    wire binary_update;
    wire bcd_update;

    frequency_counter_binary fcb(.clk(clk), .iclk(iclk), .reset(reset), .reset_value_div_2(32'd500), .code(binary_code), .update(binary_update));
    frequency_counter_decade_counters fcd(.clk(clk), .iclk(iclk), .reset(reset), .reset_value_div_2(32'd500), .code(bcd_code), .update(bcd_update));

    always #1 clk = ~clk;
    always #2 iclk = ~iclk;

    initial begin
        $monitor("time=%t binary_code=%d binary_update=%d bcd_code=0x%0x bcd_update=%d", $time, binary_code, binary_update, bcd_code, bcd_update);
        clk = 0;
        iclk = 0;
        reset = 0;
        #20
        reset = 1;
        #10000
        $finish;
    end
endmodule
