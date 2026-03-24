`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.0 — Raw-Output Vernier TDC with Triple-Buffer
// File     : mptdc_watchdog.sv
// Purpose  : Dual-level watchdog — per-context + global timeout monitor
// =============================================================================
// Per-context watchdog: each non-FREE context counts clk_sys cycles; if any
// reaches wdt_ctx_timeout_i the module asserts wdt_force_close_o for one cycle
// and increments a saturating trip counter.
//
// Global watchdog: a single counter reset by conv_done_i; if it reaches
// wdt_global_timeout_i the module asserts wdt_force_reset_o for one cycle and
// increments a saturating global trip counter.
//
// Both levels are disabled when their respective timeout register is 0.
// =============================================================================

module mptdc_watchdog
  import mptdc_pkg::*;
(
    input  wire                   clk_sys,
    input  wire                   rst_n,

    // Context state vector
    input  ctx_state_e            ctx_state_i [N_CTX-1:0],

    // Conversion-done pulse (resets global watchdog)
    input  wire                   conv_done_i,

    // Timeout configuration (0 = disabled)
    input  wire [15:0]            wdt_ctx_timeout_i,
    input  wire [15:0]            wdt_global_timeout_i,

    // Force-close / force-reset outputs (single-cycle pulses)
    output logic                  wdt_force_close_o,
    output logic                  wdt_force_reset_o,

    // Saturating trip counters
    output logic [7:0]            wdt_ctx_trip_cnt_o,
    output logic [7:0]            wdt_global_trip_cnt_o
);

  // =========================================================================
  // Per-context watchdog
  // =========================================================================
  logic [15:0] ctx_cnt [N_CTX-1:0];
  logic        ctx_trip;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < N_CTX; i++)
        ctx_cnt[i] <= 16'd0;
    end else begin
      for (int i = 0; i < N_CTX; i++) begin
        if (ctx_state_i[i] == CTX_FREE)
          ctx_cnt[i] <= 16'd0;
        else
          ctx_cnt[i] <= ctx_cnt[i] + 16'd1;
      end
    end
  end

  // Trip when any context counter reaches the programmed threshold
  always_comb begin
    ctx_trip = 1'b0;
    if (wdt_ctx_timeout_i != 16'd0) begin
      for (int i = 0; i < N_CTX; i++) begin
        if (ctx_cnt[i] == wdt_ctx_timeout_i)
          ctx_trip = 1'b1;
      end
    end
  end

  // Force-close output — single-cycle pulse
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n)
      wdt_force_close_o <= 1'b0;
    else
      wdt_force_close_o <= ctx_trip;
  end

  // Per-context trip counter (saturating at 255)
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n)
      wdt_ctx_trip_cnt_o <= 8'd0;
    else if (ctx_trip && (wdt_ctx_trip_cnt_o != 8'hFF))
      wdt_ctx_trip_cnt_o <= wdt_ctx_trip_cnt_o + 8'd1;
  end

  // =========================================================================
  // Global watchdog
  // =========================================================================
  logic [15:0] global_cnt;
  logic        global_trip;

  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n)
      global_cnt <= 16'd0;
    else if (conv_done_i || global_trip)
      global_cnt <= 16'd0;
    else if (wdt_global_timeout_i != 16'd0)
      global_cnt <= global_cnt + 16'd1;
  end

  assign global_trip = (wdt_global_timeout_i != 16'd0)
                     && (global_cnt == wdt_global_timeout_i);

  // Force-reset output — single-cycle pulse
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n)
      wdt_force_reset_o <= 1'b0;
    else
      wdt_force_reset_o <= global_trip;
  end

  // Global trip counter (saturating at 255)
  always_ff @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n)
      wdt_global_trip_cnt_o <= 8'd0;
    else if (global_trip && (wdt_global_trip_cnt_o != 8'hFF))
      wdt_global_trip_cnt_o <= wdt_global_trip_cnt_o + 8'd1;
  end

endmodule

`default_nettype wire
