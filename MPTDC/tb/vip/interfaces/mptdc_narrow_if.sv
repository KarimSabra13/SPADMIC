// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_narrow_if.sv
// Purpose : VIP interface for the 16-bit ready/valid narrow output stream.
// Author  : Karim Sabra
// Notes   : Provides a single shared view for ready driving, passive monitoring,
//           and scoreboard packet capture.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface mptdc_narrow_if #(parameter int NARROW_W = mptdc_pkg::NARROW_W)
(
  input wire clk_sys
);
  import mptdc_pkg::*;

  logic                narrow_ready;
  logic                narrow_valid;
  logic [NARROW_W-1:0] narrow_data;

`ifdef MPTDC_ENABLE_VIP_ASSERTS
  logic [NARROW_W-1:0] held_data_q;
  logic                held_valid_q;
  logic                held_stalled_q;

  always_ff @(posedge clk_sys) begin : narrow_assert_seq
    held_valid_q   <= narrow_valid;
    held_stalled_q <= narrow_valid && !narrow_ready;
    held_data_q    <= narrow_data;

    if (narrow_valid && narrow_ready && $isunknown(narrow_data))
      $error("[MPTDC_NARROW_IF] accepted narrow_data contains X/Z");

    if (held_valid_q && held_stalled_q && narrow_valid && !narrow_ready &&
        (narrow_data !== held_data_q)) begin
      $error("[MPTDC_NARROW_IF] narrow_data changed while valid && !ready");
    end
  end
`endif

endinterface

`default_nettype wire
