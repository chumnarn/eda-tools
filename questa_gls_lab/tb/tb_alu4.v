//=====================================================================
// tb_alu4.v -- LAB 08 : self checking testbench for alu4
//---------------------------------------------------------------------
// Same testbench for the RTL and for the gate netlist.
// Plusargs : +tracefile=<name>  +resultfile=<name>
//=====================================================================
`timescale 1ns/10ps

module tb_alu4;

  reg        clk   = 1'b0;
  reg        rst_n = 1'b0;
  reg  [2:0] op    = 3'd0;
  reg  [3:0] a     = 4'd0;
  reg  [3:0] b     = 4'd0;
  wire [3:0] y;
  wire       zero;

  integer errors = 0;
  integer checks = 0;
  integer fh;
  reg [8*64:1] tracefile  = "trace.txt";
  reg [8*64:1] resultfile = "result.txt";

  alu4 dut (.clk(clk), .rst_n(rst_n), .op(op), .a(a), .b(b), .y(y), .zero(zero));

  always #5 clk = ~clk;

  task do_op(input [2:0] o, input [3:0] av, input [3:0] bv,
             input [3:0] exp, input [8*16:1] what);
    begin
      op = o; a = av; b = bv;
      @(posedge clk);
      #1;
      checks = checks + 1;
      if (y !== exp) begin
        errors = errors + 1;
        $display("** FAIL %0s : expected %h but got %h", what, exp, y);
      end
      $fdisplay(fh, "op=%0d a=%h b=%h y=%h zero=%b", o, av, bv, y, zero);
      $display("  t=%0.3f ns : %0s -> y = %h (zero = %b)", $realtime, what, y, zero);
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

    $display("=== tb_alu4 : %0s ===", $test$plusargs("GATE") ? "GATE LEVEL" : "RTL");

    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    #1 rst_n = 1'b1;

    do_op(3'd0, 4'd7, 4'd5, 4'hC, "add");
    do_op(3'd1, 4'd7, 4'd5, 4'h2, "sub");
    do_op(3'd2, 4'hC, 4'hA, 4'h8, "and");
    do_op(3'd3, 4'hC, 4'hA, 4'hE, "or");
    do_op(3'd4, 4'hC, 4'hA, 4'h6, "xor");
    do_op(3'd0, 4'hF, 4'h1, 4'h0, "add with carry out");

    $fclose(fh);
    $display("  checks = %0d , errors = %0d", checks, errors);
    if (errors == 0) begin
      $display("TEST_PASSED : tb_alu4 completed");
      write_result(resultfile, "PASS");
    end else begin
      $display("TEST_FAILED : %0d error(s)", errors);
      write_result(resultfile, "FAIL");
    end
    $finish;
  end

endmodule
