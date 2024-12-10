module test;
    localparam ROM_BITS = 18;
    localparam ROM_SIZE = 1 << ROM_BITS;

    reg clk, nreset;
    wire dm, dp, oe, dm_out, dp_out;

    reg [7:0] data [0:ROM_SIZE - 1];
    reg [7:0] sample;

    wire [4:0] packet_start;

    always #1 clk <= ~clk;

    assign dm = sample[0];
    assign dp = sample[1];

    integer file_id, temp, address;
    initial begin
        file_id = $fopen("test.bin", "rb");
        temp = $fread(data, file_id);
        $fclose(file_id);

        $dumpfile("test.vcd");
        $dumpvars(0, test);
        $monitor("time=%t clk=%d nreset=%d address=%d dm=%d dp=%d packet_start=0x%x", $time, clk, nreset, address, dm, dp, packet_start);
        clk = 0;
        nreset = 0;
        address = 0;
        #20
        nreset = 1;
        #20

        for (address = 0; address < ROM_SIZE; address++) begin
            sample = data[address];
            #2;
        end
        $finish;
    end

    usbdevice ud(.clk(clk), .nreset(nreset), .dm_in(dm), .dp_in(dp), .packet_start(packet_start), .oe(oe), .dm_out(dm_out), .dp_out(dp_out));

endmodule
