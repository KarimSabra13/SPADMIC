`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC — Vernier Time-to-Digital Converter
// File     : mptdc_osc_model.sv
// Purpose  : Behavioural ring-oscillator model with optional jitter (sim only)
// Author   : Karim Sabra
// =============================================================================
// Simulation-only behavioural model of a multi-phase ring oscillator.  Each
// of the NE taps oscillates with a half-period of NE * TS_STEP, phase-
// shifted by k * TS_STEP for tap k.  This accurately models the propagation
// delay around the ring without requiring a gate-level netlist.
//
// Jitter support (controlled via plusargs):
//   +OSC_JITTER_SIGMA_PS=<int>  — Gaussian jitter standard deviation (ps)
//   +OSC_JITTER_BOUND_PS=<int>  — hard clamp on jitter magnitude (ps)
//
// Trim support: when trim_i = 1, the half-period is extended by
// NE * TRIM_DELTA_PS picoseconds (default 0 — no trim effect).
//
// Reset and enable:
//   - On reset or enable de-assertion, all taps return to a deterministic
//     state: phase[0] = 1, others = 0.
//   - On enable assertion, each tap waits k * TS_STEP before beginning
//     to oscillate, modelling the ring propagation startup.
//
// This module is NOT synthesisable — it uses #delays and blocking
// assignments within always blocks.  For synthesis, use mptdc_osc_stub.
// =============================================================================
module mptdc_osc_model #(
  parameter int  unsigned NE            = 8,
  parameter int  unsigned TS_STEP_PS    = 1000,
  parameter int  unsigned TRIM_DELTA_PS = mptdc_pkg::OSC_TRIM_DELTA_PS
)(
  input  wire          en,       // Enable oscillation (1 = running)
  input  wire          rst_n,    // Asynchronous active-low reset
  input  wire          trim_i,   // Trim bit: adds TRIM_DELTA_PS to tap delay
  output reg  [NE-1:0] phase,   // NE phase-shifted output taps
  output wire          phase0_guard_o,
  output wire          phase7d_probe_o
);

  // Half-period = NE * TS_STEP
  // Slow oscillator: 8 * 55 ps = 440 ps with the current behavioural model
  // Fast oscillator: 8 * 50 ps = 400 ps with the current behavioural model
  localparam time TS_STEP_T    = time'(TS_STEP_PS);
  localparam time HALF_PERIOD  = time'(NE * TS_STEP_PS);
  localparam time MIN_STEP_T   = 1ps;
  localparam int unsigned PHASE0_GUARD_PS      = 1;
  localparam int unsigned PHASE7_PROBE_DELAY_PS = 10;
  localparam int unsigned PHASE7_IDX           = (NE > 7) ? 7 : (NE - 1);

  // Jitter configuration (loaded from plusargs at time 0)
  integer osc_jitter_sigma_ps;
  integer osc_jitter_bound_ps;
  integer osc_jitter_seed;

  initial begin
    if ((TS_STEP_PS == 0) || (HALF_PERIOD <= 0)) begin
      $fatal(
        1,
        "[OSC_MODEL] Invalid TS_STEP/HALF_PERIOD (TS_STEP_PS=%0d HALF_PERIOD=%0t). Check timeprecision.",
        TS_STEP_PS,
        HALF_PERIOD
      );
    end
    if (!$value$plusargs("OSC_JITTER_SIGMA_PS=%d", osc_jitter_sigma_ps))
      osc_jitter_sigma_ps = 0;
    if (!$value$plusargs("OSC_JITTER_BOUND_PS=%d", osc_jitter_bound_ps))
      osc_jitter_bound_ps = 0;
    osc_jitter_seed = 32'h4D505444; // "MPTD"
    $display("[OSC_MODEL] NE=%0d TS_STEP_PS=%0d HALF_PERIOD=%0t", NE, TS_STEP_PS, HALF_PERIOD);
    $display("[OSC_MODEL] jitter_sigma_ps=%0d jitter_bound_ps=%0d",
             osc_jitter_sigma_ps, osc_jitter_bound_ps);
  end

  // Slow-boundary helper probes used by the synth-clean acquisition core.
  // phase0_guard_o is a 1 ps delayed copy of phase[0].  Sampling phase[0]
  // and phase0_guard_o on the STOP edge turns an ambiguous exact-boundary
  // coincidence into a deterministic one-bit carry.
  //
  // phase7d_probe_o remains a simulation helper probe used for reporting and
  // boundary diagnostics; it is no longer implemented inside the acquisition
  // core with an inline #delay.
  wire phase0_guard_w;
  wire phase7d_probe_w;
  assign #(PHASE0_GUARD_PS) phase0_guard_w = phase[0];
  assign #(PHASE7_PROBE_DELAY_PS) phase7d_probe_w = phase[PHASE7_IDX];
  assign phase0_guard_o = phase0_guard_w;
  assign phase7d_probe_o = phase7d_probe_w;

  // -----------------------------------------------------------------------
  // Per-tap oscillation process
  // Each tap k:
  //   1. Starts in a deterministic state (phase[0]=1, others=0).
  //   2. On enable, waits k * TS_STEP then oscillates at HALF_PERIOD.
  //   3. On disable or reset, returns to the deterministic state.
  // -----------------------------------------------------------------------
  genvar k;
  generate
    for (k = 0; k < NE; k++) begin : gen_phase

      // Deterministic initial state
      initial begin
        phase[k] = (k == 0) ? 1'b1 : 1'b0;
      end

      // Oscillation process (non-synthesisable #delay model)
      always begin
        @(posedge en or negedge rst_n);

        if (!rst_n) begin
          phase[k] = (k == 0) ? 1'b1 : 1'b0;
        end
        else begin
          // Initial phase offset: tap k starts k * TS_STEP after tap 0
          #(time'(k * TS_STEP_PS));

          // Oscillation loop: toggle every half-period while enabled
          while (en && rst_n) begin
            time step_delay;
            integer jitter_ps;
            step_delay = trim_i ? time'(NE * (TS_STEP_PS + TRIM_DELTA_PS))
                                 : HALF_PERIOD;
            if (osc_jitter_sigma_ps > 0) begin
              jitter_ps = $dist_normal(osc_jitter_seed, 0, osc_jitter_sigma_ps);
              if (osc_jitter_bound_ps > 0) begin
                if (jitter_ps > osc_jitter_bound_ps) jitter_ps = osc_jitter_bound_ps;
                if (jitter_ps < -osc_jitter_bound_ps) jitter_ps = -osc_jitter_bound_ps;
              end
              step_delay = (jitter_ps >= 0)
                  ? (HALF_PERIOD + time'(jitter_ps))
                  : ((HALF_PERIOD > time'(-jitter_ps)) ? (HALF_PERIOD - time'(-jitter_ps)) : MIN_STEP_T);
              if (step_delay < MIN_STEP_T) step_delay = MIN_STEP_T;
            end
            #(step_delay);
            phase[k] = ~phase[k];
          end

          // Clean stop: return to deterministic state
          phase[k] = (k == 0) ? 1'b1 : 1'b0;
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
