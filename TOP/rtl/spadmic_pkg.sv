// =============================================================================
// Project  : SPADMIC Top-Level Integration
// File     : spadmic_pkg.sv
// Purpose  : Shared constants, CSR addresses, packet helpers, and position-side
//            cluster types for TOP and I2C integration logic.
// Author   : Karim Sabra
// =============================================================================
`timescale 1ps/1ps
`default_nettype none

package spadmic_pkg;
  import mptdc_pkg::*;

  // Top-level dimensions and control-plane widths.
  localparam int unsigned SPADMIC_AXIS_COUNT  = 3;
  localparam int unsigned SPADMIC_AXIS_ID_W   = 2;
  localparam int unsigned SPADMIC_SRC_COUNT   = 4;
  localparam int unsigned SPADMIC_SRC_MASK_W  = SPADMIC_SRC_COUNT;
  localparam int unsigned SPADMIC_LINE_W      = 64;
  localparam int unsigned SPADMIC_LINE_IDX_W  = $clog2(SPADMIC_LINE_W);
  localparam int unsigned SPADMIC_LINE_COUNT_W = $clog2(SPADMIC_LINE_W + 1);
  localparam int unsigned SPADMIC_MATRIX_COLUMN_COUNT = 44;
  localparam int unsigned SPADMIC_MATRIX_COLUMN_IDX_W = $clog2(SPADMIC_MATRIX_COLUMN_COUNT);
  localparam int unsigned SPADMIC_MATRIX_CFG_BITS_PER_COLUMN = 64;
  localparam int unsigned SPADMIC_DDR16_PHY_W = 16;
  localparam int unsigned SPADMIC_DDRS2_LANE_W = 19;
  localparam int unsigned SPADMIC_DDRS2_DATA_LANES = 16;
  localparam int unsigned SPADMIC_DDRS2_VALID_LANE = 16;
  localparam int unsigned SPADMIC_DDRS2_FWD_CLK_LANE = 17;
  localparam int unsigned SPADMIC_DDRS2_SPARE_LANE = 18;
  localparam int unsigned SPADMIC_CSR_ADDR_W  = 16;
  localparam int unsigned SPADMIC_CSR_DATA_W  = mptdc_pkg::CSR_DATA_W;
  localparam int unsigned SPADMIC_EVENT_ID_W  = 14;
  localparam int unsigned SPADMIC_TX_PHY_W    = 8;
  localparam logic [6:0] SPADMIC_I2C_ADDR     = 7'h42;
  localparam int unsigned SPADMIC_POS_PKT_WORDS = 8;
  localparam int unsigned SPADMIC_POS_COMPACT_MIN_PKT_WORDS = 3;
  localparam int unsigned SPADMIC_POS_SCAN_LATENCY_CYCLES = 5;
  localparam int unsigned SPADMIC_POS_QUEUE_DEPTH = 16;
  localparam int unsigned SPADMIC_EVENT_BUNDLE_DEPTH = 16;
  localparam int unsigned SPADMIC_POS_RAW_WORDS_PER_AXIS = (SPADMIC_LINE_W + NARROW_W - 1) / NARROW_W;
  localparam int unsigned SPADMIC_POS_RAW_PAYLOAD_WORDS = SPADMIC_AXIS_COUNT * SPADMIC_POS_RAW_WORDS_PER_AXIS;
  localparam int unsigned SPADMIC_POS_RAW_PKT_WORDS = 1 + SPADMIC_POS_RAW_PAYLOAD_WORDS + 1;
  localparam int unsigned SPADMIC_MAX_TDC_PACKET_WORDS = 2 + (mptdc_pkg::MAX_HITS * 2);
  localparam int unsigned SPADMIC_MAX_CONCURRENT_ARB_BURST_WORDS =
      (SPADMIC_AXIS_COUNT * SPADMIC_MAX_TDC_PACKET_WORDS) + SPADMIC_POS_RAW_PKT_WORDS;
  localparam int unsigned SPADMIC_OUTPUT_FIFO_DEPTH = 256;
  localparam int unsigned SPADMIC_OUTPUT_FIFO_LEVEL_W = $clog2(SPADMIC_OUTPUT_FIFO_DEPTH + 1);
  localparam int unsigned SPADMIC_MAX_EVENT_BUNDLE_WORDS = 128;
  localparam int unsigned SPADMIC_OUTPUT_FIFO_RESERVE_ENTRIES =
      SPADMIC_MAX_EVENT_BUNDLE_WORDS + 1; // include ordered flush marker

  typedef enum logic [SPADMIC_AXIS_ID_W-1:0] {
    TDC_ID_X = 2'd0,
    TDC_ID_Y = 2'd1,
    TDC_ID_Z = 2'd2,
    SPADMIC_SRC_POSITION = 2'd3
  } spadmic_source_id_e;

  typedef spadmic_source_id_e spadmic_tdc_id_e;

  typedef enum logic {
    SPADMIC_TX_TDC      = 1'b0,
    SPADMIC_TX_POSITION = 1'b1
  } spadmic_tx_sel_e;

  typedef enum logic [1:0] {
    SPADMIC_EXPORT_TDC_ONLY      = 2'd0,
    SPADMIC_EXPORT_POSITION_ONLY = 2'd1,
    SPADMIC_EXPORT_BOTH_ACTIVE   = 2'd2
  } spadmic_export_mode_e;

  typedef enum logic [2:0] {
    SPADMIC_MODE_DISABLED      = 3'd0,
    SPADMIC_MODE_TDC_ONLY      = 3'd1,
    SPADMIC_MODE_POSITION_ONLY = 3'd2,
    SPADMIC_MODE_BOTH          = 3'd3,
    SPADMIC_MODE_CALIBRATION   = 3'd4
  } spadmic_operating_mode_e;

  typedef enum logic {
    SPADMIC_POS_MODE_CLUSTER = 1'b0,
    SPADMIC_POS_MODE_RAW     = 1'b1
  } spadmic_pos_mode_e;

  typedef enum logic [1:0] {
    SPADMIC_SPAD_RST_MANUAL_ONLY    = 2'd0,
    SPADMIC_SPAD_RST_EVENT_DEFERRED = 2'd1,
    SPADMIC_SPAD_RST_PERIODIC       = 2'd2
  } spadmic_spad_reset_mode_e;

  localparam logic [3:0] SPADMIC_REGION_GLOBAL   = 4'h0;
  localparam logic [3:0] SPADMIC_REGION_TDC_X    = 4'h1;
  localparam logic [3:0] SPADMIC_REGION_TDC_Y    = 4'h2;
  localparam logic [3:0] SPADMIC_REGION_TDC_Z    = 4'h3;
  localparam logic [3:0] SPADMIC_REGION_POSITION = 4'h4;
  localparam logic [3:0] SPADMIC_REGION_MATRIX_EVENT = 4'h5;
  localparam logic [3:0] SPADMIC_REGION_MATRIX_CFG   = 4'h6;
  localparam logic [3:0] SPADMIC_REGION_TX_DEBUG     = 4'h7;

  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_ID      = 16'h0000;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_VERSION = 16'h0004;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_CTRL    = 16'h0008;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_STATUS  = 16'h000C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_FAULT   = 16'h0010;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_FAULT_COUNT = 16'h0014;

  // Matrix-top final CSR16 map. Legacy top modules that still use the older
  // local 0x0xx/0x1xx addresses see these values zero-extended.
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MTOP_CTRL_REQUEST = 16'h0008;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MTOP_CTRL_ACTIVE  = 16'h000C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MTOP_STATUS       = 16'h0010;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MTOP_FAULT        = 16'h0014;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MTOP_FAULT_COUNT  = 16'h0018;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_SHARED_TDC_MAX_HITS = 16'h0020;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_SHARED_TDC_RO_SLOW  = 16'h0024;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_SHARED_TDC_RO_FAST  = 16'h0028;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_SHARED_TDC_CTRL     = 16'h002C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_CALIB_AXIS_MASK     = 16'h0030;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_PLL_CTRL            = 16'h0034;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_PLL_STATUS          = 16'h0038;

  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POSITION_MODE       = 16'h4000;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_CTRL        = 16'h4000;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_GAP_CFG     = 16'h4004;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_FILTER_CFG  = 16'h4008;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_RESET_CFG   = 16'h400C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_STATUS      = 16'h4020;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_EVENT_COUNT = 16'h4024;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_FAULT_STATUS = 16'h4028;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_DROP_COUNT   = 16'h402C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_REJECT_COUNT = 16'h4030;

  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_EVENT_STATUS = 16'h5000;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_SNAPSHOT_CFG = 16'h5004;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_RESET_CTRL   = 16'h5008;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_RESET_STATUS = 16'h500C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_R_SNAP_LO    = 16'h5010;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_R_SNAP_HI    = 16'h5014;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_Y_SNAP_LO    = 16'h5018;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_Y_SNAP_HI    = 16'h501C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_B_SNAP_LO    = 16'h5020;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_B_SNAP_HI    = 16'h5024;

  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_CMD      = 16'h6000;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_STATUS   = 16'h6004;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_COL      = 16'h6008;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_WDATA_LO = 16'h600C;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_WDATA_HI = 16'h6010;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_RDATA_LO = 16'h6014;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_RDATA_HI = 16'h6018;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_MATRIX_CFG_LAST_ERROR = 16'h601C;

  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_TX_STATUS = 16'h7000;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_OUTPUT_FIFO_STATUS = 16'h7004;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_OUTPUT_FIFO_WATERMARKS = 16'h7008;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_SLVS_GPIO_CTRL = 16'h7010;

  // Position-side cluster summaries keep only the highest-priority two clusters
  // per axis. Additional qualifying clusters set overflow.
  typedef struct packed {
    logic                             valid;
    logic [SPADMIC_LINE_IDX_W-1:0]    lo;
    logic [SPADMIC_LINE_IDX_W-1:0]    hi;
  } spadmic_cluster_t;

  localparam int unsigned SPADMIC_POS_CLUSTER_SLOT_COUNT = SPADMIC_AXIS_COUNT * 2;
  typedef logic [SPADMIC_POS_CLUSTER_SLOT_COUNT-1:0] spadmic_pos_cluster_slot_mask_t;

  typedef struct packed {
    logic                 empty;
    logic                 overflow;
    logic [1:0]           cluster_count;
    spadmic_cluster_t     cluster0;
    spadmic_cluster_t     cluster1;
  } spadmic_axis_clusters_t;

  typedef struct packed {
    spadmic_pos_mode_e       mode;
    logic                     compact_cluster;
    logic [2:0]               non_empty_mask;
    logic [2:0]               multi_cluster_mask;
    logic                     overflow_any;
    spadmic_pos_cluster_slot_mask_t cluster_slot_mask;
    logic [2:0]               compact_cluster_words;
    spadmic_axis_clusters_t   x_clusters;
    spadmic_axis_clusters_t   y_clusters;
    spadmic_axis_clusters_t   z_clusters;
    logic [SPADMIC_LINE_W-1:0] x_raw_lines;
    logic [SPADMIC_LINE_W-1:0] y_raw_lines;
    logic [SPADMIC_LINE_W-1:0] z_raw_lines;
  } spadmic_pos_frame_t;

  function automatic logic is_tdc_header(input logic [NARROW_W-1:0] word);
    return (word[15:13] == 3'b100);
  endfunction

  function automatic logic is_spadmic_subheader(input logic [NARROW_W-1:0] word);
    return (word[15:13] == 3'b101);
  endfunction

  function automatic logic is_spadmic_pos_raw_header(input logic [NARROW_W-1:0] word);
    return (word[15:13] == 3'b100) && (word[5:4] == 2'b10) && (word[3:0] == 4'h2);
  endfunction

  function automatic logic is_spadmic_pos_cluster_header(input logic [NARROW_W-1:0] word);
    return (word[15:14] == 2'b01);
  endfunction

  function automatic logic is_spadmic_pos_compact_header(input logic [NARROW_W-1:0] word);
    return is_spadmic_pos_cluster_header(word) && word[9];
  endfunction

  function automatic logic is_tdc_eoc(input logic [NARROW_W-1:0] word);
    return (word[15:14] == 2'b11);
  endfunction

  function automatic spadmic_tdc_id_e tdc_header_source_id(
    input logic [NARROW_W-1:0] word
  );
    return spadmic_tdc_id_e'(word[1:0]);
  endfunction

  function automatic logic [NARROW_W-1:0] patch_tdc_id_into_header(
    input logic [NARROW_W-1:0]     word,
    input spadmic_tdc_id_e         tdc_id
  );
    logic [NARROW_W-1:0] patched;
    patched = word;
    if (is_tdc_header(word)) begin
      patched[1:0] = tdc_id;
    end
    return patched;
  endfunction

  function automatic logic [SPADMIC_LINE_IDX_W:0] spadmic_cluster_span(
    input spadmic_cluster_t cluster
  );
    logic [SPADMIC_LINE_IDX_W:0] lo_ext;
    logic [SPADMIC_LINE_IDX_W:0] hi_ext;
    if (!cluster.valid)
      return '0;

    lo_ext = {1'b0, cluster.lo};
    hi_ext = {1'b0, cluster.hi};
    return hi_ext - lo_ext + 1'b1;
  endfunction

  function automatic logic [SPADMIC_SRC_MASK_W-1:0] spadmic_source_bit(
    input spadmic_source_id_e source_id
  );
    logic [SPADMIC_SRC_MASK_W-1:0] src_mask;
    src_mask = '0;
    src_mask[source_id] = 1'b1;
    return src_mask;
  endfunction

  function automatic spadmic_export_mode_e spadmic_export_mode_from_ctrl(
    input spadmic_tx_sel_e tx_sel,
    input logic            position_enable
  );
    if (tx_sel == SPADMIC_TX_POSITION)
      return SPADMIC_EXPORT_POSITION_ONLY;
    if (position_enable)
      return SPADMIC_EXPORT_BOTH_ACTIVE;
    return SPADMIC_EXPORT_TDC_ONLY;
  endfunction

  function automatic logic [SPADMIC_SRC_MASK_W-1:0] spadmic_expected_source_mask(
    input spadmic_export_mode_e export_mode,
    input logic [SPADMIC_AXIS_COUNT-1:0] axis_enable,
    input logic                          position_enable
  );
    logic [SPADMIC_SRC_MASK_W-1:0] mask;
    mask = '0;

    if (export_mode != SPADMIC_EXPORT_POSITION_ONLY) begin
      mask[TDC_ID_X] = axis_enable[0];
      mask[TDC_ID_Y] = axis_enable[1];
      mask[TDC_ID_Z] = axis_enable[2];
    end

    if ((export_mode != SPADMIC_EXPORT_TDC_ONLY) && position_enable)
      mask[SPADMIC_SRC_POSITION] = 1'b1;

    return mask;
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_header_word(
    input logic overflow_any,
    input logic [2:0] non_empty_mask,
    input logic [2:0] multi_cluster_mask
  );
    return {
      2'b01,
      overflow_any,
      non_empty_mask,
      1'b0,
      6'b0,
      multi_cluster_mask
    };
  endfunction

  function automatic logic [2:0] spadmic_pos_cluster_slot_count(
    input spadmic_pos_cluster_slot_mask_t slot_mask
  );
    return {2'b0, slot_mask[0]}
         + {2'b0, slot_mask[1]}
         + {2'b0, slot_mask[2]}
         + {2'b0, slot_mask[3]}
         + {2'b0, slot_mask[4]}
         + {2'b0, slot_mask[5]};
  endfunction

  function automatic spadmic_pos_cluster_slot_mask_t spadmic_pos_cluster_slot_mask(
    input spadmic_axis_clusters_t x_clusters,
    input spadmic_axis_clusters_t y_clusters,
    input spadmic_axis_clusters_t z_clusters
  );
    return {
      z_clusters.cluster1.valid,
      z_clusters.cluster0.valid,
      y_clusters.cluster1.valid,
      y_clusters.cluster0.valid,
      x_clusters.cluster1.valid,
      x_clusters.cluster0.valid
    };
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_compact_header_word(
    input logic overflow_any,
    input logic [2:0] non_empty_mask,
    input logic [2:0] multi_cluster_mask,
    input spadmic_pos_cluster_slot_mask_t slot_mask
  );
    return {
      2'b01,
      overflow_any,
      non_empty_mask,
      1'b1,
      slot_mask,
      multi_cluster_mask
    };
  endfunction

  function automatic logic [2:0] spadmic_pos_compact_payload_words(
    input logic [NARROW_W-1:0] word
  );
    return spadmic_pos_cluster_slot_count(spadmic_pos_cluster_slot_mask_t'(word[8:3]));
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_raw_header_word(
    input logic [2:0] non_empty_mask
  );
    return {
      3'b100,
      1'b0,
      non_empty_mask,
      3'b000,
      2'b10,
      4'h2
    };
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_cluster_word(
    input spadmic_cluster_t cluster
  );
    return {
      3'b000,
      cluster.lo,
      cluster.hi,
      cluster.valid
    };
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_eoc_word(
    input logic [3:0] event_tag
  );
    return {2'b11, 10'b0, event_tag};
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_raw_word(
    input logic [SPADMIC_LINE_W-1:0] lines,
    input int unsigned               word_idx
  );
    logic [NARROW_W-1:0] word;
    int unsigned bit_base;

    word = '0;
    bit_base = word_idx * NARROW_W;
    for (int bit_idx = 0; bit_idx < NARROW_W; bit_idx++) begin
      if ((bit_base + bit_idx) < SPADMIC_LINE_W)
        word[bit_idx] = lines[bit_base + bit_idx];
    end

    return word;
  endfunction

endpackage

`default_nettype wire
