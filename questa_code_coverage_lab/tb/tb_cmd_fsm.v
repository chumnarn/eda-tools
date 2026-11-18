//=============================================================================
// tb_cmd_fsm.v  --  ONE testbench, TWO tests, selected by a plusarg
//----------------------------------------------------------------------------
// Lab DUT testbench for "Using Code Coverage in QuestaSim"
//
// Why one testbench and not two?
//   When two different testbenches load the same DUT, the DUT ends up at
//   two different instance paths in the coverage database:
//
//       /tb_cmd_fsm_basic/dut     <- test 1
//       /tb_cmd_fsm_extra/dut     <- test 2
//
//   vcover merge then treats them as two DIFFERENT instances.  The bins are
//   NOT combined, they are simply added up, and the merged report shows
//   twice as many bins (50 branches instead of 25) with every bin still
//   partly uncovered.
//
//   By keeping the testbench name (and therefore the instance path)
//   identical and only changing the stimulus, the two tests land on the
//   same instance and the merge does what we want: the union of the hits.
//
//   Run:
//       vsim -coverage work.tb_cmd_fsm +TEST=basic
//       vsim -coverage work.tb_cmd_fsm +TEST=extra
//=============================================================================
`timescale 1ns / 1ps

module tb_cmd_fsm;

    reg        clk, rst_n, en;
    reg  [3:0] cmd, a, b;
    wire [3:0] result;
    wire       zero, parity, done;
    wire [1:0] state_o;

    cmd_fsm dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .en      (en),
        .cmd     (cmd),
        .a       (a),
        .b       (b),
        .result  (result),
        .zero    (zero),
        .parity  (parity),
        .done    (done),
        .state_o (state_o)
    );

    // 100 MHz clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    //---------------------------------------------------------------------
    // Apply the stimulus on the falling edge, sample on the rising edge, so
    // the DUT always sees settled values at the active clock edge.
    //---------------------------------------------------------------------
    task step;
        input [3:0] c;
        input [3:0] av;
        input [3:0] bv;
        input       e;
        begin
            @(negedge clk);
            cmd = c; a = av; b = bv; en = e;
            @(posedge clk);
            @(negedge clk);
            $display("[%0t] cmd=%h a=%h b=%h en=%b -> result=%h zero=%b parity=%b state=%0d done=%b",
                     $time, cmd, a, b, en, result, zero, parity, state_o, done);
        end
    endtask

    //---------------------------------------------------------------------
    // Test 1 : "basic"
    //   covers commands 4'h1 / 4'h2, the (a>b) and (a==b) condition rows
    //   and the FSM states IDLE / EXEC / WAIT.
    //---------------------------------------------------------------------
    task run_basic_test;
        begin
            $display("=== TEST 'basic' : start ===");
            step(4'h1, 4'd5,  4'd3, 1'b1);   // add        , a >  b
            step(4'h1, 4'd9,  4'd2, 1'b1);   // add        , a >  b
            step(4'h2, 4'd8,  4'd3, 1'b1);   // sub        , a >  b
            step(4'h1, 4'd5,  4'd5, 1'b1);   // add        , a == b
            step(4'h0, 4'd0,  4'd0, 1'b0);   // !en -> EXEC -> WAIT
            $display("=== TEST 'basic' : finished ===");
        end
    endtask

    //---------------------------------------------------------------------
    // Test 2 : "extra"
    //   covers commands 4'h3 / 4'h4 / default, the condition row where
    //   en=1 but a<b and a!=b, and the FSM states ST_DONE.
    //---------------------------------------------------------------------
    task run_extra_test;
        begin
            $display("=== TEST 'extra' : start ===");
            step(4'h3, 4'd6,  4'd3, 1'b1);   // xor
            step(4'h4, 4'd12, 4'd3, 1'b1);   // concat
            step(4'h5, 4'd2,  4'd7, 1'b1);   // default case item , a < b
            step(4'h0, 4'd0,  4'd0, 1'b0);   // !en -> EXEC -> WAIT
            step(4'h0, 4'd5,  4'd5, 1'b1);   // a == b -> WAIT -> DONE
            step(4'h0, 4'd0,  4'd0, 1'b0);   // !en -> DONE -> IDLE
            $display("=== TEST 'extra' : finished ===");
        end
    endtask

    //---------------------------------------------------------------------
    // Test 3 : "edge"
    //   Closes every gap that the first two tests leave behind:
    //     * the reset transition out of ST_EXEC and out of ST_WAIT
    //       (the FSM coverage counts a reset as a transition!)
    //     * the "a == b is false" row of the condition at line 50
    //       (the FSM has to sit in ST_WAIT while a /= b)
    //     * the a[1] / b[1] rows of the parity expression
    //     * the cmd[3] and b[3] toggle bins
    //---------------------------------------------------------------------
    task pulse_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    task run_edge_test;
        begin
            $display("=== TEST 'edge' : start ===");

            // ---- expression coverage of the parity expression ------------
            // (a[0]^b[0]) must be 0 so that the result of the OR is masked
            step(4'h0, 4'b0010, 4'b1010, 1'b1);  // a[1]=0 b[1]=1
            step(4'h0, 4'b0110, 4'b0010, 1'b1);  // a[1]=1 b[1]=0
            step(4'h0, 4'b1111, 4'b1111, 1'b1);  // a[0]=b[0]=1, a[1]=b[1]=1
            // a[0] and b[0] must DIFFER, otherwise the XOR term is 0 and
            // the OR term is masked -> the a[1] / b[1] rows stay empty
            step(4'h0, 4'b0000, 4'b0001, 1'b1);  // a[1]=0 b[1]=0 -> parity=0
            step(4'h0, 4'b0010, 4'b0001, 1'b1);  // a[1]=1 b[1]=0 -> parity=1

            // ---- toggle coverage : cmd[3] and b[3] must change value ----
            step(4'h8, 4'd8,  4'd12, 1'b1);       // cmd[3]=1 , b[3]=1
            step(4'h0, 4'd8,  4'd0,  1'b1);       // cmd[3]=0 , b[3]=0

            // ---- reset while the FSM is in ST_EXEC ----------------------
            step(4'h0, 4'd1,  4'd2,  1'b1);       // IDLE -> EXEC
            pulse_reset;                          // EXEC -> IDLE (reset)

            // ---- sit in ST_WAIT while a /= b ---------------------------
            step(4'h0, 4'd1,  4'd2,  1'b1);       // IDLE -> EXEC
            step(4'h0, 4'd1,  4'd2,  1'b0);       // EXEC -> WAIT
            step(4'h0, 4'd1,  4'd2,  1'b0);       // stay in WAIT, a /= b

            // ---- reset while the FSM is in ST_WAIT ----------------------
            pulse_reset;                          // WAIT -> IDLE (reset)

            $display("=== TEST 'edge' : finished ===");
        end
    endtask

    //---------------------------------------------------------------------
    // Test selection
    //---------------------------------------------------------------------
    reg [8*16-1:0] test_name;
    integer        plusarg_ok;

    initial begin
        test_name = "basic";
        rst_n = 1'b0; en = 1'b0; cmd = 4'h0; a = 4'h0; b = 4'h0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        plusarg_ok = $value$plusargs("TEST=%s", test_name);

        if      (test_name == "extra") run_extra_test;
        else if (test_name == "edge")  run_edge_test;
        else                           run_basic_test;

        $finish;
    end

endmodule
