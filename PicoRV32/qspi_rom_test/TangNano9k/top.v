module top
(
    input wire clk,
    output wire ntrap,
    output wire led,
    output wire rom_sck,
    inout wire [3:0] rom_sio,
    output wire rom_ncs
);
    wire clk_rom_controller;
    wire clk_main;

    //reg [3:0] counter = 0;

    assign clk_rom_controller = clk; //counter[3];
    assign clk_main = clk; //counter[3];

    main #(.RESET_BIT(3))
         m(.clk(clk_main), .clk_rom_controller(clk_rom_controller), .ntrap(ntrap), .led(led), .rom_sck(rom_sck), .rom_sio(rom_sio), .rom_ncs(rom_ncs));

    //always @(posedge clk) begin
    //    counter <= counter + 1;
    //end
endmodule