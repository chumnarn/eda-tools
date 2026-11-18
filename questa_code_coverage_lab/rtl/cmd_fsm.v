//=============================================================================
// cmd_fsm.v  --  Command Decoder + Response FSM
//----------------------------------------------------------------------------
// Lab DUT for "Using Code Coverage in QuestaSim"
//----------------------------------------------------------------------------
// The module is deliberately small but contains one of every construct that
// QuestaSim/ModelSim can measure with code coverage:
//
//   s  Statement    -> every assignment is a countable statement
//   b  Branch       -> if / else-if / else and every case item
//   c  Condition    -> boolean conditions (UDP) inside if statements
//   e  Expression   -> right-hand-side expressions of assignments
//   t  Toggle       -> 0->1 and 1->0 transitions of every signal
//   f  FSM          -> states and transitions of the state machine
//=============================================================================
`timescale 1ns / 1ps

module cmd_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,        // command enable
    input  wire [3:0] cmd,       // command code
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [3:0] result,
    output reg        zero,      // result is zero
    output reg        parity,
    output wire       done,
    output wire [1:0] state_o
);

    //---------------------------------------------------------------------
    // FSM state encoding
    //---------------------------------------------------------------------
    localparam [1:0] ST_IDLE = 2'd0,
                     ST_EXEC = 2'd1,
                     ST_WAIT = 2'd2,
                     ST_DONE = 2'd3;

    reg [1:0] state, next_state;

    //---------------------------------------------------------------------
    // Next-state logic (combinational)  -> FSM transition coverage
    //---------------------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE : if (en)      next_state = ST_EXEC;
            ST_EXEC : if (!en)     next_state = ST_WAIT;
            ST_WAIT : if (a == b)  next_state = ST_DONE;
            ST_DONE : if (!en)     next_state = ST_IDLE;
            default :               next_state = ST_IDLE;
        endcase
    end

    //---------------------------------------------------------------------
    // State register
    //---------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= ST_IDLE;
        else        state <= next_state;
    end

    assign state_o = state;
    assign done    = (state == ST_DONE);

    //---------------------------------------------------------------------
    // Command decoder
    //   -> statement coverage   (each assignment is one statement)
    //   -> branch coverage      (if / else + each case item)
    //   -> expression coverage  (a+b, a-b, a^b, concatenation)
    //---------------------------------------------------------------------
    always @(*) begin
        result = 4'h0;
        if (en) begin
            case (cmd)
                4'h1:    result = a + b;
                4'h2:    result = a - b;
                4'h3:    result = a ^ b;
                4'h4:    result = {a[1:0], b[1:0]};
                default: result = 4'h0;
            endcase
        end
    end

    //---------------------------------------------------------------------
    // Compare logic
    //   -> condition coverage (boolean UDPs of the if conditions)
    //---------------------------------------------------------------------
    always @(*) begin
        zero = 1'b0;
        if (en && (a > b))       zero = 1'b1;
        else if (en && (a == b)) zero = 1'b1;
        else                     zero = 1'b0;
    end

    //---------------------------------------------------------------------
    // Parity logic
    //   -> expression coverage with three sub-expressions
    //---------------------------------------------------------------------
    always @(*) begin
        parity = (a[0] ^ b[0]) & (a[1] | b[1]);
    end

endmodule
