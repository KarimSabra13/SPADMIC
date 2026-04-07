`timescale 1ps/1ps
`default_nettype none

package spadmic_pkg;
  import mptdc_pkg::*;

  localparam int unsigned SPADMIC_AXIS_COUNT  = 3;
  localparam int unsigned SPADMIC_AXIS_ID_W   = 2;
  localparam int unsigned SPADMIC_LINE_W      = 127;
  localparam int unsigned SPADMIC_LINE_IDX_W  = 7;
  localparam int unsigned SPADMIC_CSR_ADDR_W  = 12;
  localparam int unsigned SPADMIC_CSR_DATA_W  = mptdc_pkg::CSR_DATA_W;
  localparam logic [6:0] SPADMIC_I2C_ADDR     = 7'h42;

  typedef enum logic [SPADMIC_AXIS_ID_W-1:0] {
    TDC_ID_X = 2'd0,
    TDC_ID_Y = 2'd1,
    TDC_ID_Z = 2'd2
  } spadmic_tdc_id_e;

  localparam logic [3:0] SPADMIC_REGION_GLOBAL   = 4'h0;
  localparam logic [3:0] SPADMIC_REGION_TDC_X    = 4'h1;
  localparam logic [3:0] SPADMIC_REGION_TDC_Y    = 4'h2;
  localparam logic [3:0] SPADMIC_REGION_TDC_Z    = 4'h3;
  localparam logic [3:0] SPADMIC_REGION_POSITION = 4'h4;

  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_ID      = 12'h000;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_VERSION = 12'h004;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_CTRL    = 12'h008;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_GLOBAL_STATUS  = 12'h00C;

  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_CTRL        = 12'h400;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_GAP_CFG     = 12'h404;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_STATUS      = 12'h420;
  localparam logic [SPADMIC_CSR_ADDR_W-1:0] SPADMIC_CSR_POS_EVENT_COUNT = 12'h424;

  typedef struct packed {
    logic                             valid;
    logic [SPADMIC_LINE_IDX_W-1:0]    lo;
    logic [SPADMIC_LINE_IDX_W-1:0]    hi;
  } spadmic_cluster_t;

  typedef struct packed {
    logic                 empty;
    logic                 overflow;
    logic [1:0]           cluster_count;
    spadmic_cluster_t     cluster0;
    spadmic_cluster_t     cluster1;
  } spadmic_axis_clusters_t;

  function automatic logic is_tdc_header(input logic [NARROW_W-1:0] word);
    return (word[15:13] == 3'b100);
  endfunction

  function automatic logic is_tdc_subheader(input logic [NARROW_W-1:0] word);
    return (word[15:13] == 3'b101);
  endfunction

  function automatic logic is_tdc_eoc(input logic [NARROW_W-1:0] word);
    return (word[15:14] == 2'b11);
  endfunction

  function automatic logic [NARROW_W-1:0] patch_tdc_id_into_subheader(
    input logic [NARROW_W-1:0]     word,
    input spadmic_tdc_id_e         tdc_id
  );
    logic [NARROW_W-1:0] patched;
    patched = word;
    if (is_tdc_subheader(word))
      patched[5:4] = tdc_id;
    return patched;
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_header_word(
    input logic overflow_any,
    input logic [2:0] non_empty_mask,
    input logic [2:0] multi_cluster_mask
  );
    return {
      3'b100,
      overflow_any,
      non_empty_mask,
      multi_cluster_mask,
      2'b01,
      4'b0000
    };
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_axis_summary_word(
    input spadmic_tdc_id_e        axis_id,
    input spadmic_axis_clusters_t axis_clusters
  );
    return {
      1'b0,
      axis_id,
      axis_clusters.overflow,
      axis_clusters.cluster_count,
      axis_clusters.empty,
      9'b0
    };
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_cluster_word(
    input spadmic_cluster_t cluster
  );
    return {
      1'b0,
      cluster.lo,
      cluster.hi,
      cluster.valid
    };
  endfunction

  function automatic logic [NARROW_W-1:0] spadmic_pos_eoc_word(
    input logic [13:0] event_count
  );
    return {2'b11, event_count};
  endfunction

endpackage

`default_nettype wire
