module leds (
    input  wire         clk_i,
    input  wire         rst_ni,
    input  wire         en_i,
    input  wire         we_i,
    input  wire [ 31:0] waddr_i,
    input  wire [ 31:0] wdata_i,
    output wire [119:0] led_r_o,
    output wire [119:0] led_g_o,
    output wire [119:0] led_b_o
);

  ////////////////////
  // Parameters
  ////////////////////
  localparam NUM_COLS = 12;
  localparam NUM_ROWS = 10;
  localparam TOTAL_LEDS = NUM_COLS * NUM_ROWS;
  localparam BASE_ADDR = 32'h50000000;

  ////////////////////
  // Internal wires
  ////////////////////
  wire [3:0] col_w;
  wire [3:0] row_w;
  wire update_r_w, update_g_w, update_b_w;
  wire [ 15:0] new_val_w;
  wire         is_base_addr_w;
  wire [119:0] update_mask_r_w;
  wire [119:0] update_mask_g_w;
  wire [119:0] update_mask_b_w;
  wire [119:0] new_values_w;

  ////////////////////
  // Internal Registers
  ////////////////////
  reg [119:0] led_r_r, led_g_r, led_b_r;

  ////////////////////
  // Assignments
  ////////////////////
  assign col_w          = wdata_i[3:0];
  assign row_w          = wdata_i[7:4];
  assign update_r_w     = wdata_i[8];
  assign update_g_w     = wdata_i[9];
  assign update_b_w     = wdata_i[10];
  assign new_val_w      = wdata_i[31:16];
  assign is_base_addr_w = (waddr_i == BASE_ADDR);

  ////////////////////
  // LED Update Logic
  ////////////////////
  genvar i, j;
  generate
    for (i = 0; i < NUM_ROWS; i = i + 1) begin : gen_rows
      for (j = 0; j < NUM_COLS; j = j + 1) begin : gen_cols
        localparam led_index = i * NUM_COLS + j;
        wire update_this_led_w = 
                    ((col_w == 4'b1111 || col_w == j) && (row_w == 4'b1111 || row_w == i)) ||
                    (col_w == j && row_w == 4'b1111) ||
                    (row_w == i && col_w == 4'b1111);
        assign update_mask_r_w[led_index] = update_r_w & update_this_led_w;
        assign update_mask_g_w[led_index] = update_g_w & update_this_led_w;
        assign update_mask_b_w[led_index] = update_b_w & update_this_led_w;
        wire new_led_value_w = 
                    (col_w == 4'b1111 && row_w == 4'b1111) ? new_val_w[0] :
                    (col_w == j && row_w == 4'b1111) ? new_val_w[i] :
                    (row_w == i && col_w == 4'b1111) ? new_val_w[j] : 
                    new_val_w[0];
        assign new_values_w[led_index] = new_led_value_w;
      end
    end
  endgenerate

  ////////////////////
  // LED Update Process
  ////////////////////
  always @(posedge clk_i) begin
    if (~rst_ni) begin
      led_r_r <= {TOTAL_LEDS{1'b0}};
      led_g_r <= {TOTAL_LEDS{1'b0}};
      led_b_r <= {TOTAL_LEDS{1'b0}};
    end else if (en_i && we_i && is_base_addr_w) begin
      led_r_r <= (led_r_r & ~update_mask_r_w) | (new_values_w & update_mask_r_w & {TOTAL_LEDS{update_r_w}});
      led_g_r <= (led_g_r & ~update_mask_g_w) | (new_values_w & update_mask_g_w & {TOTAL_LEDS{update_g_w}});
      led_b_r <= (led_b_r & ~update_mask_b_w) | (new_values_w & update_mask_b_w & {TOTAL_LEDS{update_b_w}});
    end
  end

  ////////////////////
  // Output Assignments
  ////////////////////
  assign led_r_o = led_r_r;
  assign led_g_o = led_g_r;
  assign led_b_o = led_b_r;

endmodule
