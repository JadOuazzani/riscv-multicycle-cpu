module buttons (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire [ 9:0] push_i,
    input  wire [ 7:0] switch_i,
    output wire [31:0] rdata_o,
    output wire        irq_o
);
  ////////////////////
  // Constants
  ////////////////////
  localparam ADDR_VAL = 4'h0;
  localparam ADDR_SRC = 4'h4;
  localparam ADDR_PTM = 4'h8;
  localparam ADDR_STM = 4'hC;

  ////////////////////
  // Internal Registers
  ////////////////////
  reg [31:0] val_r;
  reg        read_r;
  reg [31:0] addr_r;
  reg [31:0] src_r;
  reg [19:0] ptm_r;
  reg [15:0] stm_r;

  reg [9:0]  push_d;
  reg [7:0]  switch_d;
  wire [9:0] push_irq;
  wire [7:0] switch_irq;

  ////////////////////
  // Write Logic
  ////////////////////
  always @(posedge clk_i) begin
    if (!rst_ni) begin
      val_r <= 32'h0;
    end else begin
      val_r <= {8'h0, switch_i, 6'h0, push_i};
    end
  end


  ////////////////////
  // Delayed signals
  ////////////////////
  always @(posedge clk_i) begin
    if (!rst_ni) begin
      push_d   <= 10'b0;
      switch_d <= 8'b0;
    end else begin
      push_d   <= push_i;
      switch_d <= switch_i;
    end
  end

  ////////////////////
  // PTM and STM registers
  ////////////////////
  always @(posedge clk_i) begin
    if (!rst_ni) begin
      ptm_r <= 20'hFFFFF;
      stm_r <= 16'hFFFF;
    end
    else if (en_i && we_i) begin
      if (addr_i[3:0] == ADDR_PTM)
        ptm_r <= wdata_i[19:0];
      else if (addr_i[3:0] == ADDR_STM)
        stm_r <= wdata_i[15:0];
    end
  end

  genvar i;
  generate
    for (i = 0;i < 10;i = i + 1) begin : gen_push
      wire [1:0] mode        = ptm_r[2*i +: 2];
      wire       curr        = push_i[i];
      wire       prev        = push_d[i];
      assign     push_irq[i] = (mode == 2'b00) ? ~curr :
                     (mode == 2'b01) ? (~prev & curr) | src_r[i] :
                     (mode == 2'b10) ? (prev & ~curr) | src_r[i] :
                                       curr;

    end

    for (i = 0;i <  8;i = i + 1) begin : gen_switch
      wire [1:0] mode          = stm_r[2*i +: 2];
      wire       curr          = switch_i[i];
      wire       prev          = switch_d[i];
      assign     switch_irq[i] = (mode == 2'b00) ? ~curr :
                     (mode == 2'b01) ? (~prev & curr) | src_r[16 + i] :
                     (mode == 2'b10) ? (prev & ~curr) | src_r[16 + i] :
                                       curr;
    end
  endgenerate

  ////////////////////
  // SRC register
  ////////////////////
  always @(posedge clk_i) begin
    if ((en_i && we_i && addr_i[3:0] == ADDR_SRC && wdata_i == 32'h0) || (!rst_ni))
      src_r <= 32'h0;
    else begin
      src_r <= {8'b0, switch_irq, 6'b0, push_irq};
    end
  end

  ////////////////////
  // Read Logic
  ////////////////////
  always @(posedge clk_i) begin
    read_r <= en_i;
    addr_r <= addr_i;
  end

  ////////////////////
  // Output Assignment
  ////////////////////
  assign rdata_o = read_r ? (addr_r[3:0] == ADDR_VAL ? val_r
              : (addr_r[3:0] == ADDR_SRC ? src_r : 32'h0)) : 32'h0;
  assign irq_o   = |src_r;

endmodule
