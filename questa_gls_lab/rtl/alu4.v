//=====================================================================
// alu4.v -- LAB 08 : 4-bit ALU
//---------------------------------------------------------------------
// op :  0 = add, 1 = subtract, 2 = and, 3 = or, 4 = xor
// A bigger design than the counter : the gate netlist has dozens of
// cells instead of a handful, so the gate level simulation is really
// worth doing.
//=====================================================================
`timescale 1ns/10ps

module alu4 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] op,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [3:0] y,
    output wire       zero
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      y <= 4'd0;
    end else begin
      case (op)
        3'd0:    y <= a + b;
        3'd1:    y <= a - b;
        3'd2:    y <= a & b;
        3'd3:    y <= a | b;
        3'd4:    y <= a ^ b;
        default: y <= 4'd0;
      endcase
    end
  end

  assign zero = (y == 4'd0);

endmodule
