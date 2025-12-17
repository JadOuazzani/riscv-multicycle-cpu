
module csr (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire [11:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire        irq_i,
    input  wire [31:0] pc_i,
    input  wire        write_i,
    input  wire        set_i,
    input  wire        clear_i,
    input  wire        interrupt_i,
    input  wire        mret_i,
    output wire [31:0] rdata_o,
    output wire [31:0] mtvec_o,
    output wire [31:0] mepc_o,
    output wire        ipending_o
);

  //! Don't change the following definition.
  //! Should be used for storing the CSR registers values as
  //! described in the assignment.
  reg [31:0] mstatus_r, mie_r, mtvec_r, mepc_r, mcause_r, mip_r;

  localparam MSTATUS_MASK = 32'h00001888;
  localparam MIE_MASK     = 32'h00000800;
  localparam MCAUSE_MASK  = 32'h80000800;
  localparam MIP_MASK     = 32'h00000800;

  assign rdata_o = (addr_i == 12'h300) ? mstatus_r :
                   (addr_i == 12'h304) ? mie_r     :
                   (addr_i == 12'h305) ? mtvec_r   :
                   (addr_i == 12'h341) ? mepc_r    :
                   (addr_i == 12'h342) ? mcause_r  :
                   (addr_i == 12'h344) ? mip_r     : 32'h0;

  assign ipending_o = mstatus_r[3] && |(mip_r & mie_r);
  assign mtvec_o = mtvec_r;
  assign mepc_o  = mepc_r;


  always @(posedge clk_i) begin
    if (!rst_ni) begin
      mstatus_r <= 32'h1800;
      mie_r     <= 32'h0;
      mtvec_r   <= 32'h0;
      mepc_r    <= 32'h0;
      mcause_r  <= 32'h0;
      mip_r     <= 32'h0;
    end else begin
      // mret and CSR operations are mutually exclusive
      if (mret_i) begin
        mstatus_r[3] <= mstatus_r[7];
        mstatus_r[7] <= 1'b1;
      end else if (write_i) begin
        case (addr_i)
          12'h300: mstatus_r <= wdata_i & MSTATUS_MASK;
          12'h304: mie_r     <= wdata_i & MIE_MASK;
          12'h305: mtvec_r   <= wdata_i;
          12'h341: mepc_r    <= wdata_i;
          12'h342: mcause_r  <= wdata_i & MCAUSE_MASK;
          12'h344: mip_r     <= wdata_i & MIP_MASK;
          default: ;
        endcase
      end else if (set_i) begin
        case (addr_i)
          12'h300: mstatus_r <= (mstatus_r | wdata_i) & MSTATUS_MASK;
          12'h304: mie_r     <= (mie_r     | wdata_i) & MIE_MASK;
          12'h305: mtvec_r   <= mtvec_r   | wdata_i;
          12'h341: mepc_r    <= mepc_r    | wdata_i;
          12'h342: mcause_r  <= (mcause_r | wdata_i) & MCAUSE_MASK;
          12'h344: mip_r     <= (mip_r    | wdata_i) & MIP_MASK;
          default: ;
        endcase
      end else if (clear_i) begin
        case (addr_i)
          12'h300: mstatus_r <= mstatus_r & ~wdata_i;
          12'h304: mie_r     <= mie_r     & ~wdata_i;
          12'h305: mtvec_r   <= mtvec_r   & ~wdata_i;
          12'h341: mepc_r    <= mepc_r    & ~wdata_i;
          12'h342: mcause_r  <= mcause_r  & ~wdata_i;
          12'h344: mip_r     <= mip_r     & ~wdata_i;
          default: ;
        endcase
      end

      // Hardware signals have highest priority (last assignment wins)
      if (interrupt_i) begin
        mepc_r       <= pc_i;
        mcause_r     <= 32'h80000800;
        mstatus_r[7] <= mstatus_r[3];
        mstatus_r[3] <= 1'b0;
      end
        mip_r[11] <= irq_i;
    end
  end
endmodule
