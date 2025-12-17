module controller (
    input wire clk_i,
    input wire rst_ni,

    // Current instruction
    input wire [31:0] instruction_i,

    input wire ipending_i,

    // Branch operation
    output reg branch_op_o,

    // Immediate value correctly extended
    output reg [31:0] imm_o,

    // Instruction Register control signals
    output reg ir_en_o,

    // PC control signals
    output reg pc_add_imm_o,
    output reg pc_en_o,
    output reg pc_sel_alu_o,
    output reg pc_sel_pc_base_o,

    // Register file control signals
    output reg rf_we_o,

    // Multiplexer control signals
    output reg sel_addr_o,
    output reg sel_b_o,
    output reg sel_mem_o,
    output reg sel_pc_o,
    output reg sel_imm_o,

    // Memory control signals
    output reg we_o,

    // ALU control signals
    output reg [5:0] alu_op_o,

    output reg csr_write_o,
    output reg csr_set_o,
    output reg csr_clear_o,
    output reg csr_interrupt_o,
    output reg csr_mret_o,
    output reg sel_csr_o,
    output reg pc_sel_mtvec_o,
    output reg pc_sel_mepc_o
);

  ////////////////////
  // Constants
  ////////////////////

  // State definitions
  localparam FETCH1 = 4'b0000;
  localparam FETCH2 = 4'b0001;
  localparam DECODE = 4'b0010;
  localparam R_TYPE = 4'b0011;
  localparam I_TYPE = 4'b0100;
  localparam S_TYPE = 4'b0101;
  localparam B_TYPE = 4'b0110;
  localparam U_TYPE = 4'b0111;
  localparam J_TYPE = 4'b1000;
  localparam BREAK = 4'b1001;
  localparam LOAD1 = 4'b1010;
  localparam LOAD2 = 4'b1011;
  localparam JALR = 4'b1100;
  localparam CSR = 4'b1101;
  localparam INTERRUPT_RETURN = 4'b1110;

  // Opcode definitions
  localparam OPCODE_LOAD = 7'b0000011;
  localparam OPCODE_STORE = 7'b0100011;
  localparam OPCODE_BRANCH = 7'b1100011;
  localparam OPCODE_IMM_ARITH = 7'b0010011;
  localparam OPCODE_ARITH = 7'b0110011;
  localparam OPCODE_JALR = 7'b1100111;
  localparam OPCODE_JAL = 7'b1101111;
  localparam OPCODE_LUI = 7'b0110111;
  localparam OPCODE_SYSTEM = 7'b1110011;

  // funct3 definitions
  localparam F3_ADD_SUB = 3'b000;
  localparam F3_SLL = 3'b001;
  localparam F3_SLT = 3'b010;
  localparam F3_SLTU = 3'b011;
  localparam F3_XOR = 3'b100;
  localparam F3_SRL_SRA = 3'b101;
  localparam F3_OR = 3'b110;
  localparam F3_AND = 3'b111;

  ////////////////////
  // Internal wires
  ////////////////////
  wire [ 6:0] opcode_w;
  wire [ 2:0] funct3_w;
  wire [ 6:0] funct7_w;
  wire [31:0] imm_i_w;
  wire [31:0] imm_s_w;
  wire [31:0] imm_b_w;
  wire [31:0] imm_j_w;
  wire [31:0] imm_u_w;

  ////////////////////
  // State register
  ////////////////////
  reg [3:0] state_r, next_state_r;

  ////////////////////
  // Wire assignments
  ////////////////////
  assign opcode_w = instruction_i[6:0];
  assign funct3_w = instruction_i[14:12];
  assign funct7_w = instruction_i[31:25];
  assign imm_i_w = {{20{instruction_i[31]}}, instruction_i[31:20]};
  assign imm_s_w = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
  assign imm_b_w = {
    {20{instruction_i[31]}}, instruction_i[7], instruction_i[30:25], instruction_i[11:8], 1'b0
  };
  assign imm_j_w = {
    {12{instruction_i[31]}}, instruction_i[19:12], instruction_i[20], instruction_i[30:21], 1'b0
  };
  assign imm_u_w = {instruction_i[31:12], 12'b0};

  ////////////////////
  // State register
  ////////////////////
  always @(posedge clk_i) begin
    if (~rst_ni) begin
      state_r <= FETCH1;
    end else begin
      state_r <= next_state_r;
    end
  end

  ////////////////////
  // State machine
  ////////////////////
  always @(*) begin
    // Default values
    next_state_r     = state_r;
    branch_op_o      = 1'b0;
    imm_o            = 32'b0;
    ir_en_o          = 1'b0;
    pc_add_imm_o     = 1'b0;
    pc_en_o          = 1'b0;
    pc_sel_alu_o     = 1'b0;
    pc_sel_pc_base_o = 1'b0;
    rf_we_o          = 1'b0;
    sel_addr_o       = 1'b0;
    sel_b_o          = 1'b0;
    sel_mem_o        = 1'b0;
    sel_pc_o         = 1'b0;
    sel_imm_o        = 1'b0;
    we_o             = 1'b0;
    alu_op_o         = 6'b0;
    csr_write_o      = 1'b0;
    csr_set_o        = 1'b0;
    csr_clear_o      = 1'b0;
    csr_interrupt_o  = 1'b0;
    csr_mret_o       = 1'b0;
    sel_csr_o        = 1'b0;
    pc_sel_mtvec_o   = 1'b0;
    pc_sel_mepc_o    = 1'b0;

    case (state_r)
      FETCH1: begin
        next_state_r = FETCH2;
      end
      FETCH2: begin
        if (ipending_i) begin
          csr_interrupt_o = 1'b1;
          pc_sel_mtvec_o = 1'b1;
          pc_en_o = 1'b1;
          next_state_r = FETCH1;
        end else begin
          pc_en_o = 1'b1;
          ir_en_o = 1'b1;
          next_state_r = DECODE;
        end
      end
      DECODE: begin
        case (opcode_w)
          OPCODE_LOAD:      next_state_r = LOAD1;
          OPCODE_STORE:     next_state_r = S_TYPE;
          OPCODE_BRANCH:    next_state_r = B_TYPE;
          OPCODE_IMM_ARITH: next_state_r = I_TYPE;
          OPCODE_ARITH:     next_state_r = R_TYPE;
          OPCODE_JALR:      next_state_r = JALR;
          OPCODE_JAL:       next_state_r = J_TYPE;
          OPCODE_LUI:       next_state_r = U_TYPE;
          OPCODE_SYSTEM: begin
            if (funct3_w == 3'b000 && instruction_i[31:20] == 12'h001) begin
              next_state_r = BREAK;
            end else if (funct3_w == 3'b000 && instruction_i[31:20] == 12'h302) begin
              next_state_r = INTERRUPT_RETURN;
            end else if (funct3_w != 3'b000) begin
              next_state_r = CSR;
            end else begin
              next_state_r = FETCH1;
            end
          end
          default:          next_state_r = FETCH1;
        endcase
      end
      R_TYPE: begin
        sel_b_o = 1'b1;
        rf_we_o = 1'b1;
        next_state_r = FETCH2;
      end
      I_TYPE: begin
        imm_o = imm_i_w;
        rf_we_o = 1'b1;
        next_state_r = FETCH2;
      end
      U_TYPE: begin
        imm_o = imm_u_w;
        rf_we_o = 1'b1;
        sel_imm_o = 1'b1;
        next_state_r = FETCH2;
      end
      S_TYPE: begin
        imm_o = imm_s_w;
        sel_addr_o = 1'b1;
        we_o = 1'b1;
        next_state_r = FETCH1;
      end
      B_TYPE: begin
        imm_o = imm_b_w;
        branch_op_o = 1'b1;
        sel_b_o = 1'b1;
        pc_add_imm_o = 1'b1;
        pc_sel_pc_base_o = 1'b1;
        next_state_r = FETCH1;
      end
      J_TYPE: begin
        imm_o = imm_j_w;
        rf_we_o = 1'b1;
        pc_en_o = 1'b1;
        sel_pc_o = 1'b1;
        pc_add_imm_o = 1'b1;
        pc_sel_pc_base_o = 1'b1;
        next_state_r = FETCH1;
      end
      LOAD1: begin
        imm_o = imm_i_w;
        sel_addr_o = 1'b1;
        next_state_r = LOAD2;
      end
      LOAD2: begin
        imm_o = imm_i_w;
        sel_addr_o = 1'b1;
        sel_mem_o = 1'b1;
        rf_we_o = 1'b1;
        next_state_r = FETCH1;
      end
      JALR: begin
        imm_o = imm_i_w;
        rf_we_o = 1'b1;
        pc_en_o = 1'b1;
        sel_pc_o = 1'b1;
        pc_sel_alu_o = 1'b1;
        next_state_r = FETCH1;
      end
      BREAK: begin
        next_state_r = BREAK;
      end
      CSR: begin
         sel_csr_o = 1'b1;
         rf_we_o = 1'b1;
         case(funct3_w)
          3'b001: begin
            csr_write_o = 1'b1;
            sel_imm_o = 1'b0;
            imm_o       = 32'b0;
          end
          3'b010: begin
            csr_set_o = 1'b1;
            sel_imm_o = 1'b0;
            imm_o       = 32'b0;
          end
          3'b011: begin
            csr_clear_o = 1'b1;
            sel_imm_o = 1'b0;
            imm_o       = 32'b0;
          end
          3'b101: begin
            csr_write_o = 1'b1;
            sel_imm_o = 1'b1;
            imm_o       = {27'b0, instruction_i[19:15]};
          end
          3'b110: begin
            csr_set_o = 1'b1;
            sel_imm_o = 1'b1;
            imm_o       = {27'b0, instruction_i[19:15]};
          end
          3'b111: begin
            csr_clear_o = 1'b1;
            sel_imm_o = 1'b1;
            imm_o       = {27'b0, instruction_i[19:15]};
          end
          default: ;
         endcase
         next_state_r = FETCH2;
      end
      INTERRUPT_RETURN: begin
        csr_mret_o = 1'b1;
        pc_sel_mepc_o = 1'b1;
        pc_en_o = 1'b1;
        next_state_r = FETCH1;
      end
      default: begin
        next_state_r = FETCH1;
      end
    endcase
  end

  ////////////////////
  // ALU control
  ////////////////////
  always @(*) begin
    alu_op_o = 6'b000000;  // Default operation (ADD)

    case (opcode_w)
      OPCODE_ARITH, OPCODE_IMM_ARITH: begin
        alu_op_o[2:0] = (funct3_w == F3_SLT) ? 3'b100 : (funct3_w == F3_SLTU) ? 3'b110 : funct3_w;

        alu_op_o[3] = (funct3_w == F3_ADD_SUB && opcode_w == OPCODE_ARITH && funct7_w[5]) ||
                              (funct3_w == F3_SRL_SRA && funct7_w[5]) ||
                              (funct3_w == F3_SLT || funct3_w == F3_SLTU);

        alu_op_o[5:4] = (funct3_w == F3_SLT || funct3_w == F3_SLTU) ? 2'b01 :
                                (funct3_w == F3_XOR || funct3_w == F3_OR || funct3_w == F3_AND) ?
                                2'b10 :
                                (funct3_w == F3_SLL || funct3_w == F3_SRL_SRA) ? 2'b11 :
                                2'b00;
      end
      OPCODE_BRANCH: begin
        alu_op_o = {2'b01, 1'b1, funct3_w};
      end
      default: alu_op_o = 6'b000000;  // Default operation (ADD)
    endcase
  end

endmodule
