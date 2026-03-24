`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.0 — Raw-Output Vernier TDC with Triple-Buffer
// File     : mptdc_pkg.sv
// Purpose  : Central parameter, type, and helper-function package
// Author   : Karim Sabra
// =============================================================================
// This package defines every shared constant, type, and utility function used
// across the MPTDC v2.0 design.  Key changes from v1:
//   - All on-chip calibration removed (ridge LUT, averaging, precision pipe)
//   - Triple-buffer snapshot contexts (N_CTX=3)
//   - Simplified output: raw features only
//   - 16-bit ready/valid output with configurable modes
//   - Per-context + global watchdog (no guard timer)
//   - Async-assert / sync-deassert reset
// =============================================================================
package mptdc_pkg;

  // =========================================================================
  // Physical constants and global dimensioning
  // =========================================================================
  parameter int unsigned CLK_SYS_HZ     = 160_000_000;
  parameter int unsigned NE              = 9;
  parameter int unsigned OSC_TS_SLOW_PS  = 55;
  parameter int unsigned OSC_TS_FAST_PS  = 50;

  // Phase-detector matrix: NE × NE
  localparam int unsigned PD_N = NE * NE;                 // 81
  localparam int unsigned PH_W = (NE <= 1) ? 1 : $clog2(NE);   // 4
  localparam int unsigned PD_W = (PD_N <= 1) ? 1 : $clog2(PD_N); // 7

  // System clock period
  localparam integer SYS_CLK_PS = 1_000_000_000_000 / CLK_SYS_HZ; // 6250 ps

  // Vernier parameters
  localparam integer DELTA_STEP_SIGNED = OSC_TS_SLOW_PS - OSC_TS_FAST_PS;
  localparam integer DELTA_STEP = (DELTA_STEP_SIGNED > 0) ? DELTA_STEP_SIGNED : 1; // 5 ps
  localparam int unsigned DELTA_LSB  = 2 * DELTA_STEP;     // 10 ps
  localparam int unsigned K_VERNIER  = OSC_TS_SLOW_PS / DELTA_STEP; // 11
  localparam integer OSC_TRIM_DELTA_PS = 0;  // Trim offset (reserved for silicon tuning)

  // =========================================================================
  // Counter widths and measurement window
  // =========================================================================
  parameter int unsigned NSLOW_W     = 7;
  parameter int unsigned NFAST_W     = 7;
  parameter int unsigned EVENT_SEQ_W = 4;  // Max 15 hits → 4 bits sufficient

  localparam int unsigned DLY_MAX_PS           = 32_000;
  localparam int unsigned SLOW_HALF_PERIOD_PS  = NE * OSC_TS_SLOW_PS;  // 495 ps
  localparam int unsigned FAST_HALF_PERIOD_PS  = NE * OSC_TS_FAST_PS;  // 450 ps

  localparam int unsigned NSLOW_CAPTURE_MAX =
      1 + ((DLY_MAX_PS + SLOW_HALF_PERIOD_PS - 1) / SLOW_HALF_PERIOD_PS);
  localparam int unsigned NFAST_CAPTURE_MAX =
      1 + ((DLY_MAX_PS + FAST_HALF_PERIOD_PS - 1) / FAST_HALF_PERIOD_PS);

  // =========================================================================
  // Hit limits and FIFO sizing
  // =========================================================================
  localparam int unsigned MAX_HITS          = 15;
  localparam int unsigned MAX_HITS_W        = $clog2(MAX_HITS + 1);  // 4 bits
  localparam int unsigned EVENT_IDX_W       = MAX_HITS_W;

  // FIFO sized for triple-buffer: 3 × (1 META + 15 HITs) = 48, round to 64
  parameter int unsigned FIFO_DEPTH         = 64;
  localparam int unsigned FIFO_LVL_W        = $clog2(FIFO_DEPTH + 1);

  // =========================================================================
  // Phase/PD index type aliases (must precede structs that use them)
  // =========================================================================
  typedef logic [PH_W-1:0] ph_idx_t;
  typedef logic [PD_W-1:0] pd_idx_t;

  // =========================================================================
  // Triple-buffer context parameters
  // =========================================================================
  localparam int unsigned N_CTX   = 3;
  localparam int unsigned CTX_W   = $clog2(N_CTX);  // 2 bits

  typedef logic [CTX_W-1:0] ctx_id_t;

  typedef enum logic [1:0] {
    CTX_FREE      = 2'd0,
    CTX_CAPTURING = 2'd1,
    CTX_DRAINING  = 2'd2
  } ctx_state_e;

  // =========================================================================
  // Operating modes
  // =========================================================================
  typedef enum logic [0:0] {
    MODE_MULTI_HIT = 1'b0,
    MODE_FIRST_HIT = 1'b1
  } mode_e;

  typedef enum logic [1:0] {
    OUT_MODE_RAW_FEATURES  = 2'd0,  // nslow, nfast, ns, nf, pd_idx, event_seq
    OUT_MODE_RAW_TIMESTAMP = 2'd1,  // nslow, nfast, t_raw_ps
    OUT_MODE_FULL          = 2'd2   // all features + timestamp
  } out_mode_e;

  typedef enum logic [0:0] {
    INPUT_SPAD = 1'b0,
    INPUT_CAL  = 1'b1
  } input_sel_e;

  // =========================================================================
  // FSM states
  // =========================================================================
  typedef enum logic [2:0] {
    ST_IDLE        = 2'd0,
    ST_ACTIVE      = 2'd1,
    ST_DRAIN_WAIT  = 2'd2
  } fsm_state_e;

  // =========================================================================
  // Conversion flags
  // =========================================================================
  typedef struct packed {
    logic overflow;
    logic closed_by_firsthit;
    logic closed_by_maxhits;
    logic closed_by_watchdog;
  } tdc_conv_flags_t;

  localparam int unsigned CONV_FLAGS_W = $bits(tdc_conv_flags_t);

  // =========================================================================
  // Internal acquisition record (pushed through async FIFO)
  // =========================================================================
  typedef struct packed {
    ph_idx_t                ns;
    ph_idx_t                nf;
    logic [NFAST_W-1:0]     nfast;
    logic [EVENT_SEQ_W-1:0] event_seq;
  } mptdc_hit_raw_t;

  typedef struct packed {
    logic [NSLOW_W-1:0]     nslow;
    logic [MAX_HITS_W-1:0]  hit_count;
    tdc_conv_flags_t        flags;
    logic                   phase0_snap;
    ctx_id_t                ctx_id;
  } mptdc_conv_meta_t;

  typedef enum logic [0:0] {
    ACQ_REC_HIT  = 1'b0,
    ACQ_REC_META = 1'b1
  } acq_rec_kind_e;

  typedef struct packed {
    acq_rec_kind_e     kind;
    mptdc_hit_raw_t    hit;
    mptdc_conv_meta_t  meta;
  } mptdc_acq_rec_t;

  localparam int unsigned ACQ_REC_W = $bits(mptdc_acq_rec_t);

  // =========================================================================
  // 16-bit output packet types
  // =========================================================================
  localparam int unsigned NARROW_W = 16;

  // Header word:  [15:14]=2'b10, [13:12]=ctx_id, [11]=phase0_snap,
  //               [10:7]=hit_count, [6:3]=flags, [2:1]=out_mode, [0]=rsvd
  // Hit words:    depend on out_mode (2-4 words per hit), bit[15]=0 always
  // EOC word:     [15:14]=2'b11, [13:0]=conv_id[13:0]

  // =========================================================================
  // CSR register addresses (minimal set)
  // =========================================================================
  localparam int unsigned CSR_ADDR_W = 6;
  localparam int unsigned CSR_DATA_W = 32;

  // Control registers (write)
  localparam logic [CSR_ADDR_W-1:0] CSR_CTRL        = 6'h00;  // conv_arm, fifo_clr, soft_rst
  localparam logic [CSR_ADDR_W-1:0] CSR_MODE        = 6'h04;  // mode_cfg, input_sel, out_mode
  localparam logic [CSR_ADDR_W-1:0] CSR_MAX_HITS    = 6'h08;  // max_hits[3:0]
  localparam logic [CSR_ADDR_W-1:0] CSR_WDT_CTX     = 6'h0C;  // per-context watchdog timeout
  localparam logic [CSR_ADDR_W-1:0] CSR_WDT_GLOBAL  = 6'h10;  // global watchdog timeout

  // Status registers (read)
  localparam logic [CSR_ADDR_W-1:0] CSR_STATUS      = 6'h20;  // ready, busy, ctx_states
  localparam logic [CSR_ADDR_W-1:0] CSR_HIT_COUNT   = 6'h24;  // last hit_count, flags
  localparam logic [CSR_ADDR_W-1:0] CSR_FIFO_STATUS = 6'h28;  // fifo_level, full, empty
  localparam logic [CSR_ADDR_W-1:0] CSR_WDT_STATUS  = 6'h2C;  // watchdog trip counts
  localparam logic [CSR_ADDR_W-1:0] CSR_CONV_COUNT  = 6'h30;  // total conversion counter
  localparam logic [CSR_ADDR_W-1:0] CSR_OVF_COUNT   = 6'h34;  // overflow counter

  // =========================================================================
  // Configuration struct
  // =========================================================================
  typedef struct packed {
    mode_e      mode_cfg;
    input_sel_e input_sel;
    out_mode_e  out_mode;
    logic [MAX_HITS_W-1:0] max_hits;
    logic [15:0] wdt_ctx_timeout;
    logic [15:0] wdt_global_timeout;
  } mptdc_cfg_t;

  // =========================================================================
  // Status struct (all packed — no unpacked arrays)
  // =========================================================================
  typedef struct packed {
    logic                      ready;
    logic                      busy;
    logic [N_CTX*2-1:0]        ctx_state_packed;  // 2 bits per context, packed
    logic [MAX_HITS_W-1:0]     last_hit_count;
    tdc_conv_flags_t           last_flags;
    logic [FIFO_LVL_W-1:0]    fifo_level;
    logic                      fifo_full;
    logic                      fifo_empty;
    logic [7:0]                wdt_ctx_trip_cnt;
    logic [7:0]                wdt_global_trip_cnt;
    logic [31:0]               conv_count;
    logic [15:0]               ovf_count;
  } mptdc_status_t;

  // =========================================================================
  // Snapshot context storage record (all packed — no unpacked arrays)
  // =========================================================================
  typedef struct packed {
    logic [PD_N-1:0]                     hit_level;
    logic [PD_N*NFAST_W-1:0]             nfast_hit_packed;  // PD_N × NFAST_W flattened
    logic [NSLOW_W-1:0]                  nslow_snap;
    logic [NFAST_W-1:0]                  nfast_snap;
    logic                                phase0_snap;
    logic [MAX_HITS_W-1:0]               hit_count;
    tdc_conv_flags_t                     flags;
  } mptdc_ctx_snapshot_t;

  // =========================================================================
  // Utility functions
  // =========================================================================

  // Flat PD cell index from slow/fast phase indices
  function automatic pd_idx_t pd_from_phases(
    input ph_idx_t ns_i,
    input ph_idx_t nf_i
  );
    pd_from_phases = pd_idx_t'(PD_W'(ns_i) * PD_W'(NE) + PD_W'(nf_i));
  endfunction

  // Raw Vernier time coefficient (used by tconv_reco)
  function automatic logic signed [31:0] vernier_coef(
    input logic [NSLOW_W-1:0] nslow_i,
    input logic [NFAST_W-1:0] nfast_i,
    input ph_idx_t            ns_i,
    input ph_idx_t            nf_i
  );
    automatic int signed coef;
    coef = (int'(nslow_i) - 1) * int'(K_VERNIER) * int'(NE)
         + (int'(nfast_i) - 1) * int'(NE)
         + int'(ns_i) * int'(K_VERNIER)
         - int'(nf_i) * (int'(K_VERNIER) - 1);
    vernier_coef = 32'(coef);
  endfunction

endpackage

`default_nettype wire
