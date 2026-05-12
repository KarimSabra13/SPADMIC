`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.2 — Design Review Enhanced Vernier TDC
// File     : mptdc_watchdog.sv
// Purpose  : System-domain watchdog — raises a one-cycle force-clear pulse if
//            conversions stop completing within the programmed timeout window.
// Author   : Karim Sabra
// =============================================================================
// Review-era watchdog split:
//   - per-context timeout handling lives in mptdc_meas_ctrl (fast domain)
//   - this block keeps only the global completion watchdog, reset by conv_done_i
//   - wdt_global_timeout_i == 0 disables monitoring
// =============================================================================

module mptdc_watchdog
  import mptdc_pkg::*;
(
    input  wire                   clk_sys,
    input  wire                   rst_n,          // synchronous clk_sys reset, active-low

    // Conversion-done pulse (resets global watchdog)
    input  wire                   conv_done_i,

    // Timeout configuration (0 = disabled)
    input  wire [15:0]            wdt_global_timeout_i,

    // Force-reset output (single-cycle pulse)
    output logic                  wdt_force_reset_o,

    // Saturating trip counter
    output logic [7:0]            wdt_global_trip_cnt_o
);

  // =========================================================================
  // Global watchdog
  // =========================================================================
  logic [15:0] global_cnt;
  logic        global_trip;

  // global_trip self-clears the counter so each timeout produces one pulse and
  // the next watchdog window starts immediately.
  always_ff @(posedge clk_sys) begin
    if (!rst_n)
      global_cnt <= 16'd0;
    else if (conv_done_i || global_trip)
      global_cnt <= 16'd0;
    else if (wdt_global_timeout_i != 16'd0)
      global_cnt <= global_cnt + 16'd1;
  end

  assign global_trip = (wdt_global_timeout_i != 16'd0)
                     && (global_cnt == wdt_global_timeout_i);

  // Force-reset output — registered single-cycle pulse into the
  // frontend clear path.
  always_ff @(posedge clk_sys) begin
    if (!rst_n)
      wdt_force_reset_o <= 1'b0;
    else
      wdt_force_reset_o <= global_trip;
  end

  // Global trip counter (saturating at 255)
  always_ff @(posedge clk_sys) begin
    if (!rst_n)
      wdt_global_trip_cnt_o <= 8'd0;
    else if (global_trip && (wdt_global_trip_cnt_o != 8'hFF))
      wdt_global_trip_cnt_o <= wdt_global_trip_cnt_o + 8'd1;
  end

endmodule

`default_nettype wire
