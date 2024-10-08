// adapted from https://github.com/skmtti/div

module div #(parameter DATA_WIDTH = 32)
(
    input wire clk,
    input wire nrst,
    input wire [DATA_WIDTH-1:0] dividend,
    input wire [DATA_WIDTH-1:0] divisor,
    input wire signed_ope,
    input wire start,
    output reg [DATA_WIDTH-1:0] quotient,
    output reg [DATA_WIDTH-1:0] remainder,
    output wire ready
);
  localparam COUNT_WIDTH = $clog2(DATA_WIDTH + 1);

  reg r_ready = 1;
  reg prev_start = 0;
  reg r_signed_ope;
  reg [COUNT_WIDTH-1:0] r_count;
  reg [DATA_WIDTH-1:0] r_quotient;
  wire w_dividend_sign;
  reg r_dividend_sign;
  wire remainder_sign;
  reg [DATA_WIDTH:0] r_remainder;
  reg [DATA_WIDTH-1:0] r_divisor;
  wire [DATA_WIDTH:0] divisor_ext;
  wire divisor_sign;
  wire [DATA_WIDTH:0] rem_quo;
  wire                diff_sign;
  wire [DATA_WIDTH:0] sub_add;
  wire [DATA_WIDTH-1:0] q;

  assign ready = r_ready;

  assign divisor_sign = r_divisor[DATA_WIDTH-1] & r_signed_ope;
  assign divisor_ext = {divisor_sign, r_divisor};
  assign remainder_sign = r_remainder[DATA_WIDTH];

  assign rem_quo = {r_remainder[DATA_WIDTH-1:0], r_quotient[DATA_WIDTH-1]};
  assign diff_sign = remainder_sign ^ divisor_sign;
  assign sub_add = diff_sign ? rem_quo + divisor_ext :
                               rem_quo - divisor_ext;

  assign q = (r_quotient << 1) | 1;

  // after process
  always @(negedge clk) begin
    if (divisor == 0) begin
      quotient  <= {DATA_WIDTH{1'b1}};
      remainder <= dividend;
    end
    if (!ready) begin
      if (r_remainder != 0) begin
        if (r_remainder == divisor_ext) begin
          quotient  <= q + 1;
          remainder <= r_remainder[DATA_WIDTH-1:0] - r_divisor;
        end
        else if (r_remainder == -divisor_ext) begin
          quotient  <= q - 1;
          remainder <= r_remainder[DATA_WIDTH-1:0] + r_divisor;
        end
        else if (remainder_sign ^ r_dividend_sign) begin
          if (diff_sign) begin
            quotient  <= q - 1;
            remainder <= r_remainder[DATA_WIDTH-1:0] + r_divisor;
          end
          else begin
            quotient  <= q + 1;
            remainder <= r_remainder[DATA_WIDTH-1:0] - r_divisor;
          end
        end
        else begin
          quotient  <= q;
          remainder <= r_remainder[DATA_WIDTH-1:0];
        end
      end
      else begin
          quotient  <= q;
          remainder <= r_remainder[DATA_WIDTH-1:0];
      end
    end
  end

  assign w_dividend_sign = dividend[DATA_WIDTH-1] & signed_ope;

  always @(posedge clk) begin
    if (!nrst) begin
      r_quotient      <= 0;
      r_dividend_sign <= 0;
      r_remainder     <= 0;
      r_divisor       <= 0;
      r_count         <= 0;
      r_ready         <= 1;
      r_signed_ope    <= 0;
      prev_start      <= 0;
    end
    else begin
      if (!ready) begin
        r_quotient  <= {r_quotient[DATA_WIDTH-2:0], !diff_sign};
        r_remainder <= sub_add[DATA_WIDTH:0];
        r_count     <= r_count + 1;
        if (r_count == DATA_WIDTH)
          r_ready <= 1;
      end
      else if (start & !prev_start) begin
        // RISC-V's div by 0 spec
        if (divisor != 0) begin
          r_quotient  <= dividend;
          r_remainder <= {(DATA_WIDTH+1){w_dividend_sign}};
          r_ready     <= 0;
        end
        r_count         <= 0;
        r_dividend_sign <= w_dividend_sign;
        r_divisor       <= divisor;
        r_signed_ope    <= signed_ope;
      end
    end
    prev_start <= start;
  end
endmodule
