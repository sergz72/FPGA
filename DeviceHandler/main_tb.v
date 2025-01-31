module main_tb;
    reg clk, nreset;
    reg sda_oe, scl_oe;
    wire sda_out, scl_out;
    reg [1:0] sdi;
    wire [1:0] sdo;
    reg sclk, sncs;
    reg [2:0] module_id;
    wire [3:0] sda;
    wire [3:0] scl;
    wire [7:0] module1_io;
    wire [7:0] module2_io;
    wire [7:0] module3_io;
    wire [3:0] module4_io;
    wire [0:0] module5_io;
    wire [3:0] leds;
    wire interrupt;
    reg module1_dedicated_in, module2_dedicated_in, module3_dedicated_in, module4_dedicated_in, module5_dedicated_in;

    reg sda_m_oe[4:0], scl_m_oe[4:0];

    assign sda[0] = sda_m_oe[0] ? 1'b0 : 1'bz;
    assign sda[1] = sda_m_oe[1] ? 1'b0 : 1'bz;
    assign sda[2] = sda_m_oe[2] ? 1'b0 : 1'bz;
    assign sda[3] = sda_m_oe[3] ? 1'b0 : 1'bz;
    //assign sda[4] = sda_m_oe[4] ? 1'b0 : 1'bz;

    assign scl[0] = scl_m_oe[0] ? 1'b0 : 1'bz;
    assign scl[1] = scl_m_oe[1] ? 1'b0 : 1'bz;
    assign scl[2] = scl_m_oe[2] ? 1'b0 : 1'bz;
    assign scl[3] = scl_m_oe[3] ? 1'b0 : 1'bz;
    //assign scl[4] = scl_m_oe[4] ? 1'b0 : 1'bz;

    always #1 clk <= !clk;

    pullup(scl[0]);
    pullup(sda[0]);
    pullup(scl[1]);
    pullup(sda[1]);
    pullup(scl[2]);
    pullup(sda[2]);
    pullup(scl[3]);
    pullup(sda[3]);
    //pullup(scl[4]);
    //pullup(sda[4]);

    main m(.clk(clk), .nreset(nreset), .sda_oe(sda_oe), .sda_out(sda_out), .scl_oe(scl_oe), .scl_out(scl_out), .sdi(sdi), .sdo(sdo),
            .sclk(sclk), .sncs(sncs), .module_id(module_id), .sda(sda), .scl(scl), .module1_io(module1_io), .module2_io(module2_io), .module3_io(module3_io),
            .module4_io(module4_io), .module5_io(module5_io), .leds(leds), .interrupt(interrupt), .module1_dedicated_in(module1_dedicated_in),
            .module2_dedicated_in(module2_dedicated_in), .module3_dedicated_in(module3_dedicated_in), .module4_dedicated_in(module4_dedicated_in),
            .module5_dedicated_in(module5_dedicated_in));

    initial begin
        $dumpfile("main_tb.vcd");
        $dumpvars(0, main_tb);
        $monitor("time=%t nreset=%d sda_oe=%d sda_out=%d scl_oe=%d scl_out=%d sda_m_oe[0]=%d scl_m_oe[0]=%d sda_m_oe[1]=%d scl_m_oe[1]=%d sda[0]=%d scl[0]=%d sda[1]=%d scl[1]=%d leds=%x interrupt=%d",
                    $time, nreset, sda_oe, sda_out, scl_oe, scl_out, sda_m_oe[0], scl_m_oe[0], sda_m_oe[1], scl_m_oe[1], sda[0], scl[0], sda[1], scl[1], leds, interrupt);
        
        clk = 0;
        nreset = 0;
        sda_oe = 0;
        scl_oe = 0;
        sda_m_oe[0]=0;
        scl_m_oe[0]=0;
        sda_m_oe[1]=0;
        scl_m_oe[1]=0;
        sda_m_oe[2]=0;
        scl_m_oe[2]=0;
        sda_m_oe[3]=0;
        scl_m_oe[3]=0;
        sda_m_oe[4]=0;
        scl_m_oe[4]=0;
        sclk = 0;
        sdi = 0;
        sncs = 1;
        module_id = 7;
        module1_dedicated_in = 0;
        module2_dedicated_in = 0;
        module3_dedicated_in = 0;
        module4_dedicated_in = 0;
        module5_dedicated_in = 0;

        #10
        nreset = 1;
        module_id = 0;
        sda_oe = 1;
        #10
        sda_oe = 0;
        scl_oe = 1;
        #10
        scl_oe = 0;
        #10
        sda_m_oe[0] = 1;
        #10
        sda_m_oe[0] = 0;
        scl_m_oe[0] = 1;
        #10
        scl_m_oe[0] = 0;
        module_id = 1;
        #10
        sda_oe = 1;
        #10
        sda_oe = 0;
        scl_oe = 1;
        #10
        scl_oe = 0;

        $finish;
    end
endmodule
