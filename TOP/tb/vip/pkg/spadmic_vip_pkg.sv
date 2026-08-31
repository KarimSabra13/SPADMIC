// =============================================================================
// SPADMIC VIP — Master Package
// All VIP enums, typedefs, and class definitions live inside this package.
// Class files are `included so that Xcelium resolves all types in one unit.
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

package spadmic_vip_pkg;
  import mptdc_pkg::*;
  import spadmic_pkg::*;
  import spadmic_csr_map_pkg::*;

  // ── Backpressure modes ──────────────────────────────────────────
  typedef enum int unsigned {
    BP_ALWAYS_READY = 0,
    BP_RANDOM_50    = 1,
    BP_ALWAYS_STALL = 2
  } spadmic_bp_mode_e;

  // ── Transaction kinds ───────────────────────────────────────────
  typedef enum int unsigned {
    TXN_CTRL       = 0,
    TXN_TDC_EVENT  = 1,
    TXN_POS_EVENT  = 2,
    TXN_RESET      = 3,
    TXN_BP         = 4,
    TXN_EOT        = 5,
    TXN_MON_PKT    = 6,
    TXN_CORRELATED_EVENT = 7,
    TXN_SPAD_RESET = 8
  } spadmic_txn_kind_e;

  typedef enum int unsigned {
    MON_PKT_TDC         = 0,
    MON_PKT_POS_CLUSTER = 1,
    MON_PKT_POS_RAW     = 2
  } spadmic_mon_pkt_kind_e;

  // ── Control driver mode (I2C vs direct CSR) ─────────────────────
  typedef enum int unsigned {
    DRV_MODE_I2C        = 0,
    DRV_MODE_DIRECT_CSR = 1
  } spadmic_drv_mode_e;

  // ── Test mission profiles ──────────────────────────────────────
  typedef enum int unsigned {
    PROFILE_TDC_CHAR     = 0,
    PROFILE_POSITION     = 1,
    PROFILE_MODE_SWITCH  = 2,
    PROFILE_STRESS       = 3
  } spadmic_profile_e;

  typedef enum int unsigned {
    STIM_KIND_TDC        = 0,
    STIM_KIND_POSITION   = 1,
    STIM_KIND_CORRELATED = 2,
    STIM_KIND_RESET      = 3,
    STIM_KIND_BP         = 4,
    STIM_KIND_CSR        = 5
  } spadmic_stim_kind_e;

  typedef enum int unsigned {
    RANDOM_PHASE_TDC        = 0,
    RANDOM_PHASE_POSITION   = 1,
    RANDOM_PHASE_MODE_SWITCH = 2,
    RANDOM_PHASE_BP         = 3,
    RANDOM_PHASE_CORRELATED = 4
  } spadmic_random_phase_e;

  typedef enum int unsigned {
    RANDOM_INTENT_LEGAL = 0,
    RANDOM_INTENT_FAULT = 1
  } spadmic_random_intent_e;

  // ── Mailbox types ──────────────────────────────────────────────
  typedef mailbox #(int) mb_int_t;

  // ── Global configuration ───────────────────────────────────────
  localparam int CLK_PERIOD_PS   = 6250;    // 160 MHz
  localparam int REF_CLK_PERIOD  = 25000;   // 40 MHz
  localparam int I2C_HALF_PERIOD = 800;     // 100 kHz at 160 MHz clk_sys

  // Legal max_hits values
  localparam int LEGAL_MAX_HITS[4] = '{1, 5, 10, 15};

  // ══════════════════════════════════════════════════════════════════
  // Class includes (dependency order — base classes first)
  // ══════════════════════════════════════════════════════════════════

  // ── Configuration ───────────────────────────────────────────────
  `include "env/spadmic_env_cfg.sv"

  // ── Transactions ────────────────────────────────────────────────
  `include "txn/spadmic_base_txn.sv"
  `include "txn/spadmic_ctrl_txn.sv"
  `include "txn/spadmic_tdc_event_txn.sv"
  `include "txn/spadmic_pos_event_txn.sv"
  `include "txn/spadmic_correlated_event_txn.sv"
  `include "txn/spadmic_reset_txn.sv"
  `include "txn/spadmic_bp_txn.sv"
  `include "txn/spadmic_eot_txn.sv"
  `include "txn/spadmic_mon_pkt_txn.sv"
  `include "txn/spadmic_spad_reset_txn.sv"

  // ── Shared runtime state ────────────────────────────────────────
  `include "env/spadmic_runtime_state.sv"

  // ── Coverage ────────────────────────────────────────────────────
  `include "coverage/spadmic_stim_cov.sv"
  `include "coverage/spadmic_pkt_cov.sv"
  `include "coverage/spadmic_ctrl_cov.sv"
  `include "coverage/spadmic_fault_cov.sv"
  `include "coverage/spadmic_reset_cov.sv"

  // ── Agent / Drivers ─────────────────────────────────────────────
  `include "agent/spadmic_generator.sv"
  `include "agent/spadmic_csr_driver.sv"
  `include "agent/spadmic_i2c_driver.sv"
  `include "agent/spadmic_event_driver.sv"
  `include "agent/spadmic_pos_driver.sv"
  `include "agent/spadmic_bp_driver.sv"
  `include "agent/spadmic_driver.sv"

  // ── Monitors ────────────────────────────────────────────────────
  `include "monitor/spadmic_tx_monitor.sv"
  `include "monitor/spadmic_spad_reset_monitor.sv"
  `include "monitor/spadmic_csr_monitor.sv"
  `include "monitor/spadmic_ctrl_monitor.sv"

  // ── Reference Models + Scoreboard ───────────────────────────────
  `include "scoreboard/spadmic_tdc_ref_model.sv"
  `include "scoreboard/spadmic_pos_ref_model.sv"
  `include "scoreboard/spadmic_scoreboard.sv"

  // ── Environment ─────────────────────────────────────────────────
  `include "env/spadmic_env.sv"
  `include "env/spadmic_base_test.sv"

  // ── Test Library ────────────────────────────────────────────────
  `include "tests/spadmic_smoke_tdc.sv"
  `include "tests/spadmic_smoke_position.sv"
  `include "tests/spadmic_smoke_switching.sv"
  `include "tests/spadmic_tdc_modes.sv"
  `include "tests/spadmic_pos_clusters.sv"
  `include "tests/spadmic_ctrl_reject.sv"
  `include "tests/spadmic_reset_recovery.sv"
  `include "tests/spadmic_bp_stress.sv"
  `include "tests/spadmic_i2c_end_to_end.sv"
  `include "tests/spadmic_long_random.sv"
  `include "tests/spadmic_coverage_walk.sv"
  `include "tests/spadmic_stress_random.sv"
  `include "tests/spadmic_smoke_position_raw.sv"
  `include "tests/spadmic_spad_reset_modes.sv"

  // ── Test Factory (must be last — references all test classes) ───
  `include "env/spadmic_test_factory.sv"

endpackage

`default_nettype wire
