module ws2812b
#(parameter DIV0P1US = 5, MAX_ADDRESS = 0, COUNT_BITS = 1)
(
    input wire clk,
    input wire [COUNT_BITS - 1:0] address,
    input wire [7:0] r,
    input wire [7:0] g,
    input wire [7:0] b,
    input wire set,
    input wire send,
    output reg dout = 0,
    output reg busy = 0
);
    reg [23:0] mem [0:MAX_ADDRESS];
    reg [23:0] current;
    reg [4:0] bit_counter;
    reg [8:0] one_counter;
    reg [8:0] zero_counter;
    reg [13:0] reset_counter;
    reg [COUNT_BITS - 1:0] current_address;
    reg internal_busy = 0;
    reg prev_send = 1;

    task init_counters;
        if (current[23] == 0) begin
            one_counter <= DIV0P1US * 4;
            zero_counter <= DIV0P1US * 8;
        end
        else begin
            one_counter <= DIV0P1US * 8;
            zero_counter <= DIV0P1US * 4;
        end
    endtask

    always @(posedge set) begin
        if (busy == 0)
            mem[address] <= {g, r, b};
    end

    always @(posedge clk or send) begin
        if (!prev_send && send) begin
            current_address <= 0;
            bit_counter <= 0;
            current <= mem[0];
            dout <= 0;
            reset_counter <= 0;
            busy <= 1;
        end
        else begin
            if (busy == 1 && internal_busy == 0) begin
                internal_busy <= 1;
                init_counters;
            end
            else if (internal_busy == 1) begin
                if (reset_counter != 0) begin
                    if (reset_counter == 1) begin
                        internal_busy <= 0;
                        busy <= 0;
                    end
                    dout <= 0;
                    reset_counter <= reset_counter - 1;
                end
                else if (one_counter != 0) begin
                    dout <= 1;
                    one_counter <= one_counter - 1;
                end
                else if (zero_counter != 0) begin
                    dout <= 0;
                    if (zero_counter == 2) begin
                        if (bit_counter == 23) begin
                            if (current_address == MAX_ADDRESS) begin
                                reset_counter <= DIV0P1US * 510;
                            end
                            else begin
                                bit_counter <= 0;
                                current <= mem[current_address + 1];
                                current_address <= current_address + 1;
                            end
                        end
                        else begin
                            current <= current << 1;
                            bit_counter <= bit_counter + 1;
                        end
                    end
                    if (zero_counter == 1) begin
                        init_counters;
                    end
                    else
                        zero_counter <= zero_counter - 1;
                end
            end
        end
        prev_send <= send;
    end
endmodule

module ws2812b_tb;
    wire dout, busy;
    reg clk;
    reg address;
    reg [7:0] r, g, b;
    reg set;
    reg send;

    ws2812b #(.DIV0P1US(2), .MAX_ADDRESS(1))
        w(.clk(clk), .address(address), .r(r), .g(g), .b(b), .set(set), .send(send), .dout(dout), .busy(busy));
    
    always #1 clk = ~clk;

    initial begin
        $dumpfile("ws2812b_tb.vcd");
        $dumpvars(0, ws2812b_tb);
        $monitor("time=%t dout=%d busy=%d", $time, dout, busy);
        clk = 0;
        address = 0;
        r = 'h11;
        g = 'h22;
        b = 'h33;
        set = 0;
        send = 0;
        #5
        set = 1;
        #5
        set = 0;
        address = 1;
        r = 'h44;
        g = 'h55;
        b = 'h66;
        #5
        set = 1;
        send = 1;
        #10000
        $finish;
    end
endmodule
