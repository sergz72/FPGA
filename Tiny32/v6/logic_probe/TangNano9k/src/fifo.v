module fifo 
#(parameter SIZE_BITS=7, WIDTH=8)
(
    input wire clk,
    input wire nrst,
    input wire rreq,
    input wire wreq,
    output reg rack = 0,
    output reg wack = 0,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    reg [SIZE_BITS-1:0] w_ptr, r_ptr;
    reg [WIDTH-1:0] data [0:(1<<SIZE_BITS) - 1];

    always@(posedge clk) begin
        if(!nrst) begin
            r_ptr <= 0;
            rack <= 0;
        end
        else begin
            if (rreq & !empty & !rack) begin
                data_out <= data[r_ptr];
                r_ptr <= r_ptr + 1;
            end
            rack <= rreq;
        end
    end

    always@(posedge clk) begin
        if(!nrst) begin
            w_ptr <= 0;
            wack <= 0;
        end
        else begin
            if (wreq & !full & !wack) begin
                data[w_ptr] <= data_in;
                w_ptr <= w_ptr + 1;
            end
            wack <= wreq;
        end
    end

    assign full = (w_ptr+1'b1) == r_ptr;
    assign empty = w_ptr == r_ptr;

endmodule
