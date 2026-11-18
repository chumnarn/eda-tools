module alu4
  (input  clk,
   input  rst_n,
   input  [2:0] op,
   input  [3:0] a,
   input  [3:0] b,
   output [3:0] y,
   output zero);
  reg [3:0] cq;
  wire n7_o;
  wire [3:0] n9_o;
  wire n11_o;
  wire [3:0] n12_o;
  wire n14_o;
  wire [3:0] n15_o;
  wire n17_o;
  wire [3:0] n18_o;
  wire n20_o;
  wire [3:0] n21_o;
  wire n23_o;
  wire [4:0] n24_o;
  reg [3:0] n26_o;
  wire n43_o;
  wire n44_o;
  reg [3:0] n46_q;
  assign y = cq; //(module output)
  assign zero = n44_o; //(module output)
  /* rtl/alu4.vhd:32:10  */
  always @*
    cq = n46_q; // (isignal)
  initial
    cq = 4'b0000;
  /* rtl/alu4.vhd:39:14  */
  assign n7_o = ~rst_n;
  /* rtl/alu4.vhd:45:32  */
  assign n9_o = a + b;
  /* rtl/alu4.vhd:45:9  */
  assign n11_o = op == 3'b000;
  /* rtl/alu4.vhd:46:32  */
  assign n12_o = a - b;
  /* rtl/alu4.vhd:46:9  */
  assign n14_o = op == 3'b001;
  /* rtl/alu4.vhd:47:32  */
  assign n15_o = a & b;
  /* rtl/alu4.vhd:47:9  */
  assign n17_o = op == 3'b010;
  /* rtl/alu4.vhd:48:32  */
  assign n18_o = a | b;
  /* rtl/alu4.vhd:48:9  */
  assign n20_o = op == 3'b011;
  /* rtl/alu4.vhd:49:32  */
  assign n21_o = a ^ b;
  /* rtl/alu4.vhd:49:9  */
  assign n23_o = op == 3'b100;
  assign n24_o = {n23_o, n20_o, n17_o, n14_o, n11_o};
  /* rtl/alu4.vhd:44:7  */
  always @*
    case (n24_o)
      5'b10000: n26_o = n21_o;
      5'b01000: n26_o = n18_o;
      5'b00100: n26_o = n15_o;
      5'b00010: n26_o = n12_o;
      5'b00001: n26_o = n9_o;
      default: n26_o = 4'b0000;
    endcase
  /* rtl/alu4.vhd:56:23  */
  assign n43_o = cq == 4'b0000;
  /* rtl/alu4.vhd:56:15  */
  assign n44_o = n43_o ? 1'b1 : 1'b0;
  /* rtl/alu4.vhd:41:5  */
  always @(posedge clk or posedge n7_o)
    if (n7_o)
      n46_q <= 4'b0000;
    else
      n46_q <= n26_o;
endmodule

