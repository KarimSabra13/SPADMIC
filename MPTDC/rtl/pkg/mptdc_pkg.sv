`timescale 1ps/1ps
`default_nettype none

// =============================================================================
// Project  : SPAD_MPTDC v2.7 — Fixed-Packet Vernier TDC
// File     : mptdc_pkg.sv
// Purpose  : Central parameter, type, and helper-function package
// Author   : Karim Sabra
// =============================================================================
// v2.4 changes (first-hit mode removal):
//   - Removed MODE_FIRST_HIT / mode_e enum — single multi-hit operating mode
//   - max_hits=1 preserves fast close (OR-reduction) internally
//   - closed_by_firsthit flag renamed to closed_by_fast_maxhit
//   - mode_cfg removed from mptdc_cfg_t; CSR_MODE[0] is now reserved
//
// Current measurement-control split:
//   - Oscillator/PD/counter fabric remains the Vernier measurement exception.
//   - mptdc_meas_ctrl and mptdc_context_bank run on clk_sys.
//   - A static-bus bridge samples the held measurement image before context
//     commit and before PD/counter clear.
//   - Overflow flag removed from conv_flags (was misused as hit-saturation)
//   - slow_boundary_inc added to meta/snapshot for offline calibration
//   - N_CTX = 2 (hardwired double-buffer, not parameterizable)
//   - Readout: sync FIFO in sys_clk domain (no async FIFO)
// =============================================================================
package mptdc_pkg;

  // =========================================================================
  // Physical constants and global dimensioning
  // =========================================================================
  parameter int unsigned CLK_SYS_HZ     = 160_000_000;
  parameter int unsigned NE              = 8;
  parameter int unsigned OSC_TS_SLOW_PS  = 55;
  parameter int unsigned OSC_TS_FAST_PS  = 50;

  // Phase-detector matrix: NE x NE.  The active macro is intentionally fixed at
  // 8 taps per ring.  Keep NE as the single source of truth for widths and
  // loops, but do not treat larger NE values as a supported tapeout target.
  localparam int unsigned PD_N = NE * NE;
  localparam int unsigned PH_W = (NE <= 1) ? 1 : $clog2(NE);
  localparam int unsigned PD_W = (PD_N <= 1) ? 1 : $clog2(PD_N);

  // System clock period
  localparam longint unsigned SYS_CLK_PS = 64'd1_000_000_000_000 / CLK_SYS_HZ; // 6250 ps

  // Vernier parameters
  localparam integer DELTA_STEP_SIGNED = OSC_TS_SLOW_PS - OSC_TS_FAST_PS;
  localparam integer DELTA_STEP = (DELTA_STEP_SIGNED > 0) ? DELTA_STEP_SIGNED : 1; // 5 ps
  localparam int unsigned DELTA_LSB  = 2 * DELTA_STEP;     // 10 ps
  localparam int unsigned K_VERNIER  = OSC_TS_SLOW_PS / DELTA_STEP; // 11
  localparam integer OSC_TRIM_DELTA_PS = 0;  // Trim offset (reserved for silicon tuning)
  // Raw timestamp reconstruction keeps the original Vernier topology but adds
  // fixed geometry-origin corrections for the live counter semantics:
  //   - STOP-side nslow snapshot is two slow counts behind the historical
  //     one-based loop index.
  //   - Per-hit nfast capture is one fast count behind the same loop index.
  //   - slow_boundary_inc contributes one extra coarse slow revolution.
  //   - A fixed residual 25-coef term (= 250 ps) recenters the raw estimator.
  localparam int signed VERNIER_NSLOW_ORIGIN_BIAS = 2;
  localparam int signed VERNIER_NFAST_ORIGIN_BIAS = 1;
  localparam int signed VERNIER_COEF_BIAS         = 25;

  // =========================================================================
  // Counter widths and measurement window
  // =========================================================================
  parameter int unsigned NSLOW_W     = 7;
  parameter int unsigned NFAST_W     = 7;
  parameter int unsigned EVENT_SEQ_W = 4;  // Max 15 hits → 4 bits sufficient

  localparam int unsigned DLY_MAX_PS           = 32_000;
  localparam int unsigned SLOW_HALF_PERIOD_PS  = NE * OSC_TS_SLOW_PS;  // 440 ps @ 8 taps, 55 ps/tap
  localparam int unsigned FAST_HALF_PERIOD_PS  = NE * OSC_TS_FAST_PS;  // 400 ps @ 8 taps, 50 ps/tap

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

  // FIFO sized for double-buffer: 2 × (1 META + 15 HITs) = 32, use 64 for margin
  parameter int unsigned FIFO_DEPTH         = 64;
  localparam int unsigned FIFO_LVL_W        = $clog2(FIFO_DEPTH + 1);

  // =========================================================================
  // Phase/PD index type aliases (must precede structs that use them)
  // =========================================================================
  typedef logic [PH_W-1:0] ph_idx_t;
  typedef logic [PD_W-1:0] pd_idx_t;

  // =========================================================================
  // Double-buffer context parameters.  The retained context bank is fixed at
  // two entries: one context may drain while the frontend protects the next
  // accepted conversion under backpressure.
  // =========================================================================
  localparam int unsigned N_CTX   = 2;
  localparam int unsigned CTX_W   = (N_CTX <= 1) ? 1 : $clog2(N_CTX);  // 1 bit
  localparam int unsigned PACKET_CTX_W = 2;  // frozen 16-bit header allocation

  typedef logic [CTX_W-1:0] ctx_id_t;

  // STOP-edge slow-phase discriminator exported in the fixed feature packet.
  // These three slow-ring phase bits reduce early-delay raw aliases while
  // preserving the frozen 16-bit packet word count.  They are phase metadata,
  // not a replacement for a correct STOP-side coarse count.
  localparam int unsigned STOP_PHASE_DISC_W   = 3;
  localparam int unsigned STOP_PHASE_DISC_LSB = 3;
  localparam int unsigned STOP_PHASE_DISC_MSB =
      STOP_PHASE_DISC_LSB + STOP_PHASE_DISC_W - 1;
  typedef logic [STOP_PHASE_DISC_W-1:0] stop_phase_disc_t;

  typedef enum logic [1:0] {
    CTX_FREE      = 2'd0,
    CTX_CAPTURING = 2'd1,
    CTX_DRAINING  = 2'd2
  } ctx_state_e;

  // =========================================================================
  // Operating modes
  // =========================================================================
  // v2.4: single operating mode — multi-hit with configurable max_hits.
  // max_hits=1 triggers an internal fast close path (OR-reduction) for
  // minimum-latency single-hit operation.  The former MODE_FIRST_HIT is
  // removed; MODE_MULTI_HIT is kept as a compatibility constant.
  localparam logic [0:0] MODE_MULTI_HIT = 1'b0;

  typedef enum logic [1:0] {
    OUT_MODE_RAW_FEATURES  = 2'd0,  // single retained packet format
    OUT_MODE_RAW_TIMESTAMP = 2'd1,  // legacy CSR code, ignored by RTL
    OUT_MODE_FULL          = 2'd2   // legacy CSR code, ignored by RTL
  } out_mode_e;

  typedef enum logic [0:0] {
    INPUT_SPAD = 1'b0,
    INPUT_CAL  = 1'b1
  } input_sel_e;

  // =========================================================================
  // Measurement FSM states (clk_sys domain — mptdc_meas_ctrl)
  // Fast-clear sequence: IDLE → MEASURE → SNAPSHOT → COUNT → CLEAR → IDLE.
  // SNAPSHOT samples the static PD/counter measurement fabric into clk_sys,
  // COUNT commits the raw image with final metadata and clears frontend
  // ownership, and CLEAR clears the measurement fabric after the raw image is
  // protected. EVAL/CAPTURE enum values are retained for compatibility only.
  // =========================================================================
  typedef enum logic [2:0] {
    ST_M_IDLE      = 3'd0,
    ST_M_MEASURE   = 3'd1,
    ST_M_SNAPSHOT  = 3'd2,
    ST_M_CAPTURE   = 3'd3,
    ST_M_STOP_OSC  = 3'd4,
    ST_M_CLEAR     = 3'd5,
    ST_M_EVAL      = 3'd6,
    ST_M_COUNT     = 3'd7
  } meas_state_e;

  // =========================================================================
  // Drain FSM states (sys_clk domain — mptdc_drain_ctrl)
  // =========================================================================
  typedef enum logic [1:0] {
    ST_D_IDLE = 2'd0,
    ST_D_META = 2'd1,
    ST_D_SCAN = 2'd2,
    ST_D_EOC  = 2'd3
  } drain_state_e;

  // =========================================================================
  // Conversion flags (4 bits, packed MSB-first)
  // Bit 3: reserved (was 'overflow' in v2.1 — misused as hit-saturation)
  // Bit 2: closed_by_fast_maxhit  (v2.4: fast OR-reduction close when max_hits=1)
  // Bit 1: closed_by_maxhits     (pipelined hit-count saturation close)
  // Bit 0: closed_by_watchdog
  // Context-allocation overflow is tracked separately in ovf_count_r.
  // =========================================================================
  typedef struct packed {
    logic reserved;
    logic closed_by_fast_maxhit;
    logic closed_by_maxhits;
    logic closed_by_watchdog;
  } tdc_conv_flags_t;

  localparam int unsigned CONV_FLAGS_W = $bits(tdc_conv_flags_t);

  // =========================================================================
  // Internal acquisition record (pushed through sync FIFO in sys_clk)
  // =========================================================================
  typedef struct packed {
    ph_idx_t                ns;
    ph_idx_t                nf;
    logic [NFAST_W-1:0]     nfast;
    logic [EVENT_SEQ_W-1:0] event_seq;
  } mptdc_hit_raw_t;

  typedef struct packed {
    logic [NSLOW_W-1:0]     nslow;          // STOP-side slow snapshot
    logic [NFAST_W-1:0]     nfast;          // fast counter at CAPTURE
    logic [NFAST_W-1:0]     nfast_stop;     // fast counter at STOP edge
    logic [MAX_HITS_W-1:0]  hit_count;
    tdc_conv_flags_t        flags;
    logic                   phase0_snap;
    stop_phase_disc_t       stop_slow_phase_disc;
    logic                   slow_boundary_inc;  // phase-0 boundary correction carry
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
  //               [10:7]=hit_count, [6:3]=flags,
  //               [2]=slow_boundary_inc, [1:0]=reserved/read-zero
  // Hit words:    fixed two-word format, bit[15]=0 always.
  //               Hit W1[2:0] carries stop_slow_phase_disc.
  // EOC word:     [15:14]=2'b11, [13:0]=conv_id[13:0]

  // =========================================================================
  // CSR register addresses (minimal set)
  // =========================================================================
  localparam int unsigned CSR_ADDR_W = 6;
  localparam int unsigned CSR_DATA_W = 32;

  // Control registers (write)
  localparam logic [CSR_ADDR_W-1:0] CSR_CTRL        = 6'h00;  // conv_arm, fifo_clr, soft_rst
  localparam logic [CSR_ADDR_W-1:0] CSR_MODE        = 6'h04;  // reserved[0], input_sel, reserved[3:2]
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
  // v2.4: mode_cfg removed — single multi-hit operating mode.
  // v2.7: output packet mode is hardwired; cfg.out_mode is retained only as a
  //       read-zero compatibility field for wrappers that still carry the type.
  // =========================================================================
  typedef struct packed {
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
    logic [1:0]                drain_state;        // drain_state_e (v2.1)
    logic [MAX_HITS_W-1:0]     last_hit_count;
    tdc_conv_flags_t           last_flags;
    logic [FIFO_LVL_W-1:0]    fifo_level;
    logic                      fifo_full;
    logic                      fifo_empty;
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
    logic [NSLOW_W-1:0]                  nslow_snap;        // STOP-side slow snapshot
    logic [NFAST_W-1:0]                  nfast_snap;        // global fast counter at CAPTURE
    logic [NFAST_W-1:0]                  nfast_stop;        // fast counter at STOP edge
    logic                                phase0_snap;
    stop_phase_disc_t                    stop_slow_phase_disc;
    logic                                slow_boundary_inc; // phase-0 boundary carry
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

  // Raw Vernier time coefficient.
  //
  // This preserves the original dependence on nslow/nfast/ns/nf, K_VERNIER,
  // and DELTA_LSB.  The only additions are fixed origin corrections plus the
  // source-side slow boundary carry.
  function automatic logic signed [31:0] vernier_coef(
    input logic [NSLOW_W-1:0] nslow_i,
    input logic [NFAST_W-1:0] nfast_i,
    input ph_idx_t            ns_i,
    input ph_idx_t            nf_i,
    input logic               slow_boundary_inc_i
  );
    automatic int signed coef;
    coef = (int'(nslow_i)
            + int'(VERNIER_NSLOW_ORIGIN_BIAS)
            + int'(slow_boundary_inc_i)
            - 1) * int'(K_VERNIER) * int'(NE)
         + (int'(nfast_i) + int'(VERNIER_NFAST_ORIGIN_BIAS) - 1) * int'(NE)
         + int'(ns_i) * int'(K_VERNIER)
         - int'(nf_i) * (int'(K_VERNIER) - 1)
         + int'(VERNIER_COEF_BIAS);
    vernier_coef = 32'(coef);
  endfunction

  function automatic logic signed [31:0] vernier_tconv_ps(
    input logic [NSLOW_W-1:0] nslow_i,
    input logic [NFAST_W-1:0] nfast_i,
    input ph_idx_t            ns_i,
    input ph_idx_t            nf_i,
    input logic               slow_boundary_inc_i
  );
    vernier_tconv_ps = 32'(vernier_coef(nslow_i, nfast_i, ns_i, nf_i,
                                        slow_boundary_inc_i)
                           * int'(DELTA_LSB));
  endfunction

endpackage

`default_nettype wire
