`timescale 1ns / 1ps

module tb_alu ();
  // Localparams for ALU ops
  localparam ADD_SUB = 2'b00;
  localparam COMP = 2'b01;
  localparam LOGIC = 2'b10;
  localparam SHIFT = 2'b11;

  // Localparams for funct3 values
  // Arithmetic and Logical operations
  localparam F3_ADD_SUB = 3'b000;
  localparam F3_SLL = 3'b001;
  localparam F3_XOR = 3'b100;
  localparam F3_SR = 3'b101;
  localparam F3_OR = 3'b110;
  localparam F3_AND = 3'b111;

  // Branch operations
  localparam F3_BEQ = 3'b000;
  localparam F3_BNE = 3'b001;
  localparam F3_BLT = 3'b100;
  localparam F3_BGE = 3'b101;
  localparam F3_BLTU = 3'b110;
  localparam F3_BGEU = 3'b111;

  // Localparams for special bit
  localparam SPECIAL_BIT_0 = 1'b0;
  localparam SPECIAL_BIT_1 = 1'b1;

  // Inputs
  reg [31:0] a_i, b_i;
  reg  [ 5:0] op_i;

  // Outputs
  wire [31:0] result_o;

  // Instantiate the Unit Under Test (UUT)
  alu uut (
      .a_i     (a_i),
      .b_i     (b_i),
      .op_i    (op_i),
      .result_o(result_o)
  );

  // Variables for test tracking
  reg test_failed;
  integer test_case;
  integer opcode, op_a, op_b, op_low_b;

  // Helper task for checking results
  task check_result;
    input [31:0] expected_result;
    begin
      #10;  // Wait for outputs to settle
      if (result_o !== expected_result) begin
        $display("Error in test case %0d at time %0t:", test_case, $time);
        $display("  a_i = 0x%h, b_i = 0x%h", a_i, b_i);
        $display("  op_i = 0x%h", op_i);
        $display("  Expected result: 0x%h", expected_result);
        $display("  Got result:      0x%h", result_o);
        test_failed = 1;
      end
      test_case = test_case + 1;
    end
  endtask

  initial begin
    // Initialize test variables
    test_failed = 0;
    test_case   = 1;

    // Generate waveform file
    $dumpfile("dump/tb_alu.vcd");
    $dumpvars(0, tb_alu);

    ///////////////////////////
    // Comprehensive tests   //
    ///////////////////////////
    a_i = 32'h05555AAF;
    b_i = 32'h0AAAAC00;

    for (opcode = 0; opcode < 64; opcode = opcode + 1) begin
      op_i[5:4] = opcode[5:4];
      op_i[2:0] = opcode[2:0];
      op_i[3]   = (opcode[5:4] == COMP) ? SPECIAL_BIT_1 : opcode[3];

      // Modify the 2 most significant bits of a_i and b_i
      for (op_a = 0; op_a < 4; op_a = op_a + 1) begin
        a_i[31:30] = op_a[1:0];
        for (op_b = 0; op_b < 4; op_b = op_b + 1) begin
          b_i[31:30] = op_b[1:0];
          // Modify the 5 least significant bits of b_i (for shifts)
          for (op_low_b = 0; op_low_b < 32; op_low_b = op_low_b + 1) begin
            b_i[4:0] = op_low_b[4:0];
            case (op_i[5:4])
              ADD_SUB: check_result(op_i[3] ? a_i - b_i : a_i + b_i);
              COMP: begin
                case (op_i[2:0])
                  F3_BEQ:  check_result(a_i == b_i);
                  F3_BNE:  check_result(a_i != b_i);
                  F3_BLT:  check_result($signed(a_i) < $signed(b_i));
                  F3_BGE:  check_result($signed(a_i) >= $signed(b_i));
                  F3_BLTU: check_result(a_i < b_i);
                  F3_BGEU: check_result(a_i >= b_i);
                  default: check_result(32'd0)
                endcase 
              end
              LOGIC: begin
                case (op_i[2:0])
                  F3_XOR:  check_result(a_i ^ b_i);
                  F3_OR:   check_result(a_i | b_i);
                  F3_AND:  check_result(a_i & b_i);
                  default: check_result(32'd0);
                endcase
              end
              SHIFT: begin
                case (op_i[2:0])
                  F3_SLL:  check_result(a_i << b_i[4:0]);
                  F3_SR: begin
                    if (op_i[3]) check_result($signed(a_i) >>> b_i[4:0]);
                    else check_result(a_i >> b_i[4:0]);
                  end
                  default: check_result(32'd0);
                endcase
              end
            endcase
          end
        end
      end
    end

    // Display test completion message
    if (test_failed) begin
      $display("Some tests failed. Please check the waveform file 'tb_alu.vcd' for debugging.");
    end else begin
      $display("All %0d tests completed successfully!", test_case - 1);
    end

    // Finish simulation
    $finish;
  end
endmodule
