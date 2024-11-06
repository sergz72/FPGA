`include "main.vh"

module main
#(parameter ROM_BITS = 10, RAM_BITS = 10, RODATA_BITS = 8, I2C_PORTS_BITS = 1)
(
    input wire clk,
    output wire nerror,
    output wire nhlt,
    output wire nwfi,
    output reg led = 1,
    input wire rx,
    output wire tx,
`ifndef NO_INOUT_PINS
    inout wire [(1 << I2C_PORTS_BITS) - 1:0] scl_io,
    inout wire [(1 << I2C_PORTS_BITS) - 1:0] sda_io
`else
    input wire [(1 << I2C_PORTS_BITS) - 1:0] scl_in,
    input wire [(1 << I2C_PORTS_BITS) - 1:0] sda_in,
    output reg [(1 << I2C_PORTS_BITS) - 1:0] scl_oe = 0,
    output reg [(1 << I2C_PORTS_BITS) - 1:0] sda_oe = 0,
    output wire zero
`endif
);
    localparam MEMORY_SELECTOR_START_BIT = 13;

    wire error, hlt, wfi;
    wire [15:0] mem_address, mem_data_in, mem_data_out, uart_rdata, i2c_rdata;
    reg [15:0] ram_rdata, rodata_rdata;
    wire cpu_clk;
    wire mem_valid, mem_nwr;
    wire ram_selected, rodata_selected, port_selected, uart_selected, i2c_selected, mem_selected;

    reg mem_ready = 0;
    wire [RAM_BITS - 1:0] ram_address;
    wire [RODATA_BITS - 1:0] rodata_address;
    wire [15-MEMORY_SELECTOR_START_BIT:0] memory_selector;

    wire [1:0] interrupt, interrupt_ack;

    wire [7:0] uart_data;
    wire uart_send, uart_busy, uart_interrupt;

    reg timer_interrupt = 0;

    reg nreset = 0;

    reg [`CPU_TIMER_BITS - 1:0] cpu_timer = 0;

    reg [15:0] ram [0:(1<<RAM_BITS)-1];
    reg [15:0] rodata [0:(1<<RODATA_BITS)-1];

    reg [(1 << I2C_PORTS_BITS) - 1:0] scl = {(1 << I2C_PORTS_BITS){1'b1}};
    reg [(1 << I2C_PORTS_BITS) - 1:0] sda = {(1 << I2C_PORTS_BITS){1'b1}};
    wire [I2C_PORTS_BITS - 1:0] i2c_port;

    forth_cpu #(.ROM_BITS(ROM_BITS))
              cpu(.clk(cpu_clk), .error(error), .hlt(hlt), .wfi(wfi), .nreset(nreset), .mem_address(mem_address), .mem_nwr(mem_nwr),
                  .mem_data_in(mem_data_out), .mem_data_out(mem_data_in), .mem_valid(mem_valid), .mem_ready(mem_ready),
                  .interrupt(interrupt), .interrupt_ack(interrupt_ack));

    uart1tx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        utx(.clk(clk), .tx(tx), .data(mem_data_in[7:0]), .send(uart_send), .busy(uart_busy), .nreset(nreset));
    uart1rx #(.CLOCK_DIV(`UART_CLOCK_DIV), .CLOCK_COUNTER_BITS(`UART_CLOCK_COUNTER_BITS))
        urx(.clk(clk), .rx(rx), .data(uart_data), .interrupt(uart_interrupt), .interrupt_clear(interrupt_ack[1]), .nreset(nreset));

    genvar i;
    generate
        for (i = 0; i < (1 << I2C_PORTS_BITS); i = i + 1) begin : i2c_generate
`ifndef NO_INOUT_PINS
            assign sda_io[i] = sda[i] ? 1'bz : 0;
            assign scl_io[i] = scl[i] ? 1'bz : 0;
`else
            assign sda_oe[i] = !sda[i];
            assign scl_oe[i] = !scl[i];
`endif
        end
    endgenerate

`ifdef NO_INOUT_PINS
    assign zero = 0;
`endif

    assign interrupt = {uart_interrupt, timer_interrupt};

    assign memory_selector = mem_address[15:MEMORY_SELECTOR_START_BIT];
    assign cpu_clk = cpu_timer[`CPU_CLOCK_BIT];
    assign nerror = !error;
    assign nhlt = !hlt;
    assign nwfi = !wfi;
    assign ram_address = mem_address[RAM_BITS-1:0];
    assign rodata_address = mem_address[RODATA_BITS-1:0];

    assign ram_selected = memory_selector == 0;
    assign rodata_selected = memory_selector == 1;
    assign i2c_selected = memory_selector == 5;
    assign uart_selected = memory_selector == 6;
    assign port_selected = memory_selector == 7;

    assign i2c_port = mem_address[I2C_PORTS_BITS - 1:0];
`ifndef NO_INOUT_PINS
    assign i2c_rdata = {14'h0, scl_io[i2c_port], sda_io[i2c_port]};
`else
    assign i2c_rdata = {14'h0, scl_in[i2c_port], sda_in[i2c_port]};
`endif

    assign uart_rdata = {7'h0, uart_busy, uart_data};

    assign mem_data_out = ram_selected ? ram_rdata : (rodata_selected ? rodata_rdata : (uart_selected ? uart_rdata : i2c_rdata));

    assign uart_send = nreset & mem_valid & mem_ready & uart_selected & !mem_nwr;

    assign mem_selected = mem_valid & !mem_ready;

    initial begin
        $readmemh("asm/data.hex", ram);
        $readmemh("asm/rodata.hex", rodata);
    end

    always @(posedge clk) begin
        if (interrupt_ack[0])
            timer_interrupt <= 0;
        else if (cpu_timer == {`CPU_TIMER_BITS{1'b1}})
            timer_interrupt <= 1;
        if (cpu_timer[`RESET_BIT - 1])
            nreset <= 1;
        cpu_timer <= cpu_timer + 1;
    end

    always @(posedge cpu_clk) begin
        if (mem_selected & ram_selected) begin
            if (!mem_nwr)
                ram[ram_address] <= mem_data_in;
            ram_rdata <= ram[ram_address];
        end
        mem_ready <= nreset & mem_valid & (ram_selected | i2c_selected | port_selected | uart_selected | rodata_selected);
    end

    always @(posedge cpu_clk) begin
        if (mem_selected & rodata_selected) begin
            rodata_rdata <= rodata[rodata_address];
        end
    end

    always @(posedge cpu_clk) begin
        if (mem_selected & port_selected & !mem_nwr)
            led <= mem_data_in[0];
    end

    always @(posedge cpu_clk) begin
        if (mem_selected & i2c_selected & !mem_nwr) begin
            {scl[i2c_port], sda[i2c_port]} <= mem_data_in[1:0];
        end
    end
endmodule
