//=====================================================================
// sr16.v -- LAB 08 : 16-bit shift register with parallel load
//---------------------------------------------------------------------
// sh : 0 = hold, 1 = shift right, 2 = shift left
// din : parallel data, loaded when ld = 1
// A wide design : 16 flip-flops -> the netlist shows how a register
// bank turns into real standard cells.
//=====================================================================
`timescale 1ns/10ps

module sr16 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ld,
    input  wire [1:0]  sh,
    input  wire [15:0] din,
    output reg  [15:0] qout
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      qout <= 16'd0;
    end else if (ld) begin
      qout <= din;
    end else begin
      case (sh)
        2'd1:    qout <= {1'b0, qout[15:1]};   // shift right
        2'd2:    qout <= {qout[14:0], 1'b0};   // shift left
        default: qout <= qout;                // hold
      endcase
    end
  end

endmodule
