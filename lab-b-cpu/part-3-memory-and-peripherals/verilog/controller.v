module controller (
    input wire clk_i,
    input wire rst_ni,

    // Current instruction
    input wire [31:0] instruction_i,

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
    output reg [5:0] alu_op_o
);


    localparam ST_FETCH1 = 4'd0;
    localparam ST_FETCH2 = 4'd1;
    localparam ST_DECODE = 4'd2;
    localparam ST_R_TYPE = 4'd3;
    localparam ST_I_TYPE = 4'd4;
    localparam ST_U_TYPE = 4'd5;
    localparam ST_S_TYPE = 4'd6;
    localparam ST_LOAD1  = 4'd7;
    localparam ST_LOAD2  = 4'd8;
    localparam ST_BREAK  = 4'd9;
    localparam ST_B_TYPE = 4'd10;
    localparam ST_J_TYPE = 4'd11;
    localparam ST_JALR   = 4'd12;


    // ==========================
    // ALU operation encodings
    // ==========================
    localparam [5:0] ALU_ADD = 6'b000000;// A + B
    localparam [5:0] ALU_SUB = 6'b001000;// A - B

    localparam [5:0] ALU_AND = 6'b100111;// A & B
    localparam [5:0] ALU_OR  = 6'b100110;// A | B
    localparam [5:0] ALU_XOR = 6'b100100;// A ^ B

    localparam [5:0] ALU_SLL = 6'b110001;// A <<  B
    localparam [5:0] ALU_SRL = 6'b110101;// A >>  B (logique)
    localparam [5:0] ALU_SRA = 6'b111101;// A >>> B (arithm.)

    localparam [5:0] ALU_CMP_EQ   = 6'b011000;// A == B
    localparam [5:0] ALU_CMP_NE   = 6'b011001;// A != B
    localparam [5:0] ALU_CMP_SLT  = 6'b011100;// A <  B (signed)
    localparam [5:0] ALU_CMP_SGE  = 6'b011101;// A >= B (signed)
    localparam [5:0] ALU_CMP_SLTU = 6'b011110;// A <  B (unsigned)
    localparam [5:0] ALU_CMP_SGEU = 6'b011111;// A >= B (unsigned)

    reg [3:0] state_q, state_d;

    wire [6:0] opcode = instruction_i[6:0];
    wire [2:0] funct3 = instruction_i[14:12];
    wire [6:0] funct7 = instruction_i[31:25];
    wire [12:0] imm_b_13 =
    { instruction_i[31],       // imm[12]
      instruction_i[7],        // imm[11]
      instruction_i[30:25],    // imm[10:5]
      instruction_i[11:8],     // imm[4:1]
      1'b0                     // imm[0]
    };
    wire [20:0] imm_j_21 =
    { instruction_i[31],
      instruction_i[19:12],
      instruction_i[20],
      instruction_i[30:21],
      1'b0
    };

    always @(posedge clk_i) begin
        if (!rst_ni)
            state_q <= ST_FETCH1;
        else
            state_q <= state_d;
    end

    always @(*) begin
          case (state_q)
            ST_FETCH1: state_d = ST_FETCH2;
            ST_FETCH2: state_d = ST_DECODE;
            ST_DECODE: begin
                case (opcode)
                    7'b0110011: state_d = ST_R_TYPE;
                    7'b0010011: state_d = ST_I_TYPE;
                    7'b0110111: state_d = ST_U_TYPE;
                    7'b0100011: state_d = ST_S_TYPE;
                    7'b0000011: state_d = ST_LOAD1;
                    7'b1110011: state_d = ST_BREAK;
                    7'b1100011: state_d = ST_B_TYPE;
                    7'b1101111: state_d = ST_J_TYPE;
                    7'b1100111: state_d = ST_JALR;
                    default: state_d    = ST_BREAK;
                endcase
            end
            ST_I_TYPE: state_d = ST_FETCH2;
            ST_R_TYPE: state_d = ST_FETCH2;
            ST_U_TYPE: state_d = ST_FETCH2;
            ST_LOAD1 : state_d = ST_LOAD2;
            ST_LOAD2: state_d  = ST_FETCH1;
            ST_S_TYPE: state_d = ST_FETCH1;
            ST_BREAK: state_d  = ST_BREAK;
            ST_B_TYPE: state_d = ST_FETCH1;
            ST_J_TYPE: state_d = ST_FETCH1;
            ST_JALR: state_d = ST_FETCH1;
            default: state_d = state_q;
         endcase
    end

    always @(*) begin
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


        case (state_q)
            ST_FETCH1: begin
                we_o = 0;
            end
            ST_FETCH2: begin
                pc_en_o = 1;
                ir_en_o = 1;
            end
            ST_I_TYPE: begin
                imm_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
                rf_we_o = 1;
            end
            ST_R_TYPE: begin
                sel_b_o = 1;
                rf_we_o = 1;
            end
            ST_U_TYPE: begin
                sel_imm_o = 1;
                rf_we_o   = 1;
                imm_o     = { instruction_i[31:12], 12'b0 };
            end
            ST_LOAD1: begin
                sel_addr_o = 1;
                we_o       = 0;
                imm_o      = {{20{instruction_i[31]}}, instruction_i[31:20]};
            end
            ST_LOAD2: begin
                rf_we_o    = 1;
                sel_addr_o = 1;
                sel_mem_o  = 1;
                imm_o      = {{20{instruction_i[31]}}, instruction_i[31:20]};

            end
            ST_S_TYPE: begin
                sel_addr_o = 1;
                we_o       = 1;
                imm_o      = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
            end
            ST_B_TYPE: begin
                branch_op_o      = 1;
                sel_b_o          = 1;
                imm_o            = {{19{imm_b_13[12]}}, imm_b_13};
                pc_add_imm_o     = 1'b1;
                pc_sel_pc_base_o = 1;
            end
            ST_J_TYPE: begin
                rf_we_o          = 1;
                pc_en_o          = 1;
                pc_sel_pc_base_o = 1;
                pc_add_imm_o     = 1;
                sel_pc_o         = 1;
                imm_o            = {{11{imm_j_21[20]}}, imm_j_21};
            end
            ST_JALR: begin
                rf_we_o      = 1;
                pc_en_o      = 1;
                pc_sel_alu_o = 1;
                sel_pc_o     = 1;
                imm_o        = {{20{instruction_i[31]}}, instruction_i[31:20]};
            end
            ST_BREAK: begin
                // Break state - CPU halted, no outputs needed
            end
            ST_DECODE: begin
                // Decode state - no outputs needed, just determining next state
            end
            default: begin
                // Default case - maintain safe defaults (already set above)
            end
        endcase
    end

    always @ (*) begin
        alu_op_o = ALU_ADD;
        case (opcode)
            7'b0110011: begin
                case (funct3)
                    3'b000: begin
                        if (funct7[5])
                            alu_op_o = ALU_SUB;
                        else
                            alu_op_o = ALU_ADD;
                    end
                    3'b001: alu_op_o = ALU_SLL;
                    3'b010: alu_op_o = ALU_CMP_SLT;
                    3'b011: alu_op_o = ALU_CMP_SLTU;
                    3'b100: alu_op_o = ALU_XOR;
                    3'b101: begin
                        if (funct7[5])
                            alu_op_o  = ALU_SRA;
                        else
                            alu_op_o = ALU_SRL;
                    end
                    3'b110: alu_op_o = ALU_OR;
                    3'b111: alu_op_o = ALU_AND;
                    default: alu_op_o = ALU_ADD;
                endcase
            end
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_op_o = ALU_ADD;
                    3'b001: alu_op_o = ALU_SLL;
                    3'b010: alu_op_o = ALU_CMP_SLT;
                    3'b011: alu_op_o = ALU_CMP_SLTU;
                    3'b100: alu_op_o = ALU_XOR;
                    3'b101: begin
                        if (funct7[5])
                            alu_op_o  = ALU_SRA;
                        else
                            alu_op_o = ALU_SRL;
                    end
                    3'b110: alu_op_o = ALU_OR;
                    3'b111: alu_op_o = ALU_AND;
                    default: alu_op_o = ALU_ADD;
                endcase
            end
            7'b0100011:
                alu_op_o = ALU_ADD;
            7'b0000011:
                alu_op_o = ALU_ADD;
            7'b1100011: begin
                case (funct3)
                    3'b000: alu_op_o = ALU_CMP_EQ;
                    3'b001: alu_op_o = ALU_CMP_NE;
                    3'b100: alu_op_o = ALU_CMP_SLT;
                    3'b110: alu_op_o = ALU_CMP_SLTU;
                    3'b101: alu_op_o = ALU_CMP_SGE;
                    3'b111: alu_op_o = ALU_CMP_SGEU;
                    default: alu_op_o = ALU_ADD;
                endcase
            end
            7'b1100111:
                alu_op_o = ALU_ADD;
            default: alu_op_o = ALU_ADD;
        endcase
    end
endmodule
