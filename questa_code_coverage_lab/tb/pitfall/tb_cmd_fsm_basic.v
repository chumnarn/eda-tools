//=============================================================================
// tb_cmd_fsm_basic.v  --  PITFALL DEMO ONLY (Lab 4)
//----------------------------------------------------------------------------
// This file exists to demonstrate the most common mistake when merging
// coverage data: using a DIFFERENT testbench name for every test.
//
// Because the testbench name is part of the instance path, this test puts
// the DUT at
//       /tb_cmd_fsm_basic/dut
// while tb_cmd_fsm_extra.v puts it at
//       /tb_cmd_fsm_extra/dut
//
// vcover merge then sees two different instances and ADDS their bins
// instead of combining them.  See the "Pitfall" section of the lab guide.
//
// The recommended way is the single testbench tb/tb_cmd_fsm.v with the
// +TEST= plusarg.  This file is kept only for the demonstration.
//=============================================================================
`timescale 1ns / 1ps

module tb_cmd_fsm_basic;

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

    initial clk = 1'b0;
    always #5 clk = ~clk;

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

    initial begin
        rst_n = 1'b0; en = 1'b0; cmd = 4'h0; a = 4'h0; b = 4'h0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        $display("=== TB_CMD_FSM_BASIC : start ===");
        step(4'h1, 4'd5,  4'd3, 1'b1);
        step(4'h1, 4'd9,  4'd2, 1'b1);
        step(4'h2, 4'd8,  4'd3, 1'b1);
        step(4'h1, 4'd5,  4'd5, 1'b1);
        step(4'h0, 4'd0,  4'd0, 1'b0);
        $display("=== TB_CMD_FSM_BASIC : finished ===");
        $finish;
    end

endmodule
