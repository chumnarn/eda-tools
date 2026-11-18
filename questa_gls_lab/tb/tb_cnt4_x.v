//=====================================================================
// tb_cnt4_x.v -- LAB 06 : what happens when an input becomes 'x' ?
//---------------------------------------------------------------------
// THIS TESTBENCH DOES NOT JUDGE.  It only OBSERVES and writes what it
// saw into a file, because the interesting part of this lab is that
// the RTL and the gate level do NOT behave the same way:
//
//   RTL  :  "if (en)" with en = 'x'  ->  the condition is not true
//           -> the else branch is taken -> the register HOLDS its value
//
//   GLS  :  'en' goes through real gates (xor / and) -> 'x' propagates
//           -> the D input of the flip-flop becomes 'x' -> the register
//           captures 'x'
//
// The batch script compares the two observations and decides whether
// the difference was seen.
//
// Plusargs :
//   +obsfile=<name>     where the observation is written (default observed.txt)
//   +resultfile=<name>  where PASS / FAIL is written     (default result.txt)
//=====================================================================
`timescale 1ns/10ps

module tb_cnt4_x;

  reg        clk   = 1'b0;
  reg        rst_n = 1'b0;
  reg        en    = 1'b1;
  wire [3:0] q;

  integer    fh;
  integer    i;
  reg [8*64:1] obsfile    = "observed.txt";
  reg [8*64:1] resultfile = "result.txt";

  cnt4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q));

  always #5 clk = ~clk;

  initial begin
    if ($value$plusargs("obsfile=%s",    obsfile)    == 0) obsfile    = "observed.txt";
    if ($value$plusargs("resultfile=%s", resultfile) == 0) resultfile = "result.txt";

    fh = $fopen(obsfile, "w");
    if (fh == 0) begin
      $display("** ERROR : cannot open the observation file %0s", obsfile);
      $finish;
    end

    $display("=== tb_cnt4_x : %0s ===", $test$plusargs("GATE") ? "GATE LEVEL" : "RTL");

    //---- 1. reset and count to 3 ---------------------------------
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    #1 rst_n = 1'b1;
    for (i = 1; i <= 3; i = i + 1) begin
      @(posedge clk);
      #1;
    end
    $display("  t=%0.3f ns : before the 'x'      q = %h", $realtime, q);

    //---- 2. drive 'x' into the enable ----------------------------
    en = 1'bx;
    repeat (2) @(posedge clk);
    #1;
    $display("  t=%0.3f ns : after  en = 'x'     q = %h", $realtime, q);

    //---- 3. write down what we saw --------------------------------
    $fdisplay(fh, "observed=%h", q);
    $fclose(fh);

    $display("=== tb_cnt4_x finished ===");
    $finish;
  end

endmodule
