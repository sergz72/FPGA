module fifo 
#(parameter SIZE_BITS=7, WIDTH=8)
(
    input wire clk,
    input wire nrst,
    input wire nwr,
    input wire nrd,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);
    reg [SIZE_BITS-1:0] w_ptr, r_ptr;
    reg [WIDTH-1:0] data [0:(1<<SIZE_BITS) - 1];
    wire rclk, wclk;

    assign rclk = (nrst | clk) & nrd;
    assign wclk = (nrst | clk) & nwr;

    always@(negedge rclk) begin
        if(!nrst)
            r_ptr <= 0;
        else if (!empty) begin
            data_out <= data[r_ptr];
            r_ptr <= r_ptr + 1;
        end
    end

    always@(negedge wclk) begin
        if(!nrst)
            w_ptr <= 0;
        else if (!full) begin
            data[w_ptr] <= data_in;
            w_ptr <= w_ptr + 1;
        end
    end
    
    assign full = (w_ptr+1'b1) == r_ptr;
    assign empty = w_ptr == r_ptr;

endmodule
