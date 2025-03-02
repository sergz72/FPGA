module main_tb;
    reg clk, clk_sys, ncs, spi_send, sent, nreset;
    reg [119:0] spi_data_out, spi_data_in;
    reg [2:0] counter;
    reg [7:0] cnt;
    wire miso, mosi, interrupt, sck;
    wire [3:0] out;

    assign mosi = spi_data_out[119];

    assign sck = counter[2];

    always #1 clk <= ~clk;

    main m(.clk(clk), .clk_dds(clk_sys), .sck(sck), .mosi(mosi), .ncs(ncs), .miso(miso), .interrupt(interrupt), .out(out), .nreset(nreset));

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t sck=%d mosi=%d miso=%d ncs=%d spi_data_in=%x spi_send=%d sent=%d", $time, sck, mosi, miso, ncs, spi_data_in, spi_send, sent);
        clk = 0;
        clk_sys = 0;
        ncs = 1;
        spi_send = 0;
        sent = 0;
        counter = 0;
        nreset = 0;
        #5
        nreset = 1;

        spi_data_out = {120'h0}; // get device id
        spi_data_in = {120'h0};
        cnt = 16;
        #5
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        spi_data_out = {120'h0};
        spi_data_in = {120'h0};
        cnt = 32;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        spi_data_out = {8'h0, 8'h1, 104'h0}; // get config, subdevice 0
        spi_data_in = {120'h0};
        cnt = 16;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        spi_data_out = {120'h0};
        spi_data_in = {120'h0};
        cnt = 120;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        //device_command, command, channel, frequency_code(8), divider(2)
        spi_data_out = {8'h0, 8'h3, 8'h2, 8'h0, 8'hFF, 8'hFF, 48'h0, 16'h0, 8'h0};
        spi_data_in = {120'h0};
        cnt = 112;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        //device_command, command, channel, enable
        spi_data_out = {8'h0, 8'h3, 8'h5, 8'h0, 8'h1, 80'h0};
        spi_data_in = {120'h0};
        cnt = 40;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        //device_command, command, channel, enable
        spi_data_out = {8'h0, 8'h3, 8'h5, 8'h0, 8'h0, 80'h0};
        spi_data_in = {120'h0};
        cnt = 40;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        spi_data_out = {120'h0}; // get device id
        spi_data_in = {120'h0};
        cnt = 16;
        #5
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        spi_data_out = {120'h0};
        spi_data_in = {120'h0};
        cnt = 32;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        spi_data_out = {8'h0, 8'h1, 104'h0}; // get config
        spi_data_in = {120'h0};
        cnt = 16;
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        spi_data_out = {120'h0};
        spi_data_in = {120'h0};
        cnt = 120;
        #5
        spi_send = 1;
        while (!sent) begin
            #5;
        end
        spi_send = 0;
        #5

        $finish;
    end

    always @(posedge clk) begin
        if (spi_send) begin
            if (cnt != 0) begin
                ncs <= 0;
                if (counter == 7) begin
                    spi_data_out <= {spi_data_out[118:0], 1'b0};
                    cnt <= cnt - 1;
                end
                else if (counter == 4) begin
                    spi_data_in <= {spi_data_in[118:0], miso};
                end
                counter <= counter + 1;
            end
            else begin
                sent <= 1;
                ncs <= 1;
            end
        end
        else
            sent <= 0;
    end
endmodule
