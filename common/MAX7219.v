module MAX7219
#(parameter DIV = 6)
(
    input wire clki,
    input wire set,
    input wire reset,
    input wire [7:0] data,
    input wire [3:0] address,
    output reg clko,
    output reg dout,
    output reg load,
    output reg busy
);
    reg [23:0] counter;
    reg [15:0] current;
    reg [3:0] current_bit;
    reg ibusy;

    always @(posedge set or negedge reset) begin
        if (reset == 0) begin
            clko = 1;
            dout = 0;
            load = 1;
            counter = 0;
            current_bit = 0;
        end
        current = {4'b0000, address, data};
        busy = reset;
	ibusy = reset;
    end

    always @(posedge clki) begin
        if (ibusy == 1) begin
            counter = counter + 1;
            if (counter == DIV / 2) begin
                counter = 0;
                clko = ~clko;
                if (clko == 0) begin
                    dout = current[15];
                    current = current << 1;
                    current_bit = current_bit + 1;
                    if (current_bit == 8)
                        load = 0;
                end
                else begin
                    if (current_bit == 0)
                        ibusy = 0;
                end
            end
        end
        else begin
            load = 1;
            busy = 0;
        end
    end
endmodule

module MAX7219_tb;
    reg clki, set, reset;
    reg [7:0] data;
    reg [3:0] address;
    wire clko, dout, load, busy;

    MAX7219 m(.clki(clki), .set(set), .reset(reset), .data(data), .address(address), .clko(clko), .dout(dout),
                .load(load), .busy(busy));

    always #5 clki = ~clki;

    initial begin
        $monitor("time=%t clko=%d dout=%d load=%d busy=%d", $time, clko, dout, load, busy);
        clki = 0;
        set = 0;
        reset = 1;
        #10
        reset = 0;
        #10
        reset = 1;
        #10
        data = 'h55;
        address = 'hA;
        set = 1;
        #10
	set = 0;
	#2000
        data = 'hAA;
        address = 'h5;
        set = 1;
	#2000
        $finish;
    end
endmodule
