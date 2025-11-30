module add_sub (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire        sub_i,
    output wire        carry_o,
    output wire        zero_o,
    output wire [31:0] r_o
);
    wire [31:0] b_xored = b_i ^ {32{sub_i}};
    wire [32:0] sum   = {1'b0, a_i} + {1'b0, b_xored} + sub_i;

    assign r_o     = sum[31:0];
    assign carry_o = sum[32];
    assign zero_o  = (sum[31:0] == 32'b0);

endmodule
