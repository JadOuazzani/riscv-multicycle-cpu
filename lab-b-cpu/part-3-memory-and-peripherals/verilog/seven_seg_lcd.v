module seven_seg_lcd (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        we_i,
    input  wire [31:0] waddr_i,
    input  wire [31:0] wdata_i,
    output wire [31:0] disp_o
);

localparam BASE_ADDRESS = 32'h60000000;

reg [31:0] lcd_content ;


always @(posedge clk_i) begin
    if (!rst_ni)
        lcd_content <= 32'h00000000;
    else if (en_i && we_i && (waddr_i == BASE_ADDRESS))
        lcd_content <= wdata_i;
end

assign disp_o = lcd_content;


endmodule
