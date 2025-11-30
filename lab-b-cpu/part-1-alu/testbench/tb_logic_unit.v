`timescale 1ns / 1ps

module tb_logic_unit ();
    // Inputs
    reg [31:0] a_i, b_i;
    reg [2:0]  op_i;

    // Outputs
    wire [31:0] r_o;

    // Instantiate the Unit Under Test (UUT)
    logic_unit uut (
        .a_i  (a_i),
        .b_i  (b_i),
        .op_i (op_i),
        .r_o  (r_o)
    );

    // Operation codes (matching the logic_unit module)
    localparam XOR = 3'b100;
    localparam OR  = 3'b110;
    localparam AND = 3'b111;

    initial begin
        // Generate waveform file
        $dumpfile("dump/tb_logic_unit.vcd");
        $dumpvars(0, tb_logic_unit);

        // Test XOR operation
        #20;  // wait for circuit to settle

        // Test OR operation
        #20;  // wait for circuit to settle

        // Test AND operation
        #20;  // wait for circuit to settle

        // Test undefined operation (should default to all zeros)
        #20;  // wait for circuit to settle

        // Finish simulation
        $finish;
    end
endmodule