module alu (
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [ 5:0] op_i,
    output wire [31:0] result_o
);

  //////////////////
  // Add_Sub Unit //
  //////////////////
  wire [31:0] addsub_result_w;
  wire        carry_w;
  wire        zero_w;
  wire        sub_w;

  assign sub_w = op_i[3];

  add_sub add_sub_unit (
      .a_i    (a_i),
      .b_i    (b_i),
      .sub_i  (sub_w),
      .carry_o(carry_w),
      .zero_o (zero_w),
      .r_o    (addsub_result_w)
  );

  /////////////////////
  // Comparator Unit //
  /////////////////////
  wire comp_result_w;

  comparator comp_unit (
      .carry_i  (carry_w),
      .zero_i   (zero_w),
      .a_31_i   (a_i[31]),
      .b_31_i   (b_i[31]),
      .diff_31_i(addsub_result_w[31]),
      .op_i     (op_i[2:0]),
      .r_o      (comp_result_w)
  );

  //////////////////
  // Logic Unit   //
  //////////////////
  wire [31:0] logic_result_w;

  logic_unit logic_unit (
      .a_i (a_i),
      .b_i (b_i),
      .op_i(op_i[2:0]),
      .r_o (logic_result_w)
  );

  //////////////////
  // Shift Unit   //
  //////////////////
  wire [31:0] shift_result_w;
  wire        arithmetic_shift_w;

  assign arithmetic_shift_w = op_i[3];

  shift_unit shift_unit (
      .a_i         (a_i),
      .b_i         (b_i),
      .op_i        (op_i[2:0]),
      .arithmetic_i(arithmetic_shift_w),
      .r_o         (shift_result_w)
  );

  /////////////////
  // Multiplexer //
  /////////////////
  wire [31:0] comp_result_extended_w;

  assign comp_result_extended_w = {31'b0, comp_result_w};

  mux4x32 result_mux (
      .a_i  (addsub_result_w),
      .b_i  (comp_result_extended_w),
      .c_i  (logic_result_w),
      .d_i  (shift_result_w),
      .sel_i(op_i[5:4]),
      .o_o  (result_o)
  );

endmodule
