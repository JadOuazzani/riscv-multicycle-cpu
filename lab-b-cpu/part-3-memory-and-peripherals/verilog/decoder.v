module decoder (
    input  wire [31:0] addr_i,
    output wire        en_ram_o,
    output wire        en_leds_o,
    output wire        en_7_seg_lcd_o,
    output wire        en_buttons_o
);

assign en_leds_o      = addr_i[31:12] == 20'h50000;
assign en_7_seg_lcd_o = addr_i[31:12] == 20'h60000;
assign en_buttons_o   = addr_i[31:12] == 20'h70000;
assign en_ram_o       = (addr_i[31:28] == 4'h8) || (addr_i[31:28] == 4'h9);

endmodule
