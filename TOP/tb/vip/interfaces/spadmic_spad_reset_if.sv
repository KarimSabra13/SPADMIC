// =============================================================================
// SPADMIC VIP — SPAD Matrix Reset Observation Interface
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface spadmic_spad_reset_if (
  input wire clk_sys,
  input wire rst_n
);
  logic spad_matrix_rst;
  logic [15:0] expected_width_cycles;

  clocking mon_cb @(posedge clk_sys);
    input spad_matrix_rst, expected_width_cycles;
  endclocking
endinterface

`default_nettype wire
