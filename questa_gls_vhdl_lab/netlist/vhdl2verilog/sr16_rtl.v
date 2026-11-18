module sr16
  (input  clk,
   input  rst_n,
   input  ld,
   input  [1:0] sh,
   input  [15:0] din,
   output [15:0] qout);
  reg [15:0] cq;
  wire n4_o;
  wire [14:0] n6_o;
  wire [15:0] n8_o;
  wire n10_o;
  wire [14:0] n11_o;
  wire [15:0] n13_o;
  wire n15_o;
  wire [1:0] n16_o;
  reg [15:0] n17_o;
  wire [15:0] n18_o;
  reg [15:0] n23_q;
  assign qout = cq; //(module output)
  /* rtl/sr16.vhd:30:10  */
  always @*
    cq = n23_q; // (isignal)
  initial
    cq = 16'b0000000000000000;
  /* rtl/sr16.vhd:35:14  */
  assign n4_o = ~rst_n;
  /* rtl/sr16.vhd:42:38  */
  assign n6_o = cq[15:1]; // extract
  /* rtl/sr16.vhd:42:34  */
  assign n8_o = {1'b0, n6_o};
  /* rtl/sr16.vhd:42:11  */
  assign n10_o = sh == 2'b01;
  /* rtl/sr16.vhd:43:32  */
  assign n11_o = cq[14:0]; // extract
  /* rtl/sr16.vhd:43:46  */
  assign n13_o = {n11_o, 1'b0};
  /* rtl/sr16.vhd:43:11  */
  assign n15_o = sh == 2'b10;
  assign n16_o = {n15_o, n10_o};
  /* rtl/sr16.vhd:41:9  */
  always @*
    case (n16_o)
      2'b10: n17_o = n13_o;
      2'b01: n17_o = n8_o;
      default: n17_o = cq;
    endcase
  /* rtl/sr16.vhd:38:7  */
  assign n18_o = ld ? din : n17_o;
  /* rtl/sr16.vhd:37:5  */
  always @(posedge clk or posedge n4_o)
    if (n4_o)
      n23_q <= 16'b0000000000000000;
    else
      n23_q <= n18_o;
endmodule

