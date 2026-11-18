module cnt4
  (input  clk,
   input  rst_n,
   input  en,
   output [3:0] q);
  reg [3:0] cq;
  wire n4_o;
  wire [3:0] n7_o;
  wire [3:0] n13_o;
  reg [3:0] n14_q;
  assign q = cq; //(module output)
  /* rtl/cnt4.vhd:18:10  */
  always @*
    cq = n14_q; // (isignal)
  initial
    cq = 4'b0000;
  /* rtl/cnt4.vhd:23:14  */
  assign n4_o = ~rst_n;
  /* rtl/cnt4.vhd:27:18  */
  assign n7_o = cq + 4'b0001;
  /* rtl/cnt4.vhd:25:5  */
  assign n13_o = en ? n7_o : cq;
  /* rtl/cnt4.vhd:25:5  */
  always @(posedge clk or posedge n4_o)
    if (n4_o)
      n14_q <= 4'b0000;
    else
      n14_q <= n13_o;
endmodule

