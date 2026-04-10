// =============================================================================
// SPADMIC VIP — Position Line Interface
// Carries 3×127-bit asynchronous line buses from the SPAD matrix.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_position_line_if;
  import spadmic_pkg::*;

  logic [SPADMIC_LINE_W-1:0] x_lines;
  logic [SPADMIC_LINE_W-1:0] y_lines;
  logic [SPADMIC_LINE_W-1:0] z_lines;

  // ── BFM tasks ─────────────────────────────────────────────────

  // Set all lines simultaneously (for static pattern tests)
  task automatic set_all(
    input logic [SPADMIC_LINE_W-1:0] x,
    input logic [SPADMIC_LINE_W-1:0] y,
    input logic [SPADMIC_LINE_W-1:0] z
  );
    x_lines = x;
    y_lines = y;
    z_lines = z;
  endtask

  // Set a single-cluster pattern on one axis (contiguous bits [lo:hi])
  task automatic set_single_cluster(
    input int axis,   // 0=X, 1=Y, 2=Z
    input int lo,
    input int hi
  );
    logic [SPADMIC_LINE_W-1:0] pattern;
    pattern = '0;
    for (int i = lo; i <= hi && i < SPADMIC_LINE_W; i++)
      pattern[i] = 1'b1;
    case (axis)
      0: x_lines = pattern;
      1: y_lines = pattern;
      2: z_lines = pattern;
    endcase
  endtask

  // Set a dual-cluster pattern on one axis
  task automatic set_dual_cluster(
    input int axis,
    input int lo0, input int hi0,
    input int lo1, input int hi1
  );
    logic [SPADMIC_LINE_W-1:0] pattern;
    pattern = '0;
    for (int i = lo0; i <= hi0 && i < SPADMIC_LINE_W; i++)
      pattern[i] = 1'b1;
    for (int i = lo1; i <= hi1 && i < SPADMIC_LINE_W; i++)
      pattern[i] = 1'b1;
    case (axis)
      0: x_lines = pattern;
      1: y_lines = pattern;
      2: z_lines = pattern;
    endcase
  endtask

  // Clear all lines
  task automatic clear_all();
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
  endtask

  // Inject a glitch (set then clear within very short time)
  task automatic inject_glitch(input int axis, input int bit_idx, input int glitch_ps);
    case (axis)
      0: begin x_lines[bit_idx] = 1'b1; #(glitch_ps); x_lines[bit_idx] = 1'b0; end
      1: begin y_lines[bit_idx] = 1'b1; #(glitch_ps); y_lines[bit_idx] = 1'b0; end
      2: begin z_lines[bit_idx] = 1'b1; #(glitch_ps); z_lines[bit_idx] = 1'b0; end
    endcase
  endtask

  // ── Initial state ─────────────────────────────────────────────
  initial begin
    x_lines = '0;
    y_lines = '0;
    z_lines = '0;
  end

endinterface

`default_nettype wire
