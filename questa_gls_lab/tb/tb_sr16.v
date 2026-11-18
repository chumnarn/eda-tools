//=====================================================================
// tb_sr16.v -- LAB 08 : self checking testbench for sr16
//---------------------------------------------------------------------
// Plusargs : +tracefile=<name>  +resultfile=<name>
//=====================================================================
`timescale 1ns/10ps

module tb_sr16;

  reg        clk   = 1'b0;
  reg        rst_n = 1'b0;
  reg        ld    = 1'b0;
  reg  [1:0] sh    = 2'd0;
  reg  [15:0] din  = 16'd0;
  wire [15:0] qout;

  integer errors = 0;
  integer checks = 0;
  integer fh;
  reg [8*64:1] tracefile  = "trace.txt";
  reg [8*64:1] resultfile = "result.txt";

  sr16 dut (.clk(clk), .rst_n(rst_n), .ld(ld), .sh(sh), .din(din), .qout(qout));

  always #5 clk = ~clk;

  task check_qout(input [15:0] got, input [15:0] exp, input [8*16:1] what);
    begin
      checks = checks + 1;
      if (got !== exp) begin
        errors = errors + 1;
        $display("** FAIL %0s : expected %h but got %h", what, exp, got);
      end
      $fdisplay(fh, "qout=%h", got);
      $display("  t=%0.3f ns : %0s -> qout = %h", $realtime, what, got);
    end
  endtask

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

    $display("=== tb_sr16 : %0s ===", $test$plusargs("GATE") ? "GATE LEVEL" : "RTL");

    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    #1;
    check_qout(qout, 16'h0000, "after reset");

    rst_n = 1'b1;
    ld   = 1'b1;
    din  = 16'hA5C3;
    @(posedge clk);
    #1;
    check_qout(qout, 16'hA5C3, "parallel load");

    ld = 1'b0;
    sh = 2'd2;                       // shift left
    @(posedge clk);
    #1;
    check_qout(qout, 16'h4B86, "shift left");

    sh = 2'd1;                       // shift right
    @(posedge clk);
    #1;
    check_qout(qout, 16'h25C3, "shift right");

    sh = 2'd0;                       // hold
    @(posedge clk);
    #1;
    check_qout(qout, 16'h25C3, "hold");

    $fclose(fh);
    $display("  checks = %0d , errors = %0d", checks, errors);
    if (errors == 0) begin
      $display("TEST_PASSED : tb_sr16 completed");
      write_result(resultfile, "PASS");
    end else begin
      $display("TEST_FAILED : %0d error(s)", errors);
      write_result(resultfile, "FAIL");
    end
    $finish;
  end

endmodule
