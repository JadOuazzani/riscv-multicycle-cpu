module comparator (
    input  wire       a_31_i,
    input  wire       b_31_i,
    input  wire       diff_31_i,
    input  wire       carry_i,
    input  wire       zero_i,
    input  wire [2:0] op_i,
    output reg       r_o
);
    always @(*) begin
        case(op_i)
            3'b000 : r_o = zero_i;
            3'b001 : r_o = ~zero_i;
            3'b100 : r_o = (a_31_i & ~b_31_i) | (~(a_31_i ^ b_31_i) & diff_31_i);
            3'b101 : r_o = (~a_31_i & b_31_i) | (~(a_31_i ^ b_31_i) & ~diff_31_i);
            3'b110 : r_o = ~carry_i & ~zero_i;
            3'b111 : r_o = carry_i | zero_i;
            default: r_o = 1'b0;
        endcase
    end
endmodule
