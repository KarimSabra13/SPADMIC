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

endinterface

`default_nettype wire
