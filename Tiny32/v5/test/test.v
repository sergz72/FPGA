module tiny32_tb;
    localparam ROM_BITS = 11;
    localparam RAM_BITS = 10;

    wire [31:0] io_address;
    wire hlt, error, wfi, io_req;
    wire io_nwr;
    wire [31:0] io_data_in, io_data_out;
    reg [7:0] interrupt, interrupt_ack;
    reg clk, nreset;

    tiny32 #(.ROM_BITS(ROM_BITS), .RAM_BITS(RAM_BITS)) cpu(.clk(clk), .io_req(io_req), .io_nwr(io_nwr), .wfi(wfi), .nreset(nreset), .io_address(io_address), .io_data_in(io_data_out),
                .io_data_out(io_data_in), .error(error), .hlt(hlt), .io_ready(1'b1), .interrupt(interrupt), .interrupt_ack(interrupt_ack));

    assign io_data_out = 0;

    always #1 clk <= ~clk;
    
    integer i;
    initial begin
        $dumpfile("tiny32_tb.vcd");
        $dumpvars(0, tiny32_tb);
        $monitor("time=%t clk=%d nreset=%d io_req=%d io_nwr=0x%x hlt=%d error=%d wfi=%d io_address=0x%x, io_data_in=0x%x io_data_out=0x%x",
                 $time, clk, nreset, io_req, io_nwr, hlt, error, wfi, io_address, io_data_in, io_data_out);
        clk = 0;
        nreset = 0;
        interrupt = 0;
        #20
        nreset = 1;
        for (i = 0; i < 1000; i = i + 1) begin
            #100
            if (hlt | error)
              $finish;
        end
        $finish;
    end

endmodule
