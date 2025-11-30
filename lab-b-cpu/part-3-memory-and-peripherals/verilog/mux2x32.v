module mux2x32 (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire        sel_i,
    output reg  [31:0] o_o
);

    always @(*) begin
        case(sel_i)
            1'b0: o_o = a_i;
            1'b1: o_o = b_i;
            default: o_o = 32'b0;
        endcase
    end

endmodule
