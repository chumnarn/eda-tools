//=============================================================================
// tb_cmd_fsm_extra.v  --  PITFALL DEMO ONLY (Lab 4)
//----------------------------------------------------------------------------
// See tb_cmd_fsm_basic.v in this folder.  The point of this pair of
// testbenches is that the DUT ends up at two different instance paths,
// so vcover merge adds the bins instead of combining the hits.
//
// The recommended way is the single testbench tb/tb_cmd_fsm.v with the
// +TEST= plusarg.  This file is kept only for the demonstration.
//=============================================================================
`timescale 1ns / 1ps

module tb_cmd_fsm_extra;

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

        $display("=== TB_CMD_FSM_EXTRA : start ===");
        step(4'h3, 4'd6,  4'd3, 1'b1);
        step(4'h4, 4'd12, 4'd3, 1'b1);
        step(4'h5, 4'd2,  4'd7, 1'b1);
        step(4'h0, 4'd0,  4'd0, 1'b0);
        step(4'h0, 4'd5,  4'd5, 1'b1);
        step(4'h0, 4'd0,  4'd0, 1'b0);
        $display("=== TB_CMD_FSM_EXTRA : finished ===");
        $finish;
    end

endmodule
