// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_ref_stop_if.sv
// Purpose : VIP qualified 40 MHz reference-STOP timing model.
// Notes   : The macro-level use case treats the first qualified 40 MHz
//           reference edge after an accepted SPAD START as STOP.  The clock is
//           frequency-locked to clk_sys but intentionally phase-shifted per
//           seed to expose mesochronous edge alignments that ideal zero-skew
//           simulation would hide.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface mptdc_ref_stop_if;
  localparam time REF_CLK_PERIOD_PS = 25_000ps;  // 40 MHz
  localparam time REF_CLK_HALF_PS   = REF_CLK_PERIOD_PS / 2;
  localparam time SYS_CLK_PERIOD_PS = 6_250ps;   // 160 MHz

  logic ref_clk;
  time  phase_offset_ps;
  bit   started;

  initial begin
    ref_clk         = 1'b0;
    phase_offset_ps = 0ps;
    started         = 1'b0;
  end

  function automatic time phase_from_seed(input int unsigned seed);
    int unsigned mixed;
    begin
      mixed = seed ^ (seed >> 11) ^ 32'h9e37_79b9;
      return time'(mixed % int'(SYS_CLK_PERIOD_PS));
    end
  endfunction

  task automatic start(input time phase_offset_ps_i);
    if (started)
      return;
    phase_offset_ps = phase_offset_ps_i % SYS_CLK_PERIOD_PS;
    started = 1'b1;
    fork
      begin : ref_clock_thread
        #(phase_offset_ps);
        forever begin
          ref_clk = 1'b1;
          #(REF_CLK_HALF_PS);
          ref_clk = 1'b0;
          #(REF_CLK_HALF_PS);
        end
      end
    join_none
  endtask

  task automatic wait_next_edge(output time edge_time_ps);
    @(posedge ref_clk);
    edge_time_ps = $time;
  endtask

endinterface

`default_nettype wire
