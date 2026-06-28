// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_matrix_or_tree.sv
// Purpose  : Physically reviewable OR tree for one matrix event direction.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

module spadmic_matrix_or_tree #(
  parameter int unsigned LINE_W = 64
) (
  input  logic [LINE_W-1:0] lines_i,
  output logic              event_o
);

  localparam int unsigned STAGE0_W = (LINE_W + 3) / 4;
  localparam int unsigned STAGE1_W = (STAGE0_W + 3) / 4;

  logic [STAGE0_W-1:0] stage0;
  logic [STAGE1_W-1:0] stage1;

  genvar g0;
  generate
    for (g0 = 0; g0 < STAGE0_W; g0++) begin : gen_stage0
      localparam int unsigned LO = g0 * 4;
      localparam int unsigned REM = (LINE_W > LO) ? (LINE_W - LO) : 0;
      localparam int unsigned W = (REM >= 4) ? 4 : REM;
      assign stage0[g0] = |lines_i[LO +: W];
    end
  endgenerate

  genvar g1;
  generate
    for (g1 = 0; g1 < STAGE1_W; g1++) begin : gen_stage1
      localparam int unsigned LO = g1 * 4;
      localparam int unsigned REM = (STAGE0_W > LO) ? (STAGE0_W - LO) : 0;
      localparam int unsigned W = (REM >= 4) ? 4 : REM;
      assign stage1[g1] = |stage0[LO +: W];
    end
  endgenerate

  assign event_o = |stage1;

endmodule

`default_nettype wire
