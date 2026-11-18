module fsm_light
  (input  clk,
   input  rst_n,
   output [1:0] state,
   output red,
   output green,
   output yellow);
  reg [1:0] cstate;
  wire n7_o;
  wire n10_o;
  wire n12_o;
  wire n14_o;
  wire [2:0] n15_o;
  reg n20_o;
  reg n25_o;
  reg n30_o;
  reg [1:0] n35_o;
  reg [1:0] n49_q;
  reg n50_q;
  reg n51_q;
  reg n52_q;
  assign state = cstate; //(module output)
  assign red = n50_q; //(module output)
  assign green = n51_q; //(module output)
  assign yellow = n52_q; //(module output)
  /* rtl/fsm_light.vhd:32:10  */
  always @*
    cstate = n49_q; // (isignal)
  initial
    cstate = 2'b00;
  /* rtl/fsm_light.vhd:37:14  */
  assign n7_o = ~rst_n;
  /* rtl/fsm_light.vhd:44:9  */
  assign n10_o = cstate == 2'b00;
  /* rtl/fsm_light.vhd:49:9  */
  assign n12_o = cstate == 2'b01;
  /* rtl/fsm_light.vhd:54:9  */
  assign n14_o = cstate == 2'b10;
  assign n15_o = {n14_o, n12_o, n10_o};
  /* rtl/fsm_light.vhd:43:7  */
  always @*
    case (n15_o)
      3'b100: n20_o = 1'b1;
      3'b010: n20_o = 1'b0;
      3'b001: n20_o = 1'b0;
      default: n20_o = 1'b1;
    endcase
  /* rtl/fsm_light.vhd:43:7  */
  always @*
    case (n15_o)
      3'b100: n25_o = 1'b0;
      3'b010: n25_o = 1'b0;
      3'b001: n25_o = 1'b1;
      default: n25_o = 1'b0;
    endcase
  /* rtl/fsm_light.vhd:43:7  */
  always @*
    case (n15_o)
      3'b100: n30_o = 1'b0;
      3'b010: n30_o = 1'b1;
      3'b001: n30_o = 1'b0;
      default: n30_o = 1'b0;
    endcase
  /* rtl/fsm_light.vhd:43:7  */
  always @*
    case (n15_o)
      3'b100: n35_o = 2'b00;
      3'b010: n35_o = 2'b10;
      3'b001: n35_o = 2'b01;
      default: n35_o = 2'b00;
    endcase
  /* rtl/fsm_light.vhd:42:5  */
  always @(posedge clk or posedge n7_o)
    if (n7_o)
      n49_q <= 2'b00;
    else
      n49_q <= n35_o;
  /* rtl/fsm_light.vhd:42:5  */
  always @(posedge clk or posedge n7_o)
    if (n7_o)
      n50_q <= 1'b1;
    else
      n50_q <= n20_o;
  /* rtl/fsm_light.vhd:42:5  */
  always @(posedge clk or posedge n7_o)
    if (n7_o)
      n51_q <= 1'b0;
    else
      n51_q <= n25_o;
  /* rtl/fsm_light.vhd:42:5  */
  always @(posedge clk or posedge n7_o)
    if (n7_o)
      n52_q <= 1'b0;
    else
      n52_q <= n30_o;
endmodule

