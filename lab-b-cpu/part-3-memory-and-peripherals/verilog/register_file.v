module register_file (
    input  wire        clk_i,
    input  wire [4:0]  aa_i,
    input  wire [4:0]  ab_i,
    input  wire [4:0]  aw_i,
    input  wire        wren_i,
    input  wire [31:0] wrdata_i,
    output wire [31:0] a_o,
    output wire [31:0] b_o
);

    // 32 registres de 32 bits
    reg [31:0] reg_array_r [32];

    // Initialisation à 0
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            reg_array_r[i] = 32'b0;
    end

    // Lecture asynchrone
    assign a_o = (aa_i == 5'd0) ? 32'b0 : reg_array_r[aa_i];
    assign b_o = (ab_i == 5'd0) ? 32'b0 : reg_array_r[ab_i];

    // Écriture synchrone (sur front montant)
    always @(posedge clk_i) begin
        if (wren_i && (aw_i != 5'd0)) begin
            reg_array_r[aw_i] <= wrdata_i;
        end
    end

endmodule
