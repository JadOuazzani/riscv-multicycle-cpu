module cpu (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire [31:0] rdata_i,
    output wire [31:0] addr_o,
    output wire [31:0] wdata_o,
    output wire        we_o
);

  ////////////////////
  // Internal Wires
  ////////////////////
  wire [31:0] instruction_w;
  wire        branch_op_w;
  wire [31:0] imm_w;
  wire        ir_en_w;
  wire        pc_add_imm_w;
  wire        cont_pc_en_w;
  wire        pc_sel_alu_w;
  wire        pc_sel_pc_base_w;
  wire        rf_we_w;
  wire        sel_addr_w;
  wire        sel_b_w;
  wire        sel_mem_w;
  wire        sel_pc_w;
  wire        sel_imm_w;
  wire [ 5:0] alu_op_w;
  wire [31:0] ra_w;
  wire [31:0] rb_w;
  wire [31:0] op_b_w;
  wire [31:0] alu_res_w;
  wire [31:0] next_pc_addr_w;
  wire        pc_en_w;
  wire [31:0] alu_mux_imm_w;
  wire [31:0] pc_mux_rdata_w;
  wire        sel_pc_or_mem_w;
  wire [31:0] final_mux_res_w;

  ////////////////////////
  // Instruction Register
  ////////////////////////
  ir ir_inst (
      .clk_i   (clk_i),
      .enable_i(ir_en_w),
      .d_i     (rdata_i),
      .q_o     (instruction_w)
  );

  //////////////
  // Controller
  //////////////
  controller controller_inst (
      .clk_i           (clk_i),
      .rst_ni          (rst_ni),
      .instruction_i   (instruction_w),
      .branch_op_o     (branch_op_w),
      .imm_o           (imm_w),
      .ir_en_o         (ir_en_w),
      .pc_add_imm_o    (pc_add_imm_w),
      .pc_en_o         (cont_pc_en_w),
      .pc_sel_alu_o    (pc_sel_alu_w),
      .pc_sel_pc_base_o(pc_sel_pc_base_w),
      .rf_we_o         (rf_we_w),
      .sel_addr_o      (sel_addr_w),
      .sel_b_o         (sel_b_w),
      .sel_mem_o       (sel_mem_w),
      .sel_pc_o        (sel_pc_w),
      .sel_imm_o       (sel_imm_w),
      .we_o            (we_o),
      .alu_op_o        (alu_op_w)
  );

  ///////////////////
  // Register File
  ///////////////////
  register_file rf_inst (
      .clk_i   (clk_i),
      .aa_i    (instruction_w[19:15]),
      .ab_i    (instruction_w[24:20]),
      .aw_i    (instruction_w[11:7]),
      .wren_i  (rf_we_w),
      .wrdata_i(final_mux_res_w),
      .a_o     (ra_w),
      .b_o     (rb_w)
  );

  /////////////////////////////////
  // Immediate vs Register B Mux
  /////////////////////////////////
  mux2x32 mux_inst_imm_rb (
      .a_i  (imm_w),
      .b_i  (rb_w),
      .sel_i(sel_b_w),
      .o_o  (op_b_w)
  );

  ///////
  // ALU
  ///////
  alu alu_inst (
      .a_i     (ra_w),
      .b_i     (op_b_w),
      .op_i    (alu_op_w),
      .result_o(alu_res_w)
  );

  /////////////////////
  // Program Counter
  /////////////////////
  assign pc_en_w = (branch_op_w && alu_res_w[0]) || cont_pc_en_w;
  pc pc_inst (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .en_i         (pc_en_w),
      .sel_alu_i    (pc_sel_alu_w),
      .sel_pc_base_i(pc_sel_pc_base_w),
      .add_imm_i    (pc_add_imm_w),
      .imm_i        (imm_w),
      .alu_i        (alu_res_w),
      .addr_o       (next_pc_addr_w)
  );

  /////////////////////////////
  // ALU Result vs Immediate Mux
  /////////////////////////////
  mux2x32 mux_inst_alu_imm (
      .a_i  (alu_res_w),
      .b_i  (imm_w),
      .sel_i(sel_imm_w),
      .o_o  (alu_mux_imm_w)
  );

  //////////////////////////////////
  // Next PC vs Memory Data Mux
  //////////////////////////////////
  mux2x32 mux_inst_mem_pc (
      .a_i  (next_pc_addr_w),
      .b_i  (rdata_i),
      .sel_i(sel_mem_w),
      .o_o  (pc_mux_rdata_w)
  );

  /////////////////////////////
  // Final Write-Back Data Mux
  /////////////////////////////
  assign sel_pc_or_mem_w = sel_pc_w || sel_mem_w;
  mux2x32 mux_inst_alu_pc (
      .a_i  (alu_mux_imm_w),
      .b_i  (pc_mux_rdata_w),
      .sel_i(sel_pc_or_mem_w),
      .o_o  (final_mux_res_w)
  );

  ///////////////////////////
  // Memory Address Mux
  ///////////////////////////
  mux2x32 mux_inst_mem_addr (
      .a_i  (next_pc_addr_w),
      .b_i  (alu_res_w),
      .sel_i(sel_addr_w),
      .o_o  (addr_o)
  );

  ///////////////////////////
  // Output
  ///////////////////////////
  assign wdata_o = rb_w;

  ///////////////////////////
  // DPI-C FUNCTIONS FOR EXTENSION
  // DO NOT MODIFY
  ///////////////////////////
  export "DPI-C" function cpu_get_pc;
  reg [31:0] prev_pc_r;
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      prev_pc_r<= 32'h8000_0000;
    else
      if (pc_en_w)
        prev_pc_r<= next_pc_addr_w;
  end

  function int unsigned cpu_get_pc();
    return prev_pc_r;
  endfunction

  export "DPI-C" function cpu_get_gpr;

  function int unsigned cpu_get_gpr(input int unsigned idx);
    return rf_inst.reg_array_r[idx];
  endfunction

  export "DPI-C" function cpu_set_gpr;

  function void cpu_set_gpr(input int unsigned idx, input int unsigned val);
    if ((idx > 0) && (idx < 32))
      rf_inst.reg_array_r[idx] <= val;
  endfunction

endmodule
