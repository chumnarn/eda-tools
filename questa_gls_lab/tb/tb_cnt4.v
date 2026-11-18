//=====================================================================
// tb_cnt4.v -- self checking testbench for cnt4
//---------------------------------------------------------------------
// THIS TESTBENCH RUNS AT BOTH LEVELS.
//
// The module name and the port list of the RTL and of the gate
// netlist are identical, so the testbench does not change at all:
// only the file that is compiled into "work" changes.
//
//   RTL  :  vlog ../rtl/cnt4.v        tb/tb_cnt4.v
//   GLS  :  vlog ../cells/...  ../netlist/cnt4_net.v   tb/tb_cnt4.v
//
// It also writes a trace file so that the RTL run and the gate level
// run can be compared line by line (LAB 05).
//
// Plusargs :
//   +tracefile=<name>   where the trace is written   (default trace.txt)
//   +resultfile=<name>  where PASS / FAIL is written  (default result.txt)
//=====================================================================
`timescale 1ns/10ps

module tb_cnt4;

  reg        clk   = 1'b0;
  reg        rst_n = 1'b0;
  reg        en    = 1'b1;
  wire [3:0] q;

  integer errors = 0;
  integer checks = 0;
  integer fh;
  integer i;
  reg [8*64:1] tracefile = "trace.txt";
  reg [8*64:1] resultfile = "result.txt";

  //-------------------------------------------------------------------
  // the device under test -- the SAME instance for RTL and for GLS
  //-------------------------------------------------------------------
  cnt4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q));

  always #5 clk = ~clk;          // 100 MHz

  //-------------------------------------------------------------------
  // one check + one line of the trace
  //-------------------------------------------------------------------
  task check_q(input [3:0] got, input [3:0] exp, input [8*16:1] what);
    begin
      checks = checks + 1;
      if (got !== exp) begin
        errors = errors + 1;
        $display("** FAIL %0s : expected %h but got %h", what, exp, got);
      end
      $fdisplay(fh, "q=%h", got);
    end
  endtask

  //-------------------------------------------------------------------
  // write the verdict into a file : the batch runner reads that file
  // (never the exit code of vsim, it is always 0)
  //-------------------------------------------------------------------
  task write_result(input [8*64:1] fname, input [8*16:1] verdict);
    integer f;
    begin
      f = $fopen(fname, "w");
      if (f != 0) begin
        $fdisplay(f, "%0s", verdict);
        $fclose(f);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("tracefile=%s",  tracefile)  == 0) tracefile  = "trace.txt";
    if ($value$plusargs("resultfile=%s", resultfile) == 0) resultfile = "result.txt";

    fh = $fopen(tracefile, "w");
    if (fh == 0) begin
      $display("** ERROR : cannot open the trace file %0s", tracefile);
      $finish;
    end

    $display("=== tb_cnt4 : %0s ===", $test$plusargs("GATE") ? "GATE LEVEL" : "RTL");

    //---- 1. reset --------------------------------------------------
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    #1;
    check_q(q, 4'h0, "after reset");
    $display("  t=%0.3f ns : after reset          q = %h", $realtime, q);

    //---- 2. count up ----------------------------------------------
    rst_n = 1'b1;
    for (i = 1; i <= 6; i = i + 1) begin
      @(posedge clk);
      #1;
      check_q(q, i[3:0], "count up");
      $display("  t=%0.3f ns : count up             q = %h", $realtime, q);
    end

    //---- 3. hold while en = 0 -------------------------------------
    en = 1'b0;
    repeat (3) @(posedge clk);
    #1;
    check_q(q, 4'h6, "hold, en=0");
    $display("  t=%0.3f ns : hold, en = 0          q = %h", $realtime, q);

    //---- 4. count up again ----------------------------------------
    en = 1'b1;
    repeat (3) @(posedge clk);
    #1;
    check_q(q, 4'h9, "count up again");
    $display("  t=%0.3f ns : count up again       q = %h", $realtime, q);

    $fclose(fh);

    //---- 5. verdict ------------------------------------------------
    $display("  checks = %0d , errors = %0d", checks, errors);
    if (errors == 0) begin
      $display("TEST_PASSED : tb_cnt4 completed");
      write_result(resultfile, "PASS");
    end else begin
      $display("TEST_FAILED : %0d error(s)", errors);
      write_result(resultfile, "FAIL");
    end
    $finish;
  end

endmodule
