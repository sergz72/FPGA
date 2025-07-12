module main
(
    input wire clk,
    output wire dout
);
    localparam COUNTER_0P4 = 11;
    localparam COUNTER_0P8 = 22;
    localparam RESET_BIT = 19;

    reg nreset = 0;
    reg [RESET_BIT:0] counter = 0;
    reg [1:0] stage;
    reg [1:0] address;
    reg [7:0] r, g, b;
    reg ws2812b_write = 0;
    wire ws2812b_ready;
    reg done = 1;

    ws2812b #(.COUNTER_0P4(COUNTER_0P4), .COUNTER_0P8(COUNTER_0P8), .MAX_ADDRESS(3), .COUNT_BITS(2))
            w(.clk(!clk), .nreset(nreset), .address(address), .r(r), .g(g), .b(b), .mem_valid(ws2812b_write), .mem_ready(ws2812b_ready), .dout(dout));

    always @(posedge clk) begin
        if (counter[RESET_BIT])
            nreset <= 1;
        counter <= counter + 1;
    end

    always @(posedge clk) begin
        if (!nreset) begin
            stage <= 0;
            ws2812b_write <= 0;
            done <= 0;
            g <= 0;
            b <= 0;
            address <= 0;
        end
        else begin
            if (ws2812b_write) begin
                if (ws2812b_ready) begin
                    ws2812b_write <= 0;
                    address <= address + 1;
                end
            end
            else if (!done) begin
                case (stage)
                    0: r <= 8'h20;
                    1: g <= 8'h20;
                    2: r <= 0;
                    3: begin
                        g <= 0;
                        b <= 8'h20;
                        done <= 1;
                    end
                endcase
                ws2812b_write <= 1;
                stage <= stage + 1;
            end
        end
    end
endmodule
