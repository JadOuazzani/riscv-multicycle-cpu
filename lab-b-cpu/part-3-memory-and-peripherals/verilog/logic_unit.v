module logic_unit (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [ 2:0] op_i,
    output reg [31:0] r_o
);

    always @(*) begin
        case(op_i)
            3'b100: r_o = a_i ^ b_i;
            3'b110: r_o = a_i | b_i;
            3'b111: r_o = a_i & b_i;
            default: r_o = 32'b0;
        endcase
    end
endmodule

