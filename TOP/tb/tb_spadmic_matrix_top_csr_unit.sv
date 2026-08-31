`timescale 1ps/1ps
`default_nettype none

module tb_spadmic_matrix_top_csr_unit;
  import mptdc_pkg::*;
  import spadmic_pkg::*;
  import spadmic_csr_map_pkg::*;

  localparam int CLK_PERIOD = 6250;

  logic clk_sys;
  logic rst_n;
  logic csr_valid;
  logic csr_write;
  logic [15:0] csr_addr;
  logic [31:0] csr_wdata;
  wire csr_ready;
  wire csr_rvalid;
  wire [31:0] csr_rdata;
  wire csr_err;

  logic i2c_error_event;
  logic i2c_error_write;
  logic [15:0] i2c_error_addr;
  logic [31:0] i2c_error_wdata;
  logic [7:0] i2c_error_cause;
  logic safe_idle;
  logic transition_busy;
  logic event_busy;
  logic [13:0] event_id;
  logic [3:0] required_packet_mask;
  logic [3:0] completed_packet_mask;
  logic [3:0] required_reset_ack_mask;
  logic [3:0] observed_reset_ack_mask;
  logic event_rejected_not_ready;
  logic snapshot_valid;
  logic snapshot_busy;
  logic snapshot_timeout;
  logic snapshot_overlap;
  logic snapshot_reject;
  logic snapshot_rearm_ready;
  logic [63:0] snapshot_R;
  logic [63:0] snapshot_Y;
  logic [63:0] snapshot_B;
  logic reset_busy;
  logic reset_done;
  logic reset_disabled;
  logic [2:0] tdc_ready;
  logic [2:0] tdc_busy;
  logic [2:0] tdc_fifo_full;
  logic [2:0] tdc_stop_armed;
  logic [2:0] tdc_packet_active;
  logic [2:0] tdc_packet_pending;
  logic position_packet_pending;
  logic position_packet_busy;
  logic position_snapshot_captured;
  logic matrix_cfg_busy;
  logic matrix_cfg_done;
  logic matrix_cfg_error;
  logic [3:0] matrix_cfg_last_error;
  logic [63:0] matrix_cfg_rdata;
  logic matrix_cfg_readback_valid;
  logic matrix_cfg_valid;
  logic bundle_busy;
  logic bundle_idle;
  logic ddr_empty;
  logic ddr_busy;
  logic ddr_pair_valid;
  logic ddr_padded;
  logic [SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_level;
  logic [SPADMIC_OUTPUT_FIFO_LEVEL_W-1:0] output_fifo_free_words;
  logic output_fifo_empty;
  logic output_fifo_full;
  logic output_fifo_almost_full;
  logic output_fifo_overflow;
  logic bundle_missing_source;
  logic position_packet_drop;
  logic pll_lock;

  wire global_enable;
  spadmic_operating_mode_e requested_mode;
  spadmic_operating_mode_e active_mode;
  wire [2:0] requested_axis_mask;
  wire [2:0] active_axis_mask;
  wire auto_reset_enable;
  wire [15:0] settle_cycles;
  wire [15:0] watchdog_cycles;
  wire [15:0] reset_width;
  wire snapshot_clear;
  wire [MAX_HITS_W-1:0] tdc_max_hits;
  wire [7:0] tdc_ro_slow_code;
  wire [7:0] tdc_ro_fast_code;
  wire tdc_soft_reset;
  wire tdc_fifo_clr;
  wire [2:0] calib_axis_mask;
  spadmic_pos_mode_e position_mode;
  wire [SPADMIC_LINE_COUNT_W-1:0] position_gap_threshold;
  wire [SPADMIC_LINE_COUNT_W-1:0] position_min_cluster_span;
  wire [7:0] pll_fint_sel;
  wire [4:0] pll_ro_sw;
  wire pll_sel_pulse_pfd;
  wire pll_enable_div;
  wire pll_sel_40m;
  wire clk_160m_ext_select;
  wire [3:0] slvs_s_drv;
  wire slvs_en_vref_ext;
  wire slvs_en_drv;
  wire slvs_vref_adj_b;
  wire slvs_en_vref_400mv;
  wire slvs_en_ref_drv_b;
  wire [3:0] rx_s_rx;
  wire rx_en_rx;
  wire rx_en_term;
  wire matrix_cfg_cmd_start;
  wire [2:0] matrix_cfg_cmd_op;
  wire [5:0] matrix_cfg_col_idx;
  wire [63:0] matrix_cfg_wdata;
  wire cfg_accept;

  int pass_count;
  int fail_count;

  initial clk_sys = 1'b0;
  always #(CLK_PERIOD/2) clk_sys = ~clk_sys;

  spadmic_matrix_top_csr dut (
    .clk_sys(clk_sys), .rst_n(rst_n),
    .csr_valid_i(csr_valid), .csr_write_i(csr_write),
    .csr_addr_i(csr_addr), .csr_wdata_i(csr_wdata),
    .csr_ready_o(csr_ready), .csr_rvalid_o(csr_rvalid),
    .csr_rdata_o(csr_rdata), .csr_err_o(csr_err),
    .i2c_error_event_i(i2c_error_event), .i2c_error_write_i(i2c_error_write),
    .i2c_error_addr_i(i2c_error_addr), .i2c_error_wdata_i(i2c_error_wdata),
    .i2c_error_cause_i(i2c_error_cause),
    .safe_idle_i(safe_idle), .transition_busy_i(transition_busy),
    .event_busy_i(event_busy), .event_id_i(event_id),
    .required_packet_mask_i(required_packet_mask),
    .completed_packet_mask_i(completed_packet_mask),
    .required_reset_ack_mask_i(required_reset_ack_mask),
    .observed_reset_ack_mask_i(observed_reset_ack_mask),
    .event_rejected_not_ready_i(event_rejected_not_ready),
    .snapshot_valid_i(snapshot_valid), .snapshot_busy_i(snapshot_busy),
    .snapshot_timeout_i(snapshot_timeout), .snapshot_overlap_i(snapshot_overlap),
    .snapshot_reject_i(snapshot_reject), .snapshot_rearm_ready_i(snapshot_rearm_ready),
    .snapshot_R_i(snapshot_R), .snapshot_Y_i(snapshot_Y), .snapshot_B_i(snapshot_B),
    .reset_busy_i(reset_busy), .reset_done_i(reset_done),
    .reset_disabled_i(reset_disabled), .tdc_ready_i(tdc_ready),
    .tdc_busy_i(tdc_busy), .tdc_fifo_full_i(tdc_fifo_full),
    .tdc_stop_armed_i(tdc_stop_armed), .tdc_packet_active_i(tdc_packet_active),
    .tdc_packet_pending_i(tdc_packet_pending),
    .position_packet_pending_i(position_packet_pending),
    .position_packet_busy_i(position_packet_busy),
    .position_snapshot_captured_i(position_snapshot_captured),
    .matrix_cfg_busy_i(matrix_cfg_busy), .matrix_cfg_done_i(matrix_cfg_done),
    .matrix_cfg_error_i(matrix_cfg_error),
    .matrix_cfg_last_error_i(matrix_cfg_last_error),
    .matrix_cfg_rdata_i(matrix_cfg_rdata),
    .matrix_cfg_readback_valid_i(matrix_cfg_readback_valid),
    .matrix_cfg_valid_i(matrix_cfg_valid), .bundle_busy_i(bundle_busy),
    .bundle_idle_i(bundle_idle), .ddr_empty_i(ddr_empty), .ddr_busy_i(ddr_busy),
    .ddr_pair_valid_i(ddr_pair_valid), .ddr_padded_i(ddr_padded),
    .output_fifo_level_i(output_fifo_level),
    .output_fifo_free_words_i(output_fifo_free_words),
    .output_fifo_empty_i(output_fifo_empty), .output_fifo_full_i(output_fifo_full),
    .output_fifo_almost_full_i(output_fifo_almost_full),
    .output_fifo_overflow_i(output_fifo_overflow),
    .bundle_missing_source_i(bundle_missing_source),
    .position_packet_drop_i(position_packet_drop), .pll_lock_i(pll_lock),
    .global_enable_o(global_enable), .requested_mode_o(requested_mode),
    .active_mode_o(active_mode), .requested_axis_mask_o(requested_axis_mask),
    .active_axis_mask_o(active_axis_mask), .auto_reset_enable_o(auto_reset_enable),
    .settle_cycles_o(settle_cycles), .watchdog_cycles_o(watchdog_cycles),
    .reset_width_o(reset_width), .snapshot_clear_o(snapshot_clear),
    .tdc_max_hits_o(tdc_max_hits), .tdc_ro_slow_code_o(tdc_ro_slow_code),
    .tdc_ro_fast_code_o(tdc_ro_fast_code), .tdc_soft_reset_o(tdc_soft_reset),
    .tdc_fifo_clr_o(tdc_fifo_clr), .calib_axis_mask_o(calib_axis_mask),
    .position_mode_o(position_mode),
    .position_gap_threshold_o(position_gap_threshold),
    .position_min_cluster_span_o(position_min_cluster_span),
    .pll_fint_sel_o(pll_fint_sel), .pll_ro_sw_o(pll_ro_sw),
    .pll_sel_pulse_pfd_o(pll_sel_pulse_pfd), .pll_enable_div_o(pll_enable_div),
    .pll_sel_40m_o(pll_sel_40m), .clk_160m_ext_select_o(clk_160m_ext_select),
    .slvs_s_drv_o(slvs_s_drv), .slvs_en_vref_ext_o(slvs_en_vref_ext),
    .slvs_en_drv_o(slvs_en_drv), .slvs_vref_adj_b_o(slvs_vref_adj_b),
    .slvs_en_vref_400mv_o(slvs_en_vref_400mv),
    .slvs_en_ref_drv_b_o(slvs_en_ref_drv_b), .rx_s_rx_o(rx_s_rx),
    .rx_en_rx_o(rx_en_rx), .rx_en_term_o(rx_en_term),
    .matrix_cfg_cmd_start_o(matrix_cfg_cmd_start),
    .matrix_cfg_cmd_op_o(matrix_cfg_cmd_op),
    .matrix_cfg_col_idx_o(matrix_cfg_col_idx),
    .matrix_cfg_wdata_o(matrix_cfg_wdata), .cfg_accept_o(cfg_accept)
  );

  task automatic check(input string label, input logic condition);
    if (condition) begin
      $display("[PASS] %s", label);
      pass_count++;
    end else begin
      $display("[FAIL] %s", label);
      fail_count++;
    end
  endtask

  task automatic csr_access(
    input logic write_access,
    input logic [15:0] address,
    input logic [31:0] write_data,
    input logic expected_error,
    output logic [31:0] read_data
  );
    begin
      @(negedge clk_sys);
      while (!csr_ready) @(negedge clk_sys);
      csr_valid = 1'b1;
      csr_write = write_access;
      csr_addr = address;
      csr_wdata = write_data;
      @(posedge clk_sys);
      #1;
      check("CSR response valid", csr_rvalid === 1'b1);
      check("CSR response error", csr_err === expected_error);
      read_data = csr_rdata;
      if (expected_error)
        check("Failed CSR read returns zero", csr_rdata === 32'h0000_0000);
      @(negedge clk_sys);
      csr_valid = 1'b0;
      csr_write = 1'b0;
      csr_addr = '0;
      csr_wdata = '0;
      @(posedge clk_sys);
      #1;
    end
  endtask

  task automatic csr_read(
    input logic [15:0] address,
    input logic expected_error,
    output logic [31:0] read_data
  );
    csr_access(1'b0, address, '0, expected_error, read_data);
  endtask

  task automatic csr_write_cmd(
    input logic [15:0] address,
    input logic [31:0] write_data,
    input logic expected_error
  );
    logic [31:0] unused;
    csr_access(1'b1, address, write_data, expected_error, unused);
  endtask

  task automatic pulse_input(input int signal_id);
    begin
      @(negedge clk_sys);
      case (signal_id)
        0: tdc_fifo_full[0] = 1'b1;
        1: position_packet_drop = 1'b1;
        2: event_rejected_not_ready = 1'b1;
        3: snapshot_timeout = 1'b1;
        4: snapshot_overlap = 1'b1;
        5: snapshot_reject = 1'b1;
        6: reset_done = 1'b1;
        7: bundle_missing_source = 1'b1;
        8: output_fifo_overflow = 1'b1;
        9: matrix_cfg_error = 1'b1;
        default: ;
      endcase
      @(posedge clk_sys);
      @(negedge clk_sys);
      case (signal_id)
        0: tdc_fifo_full[0] = 1'b0;
        1: position_packet_drop = 1'b0;
        2: event_rejected_not_ready = 1'b0;
        3: snapshot_timeout = 1'b0;
        4: snapshot_overlap = 1'b0;
        5: snapshot_reject = 1'b0;
        6: reset_done = 1'b0;
        7: bundle_missing_source = 1'b0;
        8: output_fifo_overflow = 1'b0;
        9: matrix_cfg_error = 1'b0;
        default: ;
      endcase
      repeat (2) @(posedge clk_sys);
    end
  endtask

  task automatic report_i2c_error(
    input logic [7:0] cause,
    input logic [15:0] address,
    input logic [31:0] data
  );
    begin
      @(negedge clk_sys);
      i2c_error_cause = cause;
      i2c_error_addr = address;
      i2c_error_wdata = data;
      i2c_error_write = 1'b1;
      i2c_error_event = 1'b1;
      @(posedge clk_sys);
      @(negedge clk_sys);
      i2c_error_event = 1'b0;
      repeat (2) @(posedge clk_sys);
    end
  endtask

  initial begin
    logic [31:0] rd;

    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    csr_valid = 1'b0;
    csr_write = 1'b0;
    csr_addr = '0;
    csr_wdata = '0;
    i2c_error_event = 1'b0;
    i2c_error_write = 1'b0;
    i2c_error_addr = '0;
    i2c_error_wdata = '0;
    i2c_error_cause = CSR_CAUSE_NONE;
    safe_idle = 1'b1;
    transition_busy = 1'b0;
    event_busy = 1'b0;
    event_id = 14'h1234;
    required_packet_mask = 4'hB;
    completed_packet_mask = 4'h3;
    required_reset_ack_mask = 4'hF;
    observed_reset_ack_mask = 4'h5;
    event_rejected_not_ready = 1'b0;
    snapshot_valid = 1'b1;
    snapshot_busy = 1'b0;
    snapshot_timeout = 1'b0;
    snapshot_overlap = 1'b0;
    snapshot_reject = 1'b0;
    snapshot_rearm_ready = 1'b1;
    snapshot_R = 64'h0123_4567_89AB_CDEF;
    snapshot_Y = 64'h1111_2222_3333_4444;
    snapshot_B = 64'hA5A5_5A5A_C3C3_3C3C;
    reset_busy = 1'b0;
    reset_done = 1'b0;
    reset_disabled = 1'b0;
    tdc_ready = 3'b101;
    tdc_busy = 3'b010;
    tdc_fifo_full = 3'b000;
    tdc_stop_armed = 3'b001;
    tdc_packet_active = 3'b100;
    tdc_packet_pending = 3'b010;
    position_packet_pending = 1'b1;
    position_packet_busy = 1'b0;
    position_snapshot_captured = 1'b1;
    matrix_cfg_busy = 1'b0;
    matrix_cfg_done = 1'b1;
    matrix_cfg_error = 1'b0;
    matrix_cfg_last_error = 4'hA;
    matrix_cfg_rdata = 64'hFACE_CAFE_1234_5678;
    matrix_cfg_readback_valid = 1'b1;
    matrix_cfg_valid = 1'b1;
    bundle_busy = 1'b0;
    bundle_idle = 1'b1;
    ddr_empty = 1'b1;
    ddr_busy = 1'b0;
    ddr_pair_valid = 1'b0;
    ddr_padded = 1'b0;
    output_fifo_level = SPADMIC_OUTPUT_FIFO_LEVEL_W'(7);
    output_fifo_free_words = SPADMIC_OUTPUT_FIFO_LEVEL_W'(249);
    output_fifo_empty = 1'b0;
    output_fifo_full = 1'b0;
    output_fifo_almost_full = 1'b0;
    output_fifo_overflow = 1'b0;
    bundle_missing_source = 1'b0;
    position_packet_drop = 1'b0;
    pll_lock = 1'b1;

    repeat (5) @(posedge clk_sys);
    rst_n = 1'b1;
    repeat (5) @(posedge clk_sys);

    csr_read(CSR_CHIP_ID, 1'b0, rd);
    check("CHIP_ID identifies the matrix top", rd == SPADMIC_CHIP_ID_VALUE);
    csr_read(CSR_ABI_VERSION, 1'b0, rd);
    check("ABI version is 1.0", rd == SPADMIC_CSR_ABI_VERSION_VALUE);
    csr_read(CSR_GLOBAL_CTRL, 1'b0, rd);
    check("Global control reset image is disabled axes-111 auto-reset", rd == 32'h0000_00F0);
    csr_read(CSR_POSITION_CFG, 1'b0, rd);
    check("Position reset is cluster gap-2 min-span-1", rd == 32'h0000_0104);
    csr_read(CSR_PLL_CTRL, 1'b0, rd);
    check("PLL reset keeps divider enabled", rd == 32'h0000_4000);
    csr_read(CSR_SLVS_CTRL, 1'b0, rd);
    check("Active-low analog controls reset high", rd == 32'h0000_0140);
    csr_read(CSR_RX_CTRL, 1'b0, rd);
    check("Other analog controls reset low", rd == 32'h0000_0000);
    csr_read(CSR_TX_FIFO_GEOMETRY, 1'b0, rd);
    check("FIFO geometry and reserve threshold are fixed", rd == 32'h0100_0081);

    csr_write_cmd(CSR_GLOBAL_CTRL, 32'h0000_00F7, 1'b1);
    check("Normal matrix mode cannot enable with zero reset width", !global_enable);
    repeat (2) @(posedge clk_sys);
    csr_read(CSR_ACCESS_LAST_INFO, 1'b0, rd);
    check("Rejected enable records invalid-value provenance",
          rd[23:16] == CSR_CAUSE_INVALID_VALUE && rd[15:0] == CSR_GLOBAL_CTRL);

    csr_write_cmd(CSR_RESET_CFG, 32'd7, 1'b0);
    csr_write_cmd(CSR_SNAPSHOT_CFG, {16'd96, 16'd3}, 1'b0);
    csr_write_cmd(CSR_TDC_SHARED_CFG, 32'h0034_1208, 1'b0);
    csr_write_cmd(CSR_CALIB_AXIS_MASK, 32'h0000_0003, 1'b0);
    csr_write_cmd(CSR_POSITION_CFG, 32'h0000_0207, 1'b0);
    csr_write_cmd(CSR_PLL_CTRL, 32'h0001_EA5A, 1'b0);
    csr_write_cmd(CSR_SLVS_CTRL, 32'h0000_01BF, 1'b0);
    csr_write_cmd(CSR_RX_CTRL, 32'h0000_0035, 1'b0);
    csr_write_cmd(CSR_MATRIX_COLUMN, 32'd43, 1'b0);
    csr_write_cmd(CSR_MATRIX_WDATA_LO, 32'h89AB_CDEF, 1'b0);
    csr_write_cmd(CSR_MATRIX_WDATA_HI, 32'h0123_4567, 1'b0);
    csr_write_cmd(CSR_MATRIX_CMD, 32'h0000_0005, 1'b0);
    check("Matrix command reaches the controller", matrix_cfg_cmd_op == 3'd2);
    check("Matrix payload and column are retained",
          matrix_cfg_col_idx == 6'd43 && matrix_cfg_wdata == 64'h0123_4567_89AB_CDEF);
    check("CSR-owned position fields reach the datapath",
          position_mode == SPADMIC_POS_MODE_RAW &&
          position_gap_threshold == 7'd3 && position_min_cluster_span == 7'd2);
    check("Shared TDC tuning reaches all axis wrappers",
          tdc_max_hits == MAX_HITS_W'(8) &&
          tdc_ro_slow_code == 8'h12 && tdc_ro_fast_code == 8'h34);
    check("Separate analog banks reach their outputs",
          slvs_s_drv == 4'hF && !slvs_vref_adj_b && slvs_en_ref_drv_b &&
          rx_s_rx == 4'h5 && rx_en_rx && rx_en_term);

    csr_write_cmd(CSR_GLOBAL_CTRL, 32'h0000_0093, 1'b1);
    check("Normal TDC mode rejects a partial axis mask", !global_enable);
    csr_write_cmd(CSR_GLOBAL_CTRL, 32'h0000_00F3, 1'b0);
    check("Normal TDC mode atomically enables all axes",
          global_enable && active_mode == SPADMIC_MODE_TDC_ONLY && active_axis_mask == 3'b111);
    csr_write_cmd(CSR_POSITION_CFG, 32'h0000_0104, 1'b1);
    check("Configuration writes are blocked while globally enabled",
          position_mode == SPADMIC_POS_MODE_RAW);
    csr_write_cmd(CSR_GLOBAL_CTRL, 32'h0000_00F0, 1'b0);
    check("Global disable is atomic", !global_enable && active_mode == SPADMIC_MODE_DISABLED);
    csr_write_cmd(CSR_GLOBAL_CTRL, 32'h0000_0089, 1'b0);
    check("Calibration accepts the configured nonzero partial mask",
          global_enable && active_mode == SPADMIC_MODE_CALIBRATION && active_axis_mask == 3'b011);
    csr_write_cmd(CSR_GLOBAL_CTRL, 32'h0000_00F0, 1'b0);

    csr_read(CSR_TDC_R_STATUS, 1'b0, rd);
    check("TDC R status is block-owned", rd[11:8] == 4'h1 && rd[3:0] == 4'b1001);
    csr_read(CSR_TDC_Y_STATUS, 1'b0, rd);
    check("TDC Y status is block-owned", rd[11:8] == 4'h2 && rd[5:0] == 6'b100010);
    csr_read(CSR_POSITION_STATUS, 1'b0, rd);
    check("Position status exposes packet lifecycle", rd[2:0] == 3'b101);
    csr_read(CSR_EVENT_STATUS, 1'b0, rd);
    check("Event status exposes event ID", rd[13:0] == event_id);
    csr_read(CSR_EVENT_MASK_STATUS, 1'b0, rd);
    check("Event masks expose required and completed state", rd[15:0] == 16'h5F3B);
    csr_read(CSR_SNAPSHOT_R_LO, 1'b0, rd);
    check("Snapshot R low word is readable", rd == snapshot_R[31:0]);
    csr_read(CSR_MATRIX_RDATA_HI, 1'b0, rd);
    check("Matrix readback high word is readable", rd == matrix_cfg_rdata[63:32]);
    csr_read(CSR_TX_FIFO_STATUS, 1'b0, rd);
    check("TX FIFO status exposes level and free count",
          rd[15:4] == 12'd7 && rd[31:16] == 16'd249);

    csr_read(16'h0002, 1'b1, rd);
    csr_read(16'hA000, 1'b1, rd);
    csr_read(16'h0038, 1'b1, rd);
    csr_write_cmd(CSR_CHIP_ID, 32'hDEAD_BEEF, 1'b1);
    repeat (2) @(posedge clk_sys);
    csr_read(CSR_ACCESS_STATUS, 1'b0, rd);
    check("Invalid accesses set sticky diagnostics", rd[0] && rd[1]);
    csr_read(CSR_ACCESS_LAST_INFO, 1'b0, rd);
    check("Read-only write records exact address and cause",
          rd[24] && rd[23:16] == CSR_CAUSE_READ_ONLY_WRITE && rd[15:0] == CSR_CHIP_ID);
    csr_read(CSR_ACCESS_LAST_WDATA, 1'b0, rd);
    check("Read-only write records exact payload", rd == 32'hDEAD_BEEF);
    csr_read(CSR_ACCESS_ERROR_COUNT, 1'b0, rd);
    check("Access errors are counted", rd >= 32'd6);

    report_i2c_error(CSR_CAUSE_INCOMPLETE_WRITE, CSR_POSITION_CFG, 32'hA500_0000);
    csr_read(CSR_ACCESS_LAST_INFO, 1'b0, rd);
    check("Incomplete I2C writes retain address and cause",
          rd[23:16] == CSR_CAUSE_INCOMPLETE_WRITE && rd[15:0] == CSR_POSITION_CFG);
    report_i2c_error(CSR_CAUSE_I2C_RESET_ABORT, CSR_PLL_CTRL, 32'h1234_0000);
    csr_read(CSR_ACCESS_LAST_INFO, 1'b0, rd);
    check("I2C transport reset abort is independently classified",
          rd[23:16] == CSR_CAUSE_I2C_RESET_ABORT && rd[15:0] == CSR_PLL_CTRL);

    pulse_input(0);
    pulse_input(1);
    pulse_input(2);
    pulse_input(3);
    pulse_input(4);
    pulse_input(5);
    reset_disabled = 1'b1;
    pulse_input(6);
    reset_disabled = 1'b0;
    pulse_input(7);
    pulse_input(8);
    pulse_input(9);
    pll_lock = 1'b0;
    repeat (3) @(posedge clk_sys);

    csr_read(CSR_TDC_R_ERROR_COUNT, 1'b0, rd);
    check("TDC FIFO-full edge increments its counter", rd == 32'd1);
    csr_read(CSR_POSITION_DROP_COUNT, 1'b0, rd);
    check("Position drop edge increments its counter", rd == 32'd1);
    csr_read(CSR_EVENT_REJECT_COUNT, 1'b0, rd);
    check("Event reject edge increments its counter", rd == 32'd1);
    csr_read(CSR_SNAPSHOT_TIMEOUT_COUNT, 1'b0, rd);
    check("Snapshot timeout edge increments its counter", rd == 32'd1);
    csr_read(CSR_SNAPSHOT_OVERLAP_COUNT, 1'b0, rd);
    check("Snapshot overlap edge increments its counter", rd == 32'd1);
    csr_read(CSR_SNAPSHOT_REJECT_COUNT, 1'b0, rd);
    check("Snapshot reject edge increments its counter", rd == 32'd1);
    csr_read(CSR_RESET_DISABLED_COUNT, 1'b0, rd);
    check("Disabled reset completion increments its counter", rd == 32'd1);
    csr_read(CSR_TX_MISSING_SOURCE_COUNT, 1'b0, rd);
    check("TX missing-source edge increments its counter", rd == 32'd1);
    csr_read(CSR_TX_FIFO_OVERFLOW_COUNT, 1'b0, rd);
    check("TX FIFO overflow edge increments its counter", rd == 32'd1);
    csr_read(CSR_MATRIX_ERROR_COUNT, 1'b0, rd);
    check("Matrix controller error edge increments its counter", rd == 32'd1);
    csr_read(CSR_PLL_LOCK_LOSS_COUNT, 1'b0, rd);
    check("PLL lock-loss edge increments its counter", rd == 32'd1);

    csr_read(CSR_GLOBAL_FAULT, 1'b0, rd);
    check("Global fault summarizes block-owned sticky faults", rd[6:0] != 7'd0);
    csr_write_cmd(CSR_EVENT_FAULT, 32'h0000_000F, 1'b0);
    csr_read(CSR_EVENT_FAULT, 1'b0, rd);
    check("Event faults use W1C semantics", rd[3:0] == 4'd0);
    csr_write_cmd(CSR_ACCESS_FAULT, 32'h0000_007F, 1'b0);
    csr_read(CSR_ACCESS_FAULT, 1'b0, rd);
    check("Access faults use W1C semantics", rd[6:0] == 7'd0);

    csr_write_cmd(CSR_MAINT_CMD, 32'h0000_0001, 1'b0);
    repeat (2) @(posedge clk_sys);
    csr_read(CSR_TDC_R_ERROR_COUNT, 1'b0, rd);
    check("Disabled-idle maintenance clears TDC counters", rd == 32'd0);
    csr_read(CSR_POSITION_DROP_COUNT, 1'b0, rd);
    check("Disabled-idle maintenance clears Position counters", rd == 32'd0);
    csr_read(CSR_TX_FIFO_OVERFLOW_COUNT, 1'b0, rd);
    check("Disabled-idle maintenance clears TX counters", rd == 32'd0);
    csr_read(CSR_ACCESS_ERROR_COUNT, 1'b0, rd);
    check("Disabled-idle maintenance clears access counters", rd == 32'd0);
    csr_read(CSR_POSITION_FAULT, 1'b0, rd);
    check("Maintenance leaves sticky faults for explicit W1C", rd[0] == 1'b1);

    $display("============================================================");
    $display("CSR ABI 1.0: %0d PASS, %0d FAIL", pass_count, fail_count);
    $display("============================================================");
    if (fail_count != 0)
      $fatal(1, "tb_spadmic_matrix_top_csr_unit: %0d failures", fail_count);
    $finish;
  end

  initial begin
    #50_000_000;
    $fatal(1, "tb_spadmic_matrix_top_csr_unit: TIMEOUT");
  end
endmodule

`default_nettype wire
