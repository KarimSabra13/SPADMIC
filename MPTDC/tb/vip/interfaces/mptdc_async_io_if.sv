// SPDX-FileCopyrightText: 2025 MPTDC Authors
// SPDX-License-Identifier: Apache-2.0
//
// =============================================================================
// Project : SPAD_MPTDC Verification Collateral
// File    : mptdc_async_io_if.sv
// Purpose : VIP interface for async reset and START/STOP/CAL pulse driving.
// Author  : Karim Sabra
// Notes   : Centralizes source-select-aware pulse tasks so VIP tests and the
//           module-level BFM share identical async stimulus semantics.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

interface mptdc_async_io_if;
  import mptdc_pkg::*;

  logic async_rst_n;
  logic start_spad;
  logic stop_spad;
  logic cal_start;
  logic cal_stop;

  // Clear all async stimulus lines without touching reset state.
  task automatic reset_pulses();
    start_spad = 1'b0;
    stop_spad  = 1'b0;
    cal_start  = 1'b0;
    cal_stop   = 1'b0;
  endtask

  // Drive the pad-facing async reset low for a programmable interval and
  // then leave time for the synchronized release path to settle.
  task automatic hard_reset(input time low_time_ps = 100_000,
                            input time settle_time_ps = 100_000);
    reset_pulses();
    async_rst_n = 1'b0;
    #low_time_ps;
    async_rst_n = 1'b1;
    #settle_time_ps;
  endtask

  // Inject a START/STOP pair on either the SPAD or CAL source while
  // keeping pulse width and inter-pulse delay explicit at the call site.
  task automatic inject_pair(input input_sel_e source_sel,
                             input time delay_ps,
                             input time pulse_width_ps = 1_000);
    case (source_sel)
      INPUT_CAL: begin
        cal_start = 1'b1;
        #pulse_width_ps;
        cal_start = 1'b0;
        #delay_ps;
        cal_stop = 1'b1;
        #pulse_width_ps;
        cal_stop = 1'b0;
      end
      default: begin
        start_spad = 1'b1;
        #pulse_width_ps;
        start_spad = 1'b0;
        #delay_ps;
        stop_spad = 1'b1;
        #pulse_width_ps;
        stop_spad = 1'b0;
      end
    endcase
  endtask

  task automatic drive_start(input input_sel_e source_sel,
                             input time pulse_width_ps = 1_000);
    case (source_sel)
      INPUT_CAL: begin
        cal_start = 1'b1;
        #pulse_width_ps;
        cal_start = 1'b0;
      end
      default: begin
        start_spad = 1'b1;
        #pulse_width_ps;
        start_spad = 1'b0;
      end
    endcase
  endtask

  task automatic drive_stop(input input_sel_e source_sel,
                            input time pulse_width_ps = 1_000);
    case (source_sel)
      INPUT_CAL: begin
        cal_stop = 1'b1;
        #pulse_width_ps;
        cal_stop = 1'b0;
      end
      default: begin
        stop_spad = 1'b1;
        #pulse_width_ps;
        stop_spad = 1'b0;
      end
    endcase
  endtask

  // Inject only the START side of a conversion to trigger watchdog-focused
  // scenarios without changing the rest of the source-selection contract.
  task automatic inject_start_only(input input_sel_e source_sel,
                                   input time pulse_width_ps = 1_000);
    drive_start(source_sel, pulse_width_ps);
  endtask

endinterface

`default_nettype wire
