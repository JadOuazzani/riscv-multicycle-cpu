module buttons (
    input  wire        clk_i,
    input  wire        rst_ni,
    input  wire        en_i,
    input  wire [31:0] addr_i,
    input  wire [ 9:0] push_i,
    input  wire [ 7:0] switch_i,
    output reg  [31:0] rdata_o
);
    // Base address
    localparam BASE_ADDR = 32'h70000000;

    // Internal register to hold read data
    reg [31:0] val;

    // Read Address Registering
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            val <= 32'h0;
        end else if (en_i && (addr_i == BASE_ADDR)) begin
            val <= {8'b0, switch_i, 6'b0, push_i};
        end
    end

    // Read Data Output with 1-cycle latency
    always @(*) begin
        rdata_o = val;
    end
endmodule
