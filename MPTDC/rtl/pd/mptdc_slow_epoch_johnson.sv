`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_slow_epoch_johnson.sv
// Purpose  : Timing-safe slow epoch source for STOP-side coarse timestamp.
// Author   : Karim Sabra
// =============================================================================
// The slow epoch is a 64-stage Johnson counter clocked by slow_phase[0].
// Compared with the previous binary counter + Gray encoder, this removes the
// oscillator-domain carry chain and keeps each transition to one changing bit,
// which is safer for asynchronous STOP-edge capture.
//
// The counter advances on every slow_phase[0] edge after reset/clear.  The slow
// RO_tune4 rstb/run control stops the clock outside an active window, so a
// synchronous enable/hold mux would add oscillator-domain delay.  enable_i is
// retained as a compatibility port for existing wrappers/tests.
// =============================================================================
module mptdc_slow_epoch_johnson
  import mptdc_pkg::*;
#(
  parameter int unsigned STAGES = SLOW_EPOCH_STAGES
)(
  input  wire                     clk_slow,
  input  wire                     rst_n,
  input  wire                     clear_window,
  input  wire                     enable_i,       // compatibility only; ignored by design
  output logic [STAGES-1:0]       johnson_o
);

  wire unused_enable = enable_i;

  always_ff @(posedge clk_slow or negedge rst_n or posedge clear_window) begin
    if (!rst_n || clear_window) begin
      johnson_o <= '0;
    end else begin
      johnson_o <= {johnson_o[STAGES-2:0], ~johnson_o[STAGES-1]};
    end
  end

  // synthesis translate_off
  logic [STAGES-1:0] prev_johnson_q;
  logic              prev_valid_q;
  int unsigned       diff_count;

  always_comb begin
    diff_count = 0;
    for (int i = 0; i < STAGES; i++) begin
      if (johnson_o[i] != prev_johnson_q[i])
        diff_count++;
    end
  end

  always_ff @(posedge clk_slow or negedge rst_n or posedge clear_window) begin
    if (!rst_n || clear_window) begin
      prev_johnson_q <= '0;
      prev_valid_q   <= 1'b0;
    end else begin
      if (prev_valid_q) begin
        assert (diff_count <= 1)
          else $error("mptdc_slow_epoch_johnson: more than one bit changed");
      end
      prev_johnson_q <= johnson_o;
      prev_valid_q   <= 1'b1;
    end
  end
  // synthesis translate_on

endmodule

`default_nettype wire
