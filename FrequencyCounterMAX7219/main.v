module frequencyCounterMax7219
#(parameter RESET_VALUE_DIV2 = 28'd25000000)
(
    input wire clk,
    input wire iclk,
    input wire reset,
    output wire clko,
    output wire dout,
    output wire load
);
    wire [31:0] code;
    wire update;
    wire max7219_busy;
    reg max7219_set = 0;
    reg [3:0] max7219_address;
    reg [7:0] max7219_data;
    reg [1:0] main_reset_counter;
    reg init = 0;
    reg main_reset = 0;
    reg post_update = 0;
    reg [7:0] max7219_init_seq [15:0];

    initial begin
        max7219_init_seq[0] = 'hF; // digit 0
        max7219_init_seq[1] = 'hF; // digit 1
        max7219_init_seq[2] = 'hF; // digit 2
        max7219_init_seq[3] = 'hF; // digit 3
        max7219_init_seq[4] = 'hF; // digit 4
        max7219_init_seq[5] = 'hF; // digit 5
        max7219_init_seq[6] = 'hF; // digit 6
        max7219_init_seq[7] = 'hF; // digit 7
        max7219_init_seq[8] = 'hF; // decode mode - Code B decode for digits 7–0
        max7219_init_seq[9] = 3;  // Intensity
        max7219_init_seq[10] = 7;  // scan limit - Display digits 0 1 2 3 4 5 6 7
        max7219_init_seq[11] = 1;  // shutdown register - Normal operaton 
    end

    frequency_counter_decade_counters #(.CLK_COUNTER_WIDTH(28))
        fc(.clk(clk), .iclk(iclk), .reset(main_reset), .reset_value_div_2(RESET_VALUE_DIV2), .code(code), .update(update));

    MAX7219 m(.clki(clk), .reset(main_reset), .set(max7219_set), .clko(clko), .dout(dout), .load(load), .data(max7219_data),
                .address(max7219_address), .busy(max7219_busy));
    
    always @(posedge clk) begin
        if (init == 0) begin
            if (reset == 0) begin
                max7219_set = 0;
                init = 1;
                main_reset = 0;
                main_reset_counter = 0;
            end
        end
        else begin
            if (main_reset == 0) begin
                main_reset_counter = main_reset_counter + 1;
                if (main_reset_counter == 0) begin
                    main_reset = 1;
                    max7219_address = 0;
                end
            end
            else begin
                if (max7219_busy == 0) begin
                    max7219_data = max7219_init_seq[max7219_address];
                    max7219_address = max7219_address + 1;
                    max7219_set = 1;
                    if (max7219_address == 12) begin
                        init = 0;
                        max7219_set = 0;
                    end
                end
                else
                    max7219_set = 0;
            end
        end
        if (post_update == 1) begin
            if (max7219_busy == 0) begin
                case (max7219_address)
                    0: max7219_data = {4'b0000, code[3:0]};
                    1: max7219_data = {4'b0000, code[7:4]};
                    2: max7219_data = {4'b0000, code[11:8]};
                    3: max7219_data = {4'b1000, code[15:12]}; // decimal point
                    4: max7219_data = {4'b0000, code[19:16]};
                    5: max7219_data = {4'b0000, code[23:20]};
                    6: max7219_data = {4'b1000, code[27:24]}; // decimal point
                    7: begin
                        max7219_data = {4'b0000, code[31:28]};
                        post_update = 0;
                       end
                endcase
                max7219_address = max7219_address + 1;
                max7219_set = 1;
            end
            else
                max7219_set = 0;
        end
    end

    always @(posedge update) begin
        if (main_reset == 1) begin
            max7219_address = 0;
            post_update = 1;
            max7219_set = 0;
        end
    end
endmodule
