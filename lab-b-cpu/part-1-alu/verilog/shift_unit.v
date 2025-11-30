module shift_unit (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [ 2:0] op_i,
    input  wire        arithmetic_i,
    output reg [31:0] r_o
);
    
    wire [4:0] shift = b_i[4:0];

    always @(*) begin
        case(op_i)
            3'b001: r_o = a_i << shift;
            3'b101: begin 
                if (arithmetic_i) begin 
                    r_o = $signed(a_i) >>> shift;
                end else  
                    r_o = a_i >> shift;
            end
            default: r_o = 32'b0; 
        endcase
    end
endmodule
