module pc (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        sel_alu_i,
    input  wire        sel_pc_base_i,
    input  wire        add_imm_i,
    input  wire [31:0] imm_i,
    input  wire [31:0] alu_i,
    output wire [31:0] addr_o
);

  /////////////////////
  // Internal Registers
  /////////////////////
  //! Do not rename the pc_reg signal
  //! Use it to store the current PC value
  reg [31:0] pc_reg;

  wire [31:0] base_pc   = sel_pc_base_i ? (pc_reg - 32'd4) : pc_reg;
  wire [31:0] pc_plus   = add_imm_i    ? (base_pc + imm_i) : (base_pc + 32'd4);
  wire [31:0] next_pc   = sel_alu_i    ?  alu_i            : pc_plus;

  always @(posedge clk_i) begin
    if (!rst_ni)
      pc_reg <= 32'h80000000;
    else if (en_i)
      pc_reg <= next_pc;
  end

  assign addr_o = pc_reg;

endmodule
