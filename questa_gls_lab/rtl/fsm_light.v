//=====================================================================
// fsm_light.v -- LAB 08 : a small traffic-light FSM
//---------------------------------------------------------------------
// Three states : RED -> GREEN -> YELLOW -> RED
// The interesting part for gate level simulation : a design with an
// explicit state register, so the netlist contains real flip-flops
// and the state can be watched in the waveform.
//=====================================================================
`timescale 1ns/10ps

module fsm_light (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [1:0] state,
    output reg        red,
    output reg        green,
    output reg        yellow
);

  localparam ST_RED    = 2'd0;
  localparam ST_GREEN  = 2'd1;
  localparam ST_YELLOW = 2'd2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state  <= ST_RED;
      red    <= 1'b1;
      green  <= 1'b0;
      yellow <= 1'b0;
    end else begin
      case (state)
        ST_RED: begin
          red    <= 1'b0;
          green  <= 1'b1;
          yellow <= 1'b0;
          state  <= ST_GREEN;
        end
        ST_GREEN: begin
          red    <= 1'b0;
          green  <= 1'b0;
          yellow <= 1'b1;
          state  <= ST_YELLOW;
        end
        ST_YELLOW: begin
          red    <= 1'b1;
          green  <= 1'b0;
          yellow <= 1'b0;
          state  <= ST_RED;
        end
        default: begin
          state  <= ST_RED;
          red    <= 1'b1;
          green  <= 1'b0;
          yellow <= 1'b0;
        end
      endcase
    end
  end

endmodule
