module mux4x32 (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [31:0] c_i,
    input  wire [31:0] d_i,
    input  wire [ 1:0] sel_i,
    output reg [31:0] o_o
);

    always @(*) begin
        case(sel_i)
            2'b00: o_o = a_i;
            2'b01: o_o = b_i;
            2'b10: o_o = c_i;
            2'b11: o_o = d_i;
            default: o_o = 32'b0;
        endcase
    end
endmodule
