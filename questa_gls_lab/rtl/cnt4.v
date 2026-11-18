//=====================================================================
// cnt4.v -- LAB 01..08 : 4-bit up counter with asynchronous reset
//---------------------------------------------------------------------
// The design that is carried through the whole guide:
//   RTL  (this file)  --->  Yosys  --->  gate netlist  --->  GLS
//
// The module name and the port list are IDENTICAL in the RTL and in
// the gate netlist.  That is the whole point of the guide : the same
// testbench runs at RTL level and at gate level, you only change
// which source file is compiled into "work".
//=====================================================================
`timescale 1ns/10ps

module cnt4 (
    input  wire       clk,
    input  wire       rst_n,     // asynchronous, active low
    input  wire       en,
    output reg  [3:0] q
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      q <= 4'd0;   // asynchronous reset
    else if (en)     q <= q + 4'd1;
  end

endmodule
