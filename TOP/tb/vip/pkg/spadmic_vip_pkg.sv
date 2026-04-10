// =============================================================================
// SPADMIC VIP — Forward Declarations, Typedefs, and Enums
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

package spadmic_vip_pkg;
  import mptdc_pkg::*;
  import spadmic_pkg::*;

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
    TXN_MON_PKT    = 6
  } spadmic_txn_kind_e;

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

  // ── Mailbox types ──────────────────────────────────────────────
  typedef mailbox #(int) mb_int_t;

  // ── Global configuration ───────────────────────────────────────
  localparam int CLK_PERIOD_PS   = 6250;    // 160 MHz
  localparam int REF_CLK_PERIOD  = 25000;   // 40 MHz
  localparam int I2C_HALF_PERIOD = 80;      // clk_sys cycles

  // Legal max_hits values
  localparam int LEGAL_MAX_HITS[4] = '{1, 5, 10, 15};

  // ── Forward class declarations ─────────────────────────────────
  typedef class spadmic_base_txn;
  typedef class spadmic_ctrl_txn;
  typedef class spadmic_tdc_event_txn;
  typedef class spadmic_pos_event_txn;
  typedef class spadmic_reset_txn;
  typedef class spadmic_bp_txn;
  typedef class spadmic_eot_txn;
  typedef class spadmic_env_cfg;
  typedef class spadmic_generator;
  typedef class spadmic_scoreboard;
  typedef class spadmic_mon_pkt_txn;
  typedef class spadmic_base_test;

endpackage

`default_nettype wire
