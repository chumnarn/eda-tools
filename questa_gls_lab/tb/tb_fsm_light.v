//=====================================================================
// tb_fsm_light.v -- LAB 08 : self checking testbench for fsm_light
//---------------------------------------------------------------------
// The testbench follows the state sequence and checks the outputs.
// Plusargs : +tracefile=<name>  +resultfile=<name>
//=====================================================================
`timescale 1ns/10ps

module tb_fsm_light;

  reg        clk   = 1'b0;
  reg        rst_n = 1'b0;
  wire [1:0] state;
  wire       red, green, yellow;

  integer errors = 0;
  integer checks = 0;
  integer fh;
  reg [8*64:1] tracefile  = "trace.txt";
  reg [8*64:1] resultfile = "result.txt";

  fsm_light dut (.clk(clk), .rst_n(rst_n), .state(state),
                 .red(red), .green(green), .yellow(yellow));

  always #5 clk = ~clk;

  task check_state(input [1:0] exp_state, input exp_red, input exp_green,
                   input exp_yellow, input [8*16:1] what);
    begin
      checks = checks + 1;
      if (state !== exp_state || red !== exp_red || green !== exp_green || yellow !== exp_yellow) begin
        errors = errors + 1;
        $display("** FAIL %0s : state=%h red=%b green=%b yellow=%b", what, state, red, green, yellow);
      end
      $fdisplay(fh, "state=%h red=%b green=%b yellow=%b", state, red, green, yellow);
      $display("  t=%0.3f ns : %0s -> state=%h red=%b green=%b yellow=%b",
               $realtime, what, state, red, green, yellow);
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

    $display("=== tb_fsm_light : %0s ===", $test$plusargs("GATE") ? "GATE LEVEL" : "RTL");

    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    #1 rst_n = 1'b1;
    #1;
    check_state(2'd0, 1'b1, 1'b0, 1'b0, "after reset");

    @(posedge clk); #1;
    check_state(2'd1, 1'b0, 1'b1, 1'b0, "RED -> GREEN");

    @(posedge clk); #1;
    check_state(2'd2, 1'b0, 1'b0, 1'b1, "GREEN -> YELLOW");

    @(posedge clk); #1;
    check_state(2'd0, 1'b1, 1'b0, 1'b0, "YELLOW -> RED");

    @(posedge clk); #1;
    check_state(2'd1, 1'b0, 1'b1, 1'b0, "RED -> GREEN again");

    $fclose(fh);
    $display("  checks = %0d , errors = %0d", checks, errors);
    if (errors == 0) begin
      $display("TEST_PASSED : tb_fsm_light completed");
      write_result(resultfile, "PASS");
    end else begin
      $display("TEST_FAILED : %0d error(s)", errors);
      write_result(resultfile, "FAIL");
    end
    $finish;
  end

endmodule
