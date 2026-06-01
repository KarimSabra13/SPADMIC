`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_stop_epoch_capture_async.sv
// Purpose  : STOP-edge capture of the raw slow Johnson epoch state.
// =============================================================================
// This is a held-bus snapshot.  The raw Johnson state is captured on STOP and
// held until the measurement fabric is cleared.  clk_sys samples the held value
// through mptdc_hit_capture_bridge before pd_clear_o asserts.
// =============================================================================
module mptdc_stop_epoch_capture_async
  import mptdc_pkg::*;
(
  input  wire                              rst_n,
  input  wire                              async_clr_i,
  input  wire                              stop_async_i,
  input  wire [SLOW_EPOCH_STAGES-1:0]      slow_epoch_johnson_i,
  output logic [SLOW_EPOCH_STAGES-1:0]     slow_epoch_johnson_stop_o
);

  always_ff @(posedge stop_async_i or negedge rst_n or posedge async_clr_i) begin
    if (!rst_n || async_clr_i)
      slow_epoch_johnson_stop_o <= '0;
    else
      slow_epoch_johnson_stop_o <= slow_epoch_johnson_i;
  end

endmodule

`default_nettype wire
